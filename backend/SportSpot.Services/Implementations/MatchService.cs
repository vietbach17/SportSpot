using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class MatchService : IMatchService
{
    private readonly IUnitOfWork _unitOfWork;

    public MatchService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<List<OpenMatchDto>>> GetOpenMatchesAsync(int? sportId, string? district)
    {
        var matches = await _unitOfWork.Matches.GetOpenMatchesWithDetailsAsync(sportId, district);

        var result = matches.Select(m => new OpenMatchDto
        {
            MatchId = m.Id,
            BookingId = m.BookingId,
            BookingCode = m.Booking?.BookingCode ?? string.Empty,
            VenueName = m.Booking?.SubVenue?.Venue?.Name ?? string.Empty,
            SubVenueName = m.Booking?.SubVenue?.Name ?? string.Empty,
            SportName = m.Booking?.SubVenue?.Venue?.Sport?.Name ?? string.Empty,
            Address = m.Booking?.SubVenue?.Venue?.Address ?? string.Empty,
            PlayDate = m.Booking?.PlayDate ?? DateOnly.FromDateTime(DateTime.UtcNow),
            TimeSlots = m.Booking?.BookingDetails
                .OrderBy(bd => bd.SlotId)
                .Select(bd => $"{bd.TimeSlot?.StartTime}-{bd.TimeSlot?.EndTime}")
                .ToList() ?? new List<string>(),
            HostUserId = m.HostUserId,
            HostName = m.HostUser?.FullName ?? "Đội trưởng",
            TotalExpectedPlayers = m.TotalExpectedPlayers,
            NeededPlayers = m.NeededPlayers,
            CurrentJoinedPlayers = m.CurrentJoinedPlayers,
            CostPerPerson = m.CostPerPerson,
            Status = m.Status
        }).ToList();

        return ApiResponse<List<OpenMatchDto>>.Ok(result, "Lấy danh sách kèo mở thành công");
    }

    public async Task<ApiResponse<object>> JoinMatchAsync(int matchId, JoinMatchRequest request)
    {
        var match = await _unitOfWork.Matches.GetMatchByIdWithDetailsAsync(matchId);
        if (match == null || match.Booking == null)
        {
            return ApiResponse<object>.Fail("Không tìm thấy kèo đấu", 404);
        }

        if (match.Status != "Open" || match.CurrentJoinedPlayers >= match.NeededPlayers)
        {
            return ApiResponse<object>.Fail("Kèo này đã đủ người hoặc đã dừng tuyển");
        }

        var existingMember = await _unitOfWork.Matches.GetMatchMemberAsync(matchId, request.UserId);
        if (existingMember != null)
        {
            return ApiResponse<object>.Fail("Bạn đã tham gia kèo này trước đó");
        }

        var qrPayload = QrChecksumHelper.BuildSignedQrPayload(
            match.Booking.BookingCode, request.UserId, "JoinedPlayer");

        var member = new MatchMember
        {
            MatchId = match.Id,
            UserId = request.UserId,
            MemberType = "AppUser",
            PaidAmount = match.CostPerPerson,
            PaymentStatus = "Paid",
            TicketQrPayload = qrPayload,
            JoinedAt = DateTime.UtcNow
        };

        await _unitOfWork.Matches.AddMatchMemberAsync(member);

        match.CurrentJoinedPlayers++;
        if (match.CurrentJoinedPlayers >= match.NeededPlayers)
        {
            match.Status = "Full";
        }

        match.Booking.RemainingBalance = Math.Max(0, match.Booking.RemainingBalance - match.CostPerPerson);

        await _unitOfWork.Transactions.AddAsync(new Transaction
        {
            BookingId = match.BookingId,
            UserId = request.UserId,
            Amount = match.CostPerPerson,
            PaymentGateway = request.PaymentGateway,
            TransactionCode = $"TXN-M-{Guid.NewGuid():N}"[..20].ToUpper(),
            Status = "Holding",
            CreatedAt = DateTime.UtcNow
        });

        await _unitOfWork.SaveChangesAsync();

        return ApiResponse<object>.Ok(new
        {
            matchId = match.Id,
            paidAmount = match.CostPerPerson,
            ticketQrPayload = qrPayload,
            remainingBalanceForHost = match.Booking.RemainingBalance,
            matchStatus = match.Status
        }, "Tham gia kèo thành công!");
    }

    public async Task<ApiResponse<object>> AssignWalkInAtDeskAsync(int matchId)
    {
        var match = await _unitOfWork.Matches.GetMatchByIdWithDetailsAsync(matchId);
        if (match == null || match.Booking == null)
        {
            return ApiResponse<object>.Fail("Không tìm thấy kèo đấu", 404);
        }

        if (match.Status != "Open" || match.CurrentJoinedPlayers >= match.NeededPlayers)
        {
            return ApiResponse<object>.Fail("Kèo này đã đủ người hoặc đã dừng tuyển");
        }

        var member = new MatchMember
        {
            MatchId = match.Id,
            UserId = null,
            MemberType = "WalkInAtDesk",
            PaidAmount = match.CostPerPerson,
            PaymentStatus = "Paid",
            TicketQrPayload = QrChecksumHelper.BuildSignedQrPayload(match.Booking.BookingCode, 0, "WalkInAtDesk"),
            IsCheckedIn = true,
            CheckedInAt = DateTime.UtcNow,
            JoinedAt = DateTime.UtcNow
        };

        await _unitOfWork.Matches.AddMatchMemberAsync(member);

        match.CurrentJoinedPlayers++;
        if (match.CurrentJoinedPlayers >= match.NeededPlayers)
        {
            match.Status = "Full";
        }

        match.Booking.RemainingBalance = Math.Max(0, match.Booking.RemainingBalance - match.CostPerPerson);
        await _unitOfWork.SaveChangesAsync();

        return ApiResponse<object>.Ok(new
        {
            matchId = match.Id,
            remainingNeeded = match.NeededPlayers - match.CurrentJoinedPlayers,
            remainingBalanceForHost = match.Booking.RemainingBalance,
            matchStatus = match.Status
        }, "Đã gán khách vãng lai tại quầy thành công");
    }

    public async Task<ApiResponse<object>> StopRecruitingAsync(int matchId, int hostUserId)
    {
        var match = await _unitOfWork.Matches.GetByIdAsync(matchId);
        if (match == null)
        {
            return ApiResponse<object>.Fail("Không tìm thấy kèo đấu", 404);
        }

        if (hostUserId > 0 && match.HostUserId != hostUserId)
        {
            return ApiResponse<object>.Fail("Chỉ đội trưởng (Host) mới có quyền dừng tuyển", 403);
        }

        match.Status = "Stopped";
        _unitOfWork.Matches.Update(match);
        await _unitOfWork.SaveChangesAsync();

        return ApiResponse<object>.Ok(new { matchId = match.Id, status = match.Status }, "Đã dừng tuyển vãng lai thành công");
    }

    public async Task<ApiResponse<object>> LeaveMatchAsync(int matchId, int userId)
    {
        var match = await _unitOfWork.Matches.GetMatchByIdWithDetailsAsync(matchId);
        if (match == null || match.Booking == null)
        {
            return ApiResponse<object>.Fail("Không tìm thấy kèo đấu", 404);
        }

        var member = await _unitOfWork.Matches.GetMatchMemberAsync(matchId, userId);
        if (member == null)
        {
            return ApiResponse<object>.Fail("Bạn chưa tham gia kèo này", 404);
        }

        var firstSlotTime = match.Booking.BookingDetails
            .OrderBy(bd => bd.SlotId)
            .Select(bd => bd.TimeSlot?.StartTime)
            .FirstOrDefault() ?? "18:00";

        if (!TimeOnly.TryParse(firstSlotTime, out var startTime))
        {
            startTime = new TimeOnly(18, 0);
        }

        var matchDateTime = match.Booking.PlayDate.ToDateTime(startTime);
        var hoursRemaining = (matchDateTime - DateTime.Now).TotalHours;

        int refundPercentage = hoursRemaining >= 4 ? 100 : (hoursRemaining >= 2 ? 50 : 0);
        int refundAmount = (int)Math.Round(member.PaidAmount * (refundPercentage / 100.0));
        int penaltyAmount = member.PaidAmount - refundAmount;

        if (userId > 0 && refundAmount > 0)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user != null)
            {
                user.WalletBalance += refundAmount;
                _unitOfWork.Users.Update(user);
            }
        }

        // Nếu hoàn 100% thì cộng trả lại phần tiền sân thiếu của Host và mở lại slot
        if (refundPercentage == 100)
        {
            match.Booking.RemainingBalance += member.PaidAmount;
        }
        else if (refundPercentage == 50)
        {
            match.Booking.RemainingBalance += refundAmount;
        }

        _unitOfWork.Matches.RemoveMatchMember(member);
        match.CurrentJoinedPlayers = Math.Max(0, match.CurrentJoinedPlayers - 1);
        if (match.Status == "Full")
        {
            match.Status = "Open";
        }

        await _unitOfWork.SaveChangesAsync();

        return ApiResponse<object>.Ok(new
        {
            refundPercentage,
            refundAmount,
            penaltyAmount,
            slotReopened = true
        }, "Hủy tham gia kèo thành công");
    }
}
