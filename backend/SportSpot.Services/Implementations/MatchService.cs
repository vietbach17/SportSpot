using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class MatchService(IUnitOfWork unitOfWork, SportSpotDbContext db) : IMatchService
{
    private const string ConflictMessage = "Kèo vừa thay đổi. Vui lòng tải lại trước khi thử tiếp.";

    public async Task<ApiResponse<object>> GetMyTicketAsync(int matchId, int userId)
    {
        var member = await unitOfWork.Matches.GetMatchMemberAsync(matchId, userId);
        if (member?.TicketQrPayload == null)
            return ApiResponse<object>.Fail("Bạn chưa có vé tham gia kèo này", 404);
        return ApiResponse<object>.Ok(new { ticketQrPayload = member.TicketQrPayload, member.PaidAmount });
    }

    public async Task<ApiResponse<List<OpenMatchDto>>> GetOpenMatchesAsync(int? sportId, string? district)
    {
        var matches = await unitOfWork.Matches.GetOpenMatchesWithDetailsAsync(sportId, district);
        return ApiResponse<List<OpenMatchDto>>.Ok(matches
            .Where(m => m.Booking != null && MatchRules.IsUpcoming(m.Booking) && m.CurrentJoinedPlayers < m.NeededPlayers)
            .OrderBy(m => m.Booking!.PlayDate).Select(Map).ToList());
    }

    public async Task<ApiResponse<List<OpenMatchDto>>> GetStaffMatchesAsync(int staffId)
    {
        var staff = await unitOfWork.Users.GetByIdAsync(staffId);
        if (staff?.Role != "VenueStaff" || staff.StaffVenueId == null)
            return ApiResponse<List<OpenMatchDto>>.Fail("Chỉ lễ tân được phân công cụm sân mới có quyền truy cập", 403);
        var matches = await unitOfWork.Matches.GetOpenMatchesWithDetailsAsync(null, null);
        return ApiResponse<List<OpenMatchDto>>.Ok(matches.Where(m => m.Booking?.SubVenue?.VenueId == staff.StaffVenueId
            && MatchRules.IsUpcoming(m.Booking) && m.CurrentJoinedPlayers < m.NeededPlayers)
            .OrderBy(m => m.Booking!.PlayDate).Select(Map).ToList());
    }

    public async Task<ApiResponse<OpenMatchDto>> GetMatchAsync(int id)
    {
        var match = await unitOfWork.Matches.GetMatchByIdWithDetailsAsync(id);
        return match == null ? ApiResponse<OpenMatchDto>.Fail("Không tìm thấy kèo đấu", 404)
            : ApiResponse<OpenMatchDto>.Ok(Map(match));
    }

    public async Task<ApiResponse<OpenMatchDto>> CreateMatchAsync(int userId, CreateMatchRequest request)
    {
        if (!MatchRules.ValidPlayers(request.TotalExpectedPlayers, request.NeededPlayers)
            || request.SkillLevel is not ("Cơ bản" or "Trung bình"))
            return ApiResponse<OpenMatchDto>.Fail("Số người tuyển phải lớn hơn 0 và nhỏ hơn tổng số người; trình độ không hợp lệ");
        var booking = await unitOfWork.Bookings.GetBookingByIdWithDetailsAsync(request.BookingId);
        if (booking == null) return ApiResponse<OpenMatchDto>.Fail("Không tìm thấy đơn đặt sân", 404);
        if (booking.UserId != userId || userId <= 0)
            return ApiResponse<OpenMatchDto>.Fail("Chỉ Host được tạo kèo", 403);
        if (!MatchRules.IsUpcoming(booking))
            return ApiResponse<OpenMatchDto>.Fail("Chỉ được tuyển cho đơn sắp diễn ra", 409);
        if (await db.OpenMatches.AnyAsync(m => m.BookingId == booking.Id))
            return ApiResponse<OpenMatchDto>.Fail("Đơn đặt sân đã có kèo tuyển", 409);
        var match = new OpenMatch {
            Booking = booking, HostUserId = userId, HostUser = booking.User,
            TotalExpectedPlayers = request.TotalExpectedPlayers, NeededPlayers = request.NeededPlayers,
            CostPerPerson = MatchRules.SplitCost(booking.CourtPrice, request.TotalExpectedPlayers),
            SkillLevel = request.SkillLevel
        };
        booking.BookingType = "OpenMatch";
        await unitOfWork.Matches.AddAsync(match);
        try { await unitOfWork.SaveChangesAsync(); }
        catch (DbUpdateException) { return ApiResponse<OpenMatchDto>.Fail(ConflictMessage, 409); }
        return ApiResponse<OpenMatchDto>.Ok(Map(match), "Đã mở tuyển vãng lai");
    }

    public Task<ApiResponse<object>> JoinMatchAsync(int matchId, JoinMatchRequest request) =>
        AddMemberAsync(matchId, request.UserId, false, request.PaymentGateway);

    public Task<ApiResponse<object>> AssignWalkInAtDeskAsync(int matchId, int staffId) =>
        AddMemberAsync(matchId, staffId, true, "Cash");

    private async Task<ApiResponse<object>> AddMemberAsync(int matchId, int actorId, bool atDesk, string gateway)
    {
        var actor = await unitOfWork.Users.GetByIdAsync(actorId);
        if (actor == null) return ApiResponse<object>.Fail("Vui lòng đăng nhập", 401);
        var match = await unitOfWork.Matches.GetMatchByIdWithDetailsAsync(matchId);
        if (match?.Booking == null) return ApiResponse<object>.Fail("Không tìm thấy kèo đấu", 404);
        if (atDesk && (actor.Role != "VenueStaff" || actor.StaffVenueId != match.Booking.SubVenue?.VenueId))
            return ApiResponse<object>.Fail("Bạn không phải lễ tân của cụm sân này", 403);
        if (!atDesk && gateway != "MockPayment")
            return ApiResponse<object>.Fail("Thanh toán thực cần xác nhận từ Module 5 trước khi ghi nhận thành viên");
        if (!atDesk && match.HostUserId == actorId)
            return ApiResponse<object>.Fail("Host đã thuộc đội, không thể tham gia dưới dạng vãng lai", 409);
        if (match.Status != "Open" || match.CurrentJoinedPlayers >= match.NeededPlayers || !MatchRules.IsUpcoming(match.Booking))
            return ApiResponse<object>.Fail("Kèo đã đủ người, dừng tuyển hoặc đã bắt đầu", 409);
        if (!atDesk && match.MatchMembers.Any(m => m.UserId == actorId))
            return ApiResponse<object>.Fail("Bạn đã tham gia kèo này", 409);

        var qr = atDesk ? null : QrChecksumHelper.BuildSignedQrPayload(match.Booking.BookingCode, actorId, "JoinedPlayer");
        var member = new MatchMember {
            MatchId = match.Id, UserId = atDesk ? null : actorId,
            MemberType = atDesk ? "WalkInAtDesk" : "AppUser",
            PaidAmount = match.CostPerPerson, PaymentStatus = "Paid", TicketQrPayload = qr,
            IsCheckedIn = atDesk, CheckedInAt = atDesk ? DateTime.UtcNow : null
        };
        await unitOfWork.Matches.AddMatchMemberAsync(member);
        match.CurrentJoinedPlayers++;
        match.Revision++;
        if (match.CurrentJoinedPlayers == match.NeededPlayers) match.Status = "Full";
        // A negative balance is credit owed to a prepaid Host; never discard contributions by clamping to zero.
        match.Booking.RemainingBalance -= match.CostPerPerson;
        await unitOfWork.Transactions.AddAsync(new Transaction {
            BookingId = match.BookingId, UserId = actorId, Amount = match.CostPerPerson,
            PaymentGateway = gateway, TransactionCode = $"TXN-M-{Guid.NewGuid():N}",
            Status = atDesk ? "Settled" : "Holding"
        });
        try { await unitOfWork.SaveChangesAsync(); }
        catch (DbUpdateException) { return ApiResponse<object>.Fail(ConflictMessage, 409); }
        return ApiResponse<object>.Ok(new {
            matchId, paidAmount = match.CostPerPerson, ticketQrPayload = qr,
            remainingNeeded = match.NeededPlayers - match.CurrentJoinedPlayers,
            remainingBalanceForHost = match.Booking.RemainingBalance, matchStatus = match.Status
        }, atDesk ? "Đã thu tiền mặt và gán khách tại quầy" : "Tham gia thành công (thanh toán giả lập)");
    }

    public async Task<ApiResponse<object>> StopRecruitingAsync(int matchId, int hostUserId)
    {
        var match = await unitOfWork.Matches.GetMatchByIdWithDetailsAsync(matchId);
        if (match == null) return ApiResponse<object>.Fail("Không tìm thấy kèo đấu", 404);
        if (hostUserId <= 0 || match.HostUserId != hostUserId)
            return ApiResponse<object>.Fail("Chỉ Host được dừng tuyển", 403);
        if (match.Status == "Stopped") return ApiResponse<object>.Ok(new { matchId, status = match.Status });
        if (match.Status != "Open" || match.Booking == null || !MatchRules.IsUpcoming(match.Booking))
            return ApiResponse<object>.Fail("Kèo không còn mở tuyển", 409);
        match.Status = "Stopped";
        match.Revision++;
        try { await unitOfWork.SaveChangesAsync(); }
        catch (DbUpdateException) { return ApiResponse<object>.Fail(ConflictMessage, 409); }
        return ApiResponse<object>.Ok(new { matchId, status = match.Status }, "Đã dừng tuyển");
    }

    public async Task<ApiResponse<object>> LeaveMatchAsync(int matchId, int userId)
    {
        var match = await unitOfWork.Matches.GetMatchByIdWithDetailsAsync(matchId);
        if (match?.Booking == null) return ApiResponse<object>.Fail("Không tìm thấy kèo đấu", 404);
        var member = match.MatchMembers.FirstOrDefault(m => m.UserId == userId);
        if (member == null) return ApiResponse<object>.Fail("Bạn chưa tham gia kèo", 404);
        if (!MatchRules.IsUpcoming(match.Booking)) return ApiResponse<object>.Fail("Trận đã bắt đầu hoặc bị hủy", 409);
        var first = match.Booking.BookingDetails.Select(d => d.TimeSlot!.StartTime).OrderBy(t => t).First();
        var hours = (match.Booking.PlayDate.ToDateTime(TimeOnly.Parse(first)) - MatchRules.VietnamNow).TotalHours;
        var percentage = hours >= 4 ? 100 : hours >= 2 ? 50 : 0;
        var refund = (int)Math.Round(member.PaidAmount * percentage / 100m, MidpointRounding.AwayFromZero);
        var user = await unitOfWork.Users.GetByIdAsync(userId);
        if (user == null) return ApiResponse<object>.Fail("Không tìm thấy người dùng", 404);
        user.WalletBalance += refund;
        match.Booking.RemainingBalance += refund;
        match.CurrentJoinedPlayers--;
        match.Revision++;
        if (match.Status == "Full") match.Status = "Open";
        unitOfWork.Matches.RemoveMatchMember(member);
        await unitOfWork.Transactions.AddAsync(new Transaction {
            BookingId = match.BookingId, UserId = userId, Amount = -refund,
            PaymentGateway = "Wallet", Status = "Refunded", TransactionCode = $"REF-M-{Guid.NewGuid():N}"
        });
        try { await unitOfWork.SaveChangesAsync(); }
        catch (DbUpdateException) { return ApiResponse<object>.Fail(ConflictMessage, 409); }
        return ApiResponse<object>.Ok(new { refundPercentage = percentage, refundAmount = refund,
            penaltyAmount = member.PaidAmount - refund, slotReopened = match.Status == "Open" });
    }

    private static OpenMatchDto Map(OpenMatch m) => new() {
        MatchId = m.Id, BookingId = m.BookingId, BookingCode = m.Booking?.BookingCode ?? "",
        VenueId = m.Booking?.SubVenue?.VenueId ?? 0, SportId = m.Booking?.SubVenue?.Venue?.SportId ?? 0,
        VenueName = m.Booking?.SubVenue?.Venue?.Name ?? "", SubVenueName = m.Booking?.SubVenue?.Name ?? "",
        SportName = m.Booking?.SubVenue?.Venue?.Sport?.Name ?? "", District = m.Booking?.SubVenue?.Venue?.District ?? "",
        Address = m.Booking?.SubVenue?.Venue?.Address ?? "", PlayDate = m.Booking?.PlayDate ?? default,
        TimeSlots = m.Booking?.BookingDetails.OrderBy(d => d.TimeSlot?.StartTime)
            .Select(d => $"{d.TimeSlot?.StartTime}-{d.TimeSlot?.EndTime}").ToList() ?? new(),
        HostUserId = m.HostUserId, HostName = m.HostUser?.FullName ?? "Host",
        TotalExpectedPlayers = m.TotalExpectedPlayers, NeededPlayers = m.NeededPlayers,
        CurrentJoinedPlayers = m.CurrentJoinedPlayers, CostPerPerson = m.CostPerPerson,
        Status = m.Status, SkillLevel = m.SkillLevel, RemainingBalanceForHost = m.Booking?.RemainingBalance ?? 0,
        Members = m.MatchMembers.OrderBy(mm => mm.JoinedAt).Select(mm => new MatchMemberDto(
            mm.Id, mm.UserId, mm.User?.FullName ?? "Khách tại quầy", mm.User?.AvatarUrl, mm.MemberType)).ToList()
    };
}
