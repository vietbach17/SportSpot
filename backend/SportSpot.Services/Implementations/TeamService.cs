using System.Data;
using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;

namespace SportSpot.Services.Implementations;

public class TeamService(SportSpotDbContext db)
{
    private IQueryable<TeamChallenge> Challenges => db.TeamChallenges
        .Include(c => c.Team!).ThenInclude(t => t.CaptainUser)
        .Include(c => c.Booking!).ThenInclude(b => b.SubVenue!).ThenInclude(s => s.Venue)
        .Include(c => c.Booking!).ThenInclude(b => b.BookingDetails).ThenInclude(d => d.TimeSlot)
        .Include(c => c.Requests).ThenInclude(r => r.Team!).ThenInclude(t => t.CaptainUser);

    public async Task<ApiResponse<List<TeamDto>>> MyTeams(int userId) =>
        ApiResponse<List<TeamDto>>.Ok((await db.Teams.Include(t => t.CaptainUser)
            .Where(t => t.CaptainUserId == userId).OrderBy(t => t.Name).ToListAsync()).Select(MapTeam).ToList());

    public async Task<ApiResponse<TeamDto>> CreateTeam(int userId, CreateTeamRequest request)
    {
        var user = await db.Users.FindAsync(userId);
        if (user == null) return ApiResponse<TeamDto>.Fail("Vui lòng đăng nhập", 401);
        if (string.IsNullOrWhiteSpace(request.Name) || request.Name.Trim().Length is < 2 or > 100
            || request.TeamSize is not (5 or 7 or 11) || request.SkillLevel is not ("Cơ bản" or "Trung bình" or "Nâng cao"))
            return ApiResponse<TeamDto>.Fail("Nhập tên đội, loại sân 5/7/11 và trình độ hợp lệ");
        var team = new Team { Name = request.Name.Trim(), CaptainUser = user,
            TeamSize = request.TeamSize, SkillLevel = request.SkillLevel };
        db.Teams.Add(team);
        await db.SaveChangesAsync();
        return ApiResponse<TeamDto>.Created(MapTeam(team));
    }

    public async Task<ApiResponse<List<TeamChallengeDto>>> List(int userId, bool mine)
    {
        var query = Challenges;
        if (mine) query = query.Where(c => c.Team!.CaptainUserId == userId
            || c.Requests.Any(r => r.Team!.CaptainUserId == userId));
        else query = query.Where(c => c.Status == "Open");
        var rows = await query.OrderByDescending(c => c.Id).ToListAsync();
        return ApiResponse<List<TeamChallengeDto>>.Ok(rows.Where(c => mine || MatchRules.IsUpcoming(c.Booking!))
            .Select(c => Map(c, userId)).ToList());
    }

    public Task<ApiResponse<object>> CreateChallenge(int userId, CreateTeamChallengeRequest request) => Write(async () =>
    {
        var team = await db.Teams.FindAsync(request.TeamId);
        if (team?.CaptainUserId != userId) return ApiResponse<object>.Fail("Chỉ đội trưởng được mở kèo", 403);
        var booking = await db.Bookings.Include(b => b.SubVenue!).ThenInclude(s => s.Venue)
            .Include(b => b.BookingDetails).ThenInclude(d => d.TimeSlot).FirstOrDefaultAsync(b => b.Id == request.BookingId);
        if (booking == null || booking.UserId != userId) return ApiResponse<object>.Fail("Chọn đơn đặt sân của bạn", 403);
        if (booking.SubVenue?.Venue?.SportId != 3 || booking.BookingType is not ("Standard" or "TeamChallenge") || !MatchRules.IsUpcoming(booking))
            return ApiResponse<object>.Fail("Cần đơn sân bóng sắp diễn ra, chưa mở tuyển người lẻ", 409);
        var existing = await db.TeamChallenges.FirstOrDefaultAsync(c => c.BookingId == booking.Id);
        if (existing != null && existing.Status != "Cancelled")
            return ApiResponse<object>.Fail("Đơn sân này đã có kèo đối kháng", 409);
        if (await Busy(team.Id, booking)) return ApiResponse<object>.Fail("Đội đã có trận trùng giờ", 409);
        var challenge = existing ?? new TeamChallenge { BookingId = booking.Id };
        challenge.TeamId = team.Id;
        challenge.Note = request.Note.Trim();
        challenge.Status = "Open";
        challenge.Revision++;
        booking.BookingType = "TeamChallenge";
        if (existing == null) db.TeamChallenges.Add(challenge);
        await db.SaveChangesAsync();
        return ApiResponse<object>.Created(new { challenge.Id });
    });

    public Task<ApiResponse<object>> Apply(int userId, int id, ApplyTeamChallengeRequest request) => Write(async () =>
    {
        var challenge = await Challenges.FirstOrDefaultAsync(c => c.Id == id);
        if (challenge == null) return ApiResponse<object>.Fail("Không tìm thấy kèo", 404);
        var team = await db.Teams.FindAsync(request.TeamId);
        if (team?.CaptainUserId != userId) return ApiResponse<object>.Fail("Chỉ đội trưởng được gửi lời mời", 403);
        if (challenge.Team!.CaptainUserId == userId) return ApiResponse<object>.Fail("Không thể ghép với đội của chính bạn");
        if (challenge.Status != "Open" || !MatchRules.IsUpcoming(challenge.Booking!))
            return ApiResponse<object>.Fail("Kèo đã đóng hoặc đã bắt đầu", 409);
        if (challenge.Team.TeamSize != team.TeamSize) return ApiResponse<object>.Fail("Hai đội cần cùng loại sân 5/7/11");
        if (await Busy(team.Id, challenge.Booking!)) return ApiResponse<object>.Fail("Đội đã có trận trùng giờ", 409);
        var application = challenge.Requests.FirstOrDefault(r => r.TeamId == team.Id);
        if (application != null && application.Status is not ("Withdrawn" or "Cancelled"))
            return ApiResponse<object>.Fail("Đội đã gửi lời mời cho kèo này", 409);
        if (application == null) challenge.Requests.Add(new TeamChallengeRequest { TeamId = team.Id, Message = request.Message.Trim() });
        else { application.Status = "Pending"; application.Message = request.Message.Trim(); }
        challenge.Revision++;
        Notify(challenge.Team.CaptainUserId, "Có đội muốn ghép trận", $"{team.Name} đã gửi lời mời đối kháng.");
        await db.SaveChangesAsync();
        return ApiResponse<object>.Ok(new { status = "Pending" });
    });

    public Task<ApiResponse<object>> Decide(int userId, int id, int requestId, bool accept) => Write(async () =>
    {
        var challenge = await Challenges.FirstOrDefaultAsync(c => c.Id == id);
        if (challenge == null) return ApiResponse<object>.Fail("Không tìm thấy kèo", 404);
        if (challenge.Team!.CaptainUserId != userId) return ApiResponse<object>.Fail("Chỉ chủ kèo được duyệt", 403);
        if (challenge.Status != "Open" || !MatchRules.IsUpcoming(challenge.Booking!))
            return ApiResponse<object>.Fail("Kèo không còn nhận lời mời", 409);
        var application = challenge.Requests.FirstOrDefault(r => r.Id == requestId);
        if (application?.Status != "Pending") return ApiResponse<object>.Fail("Lời mời không còn chờ duyệt", 409);
        if (accept && (await Busy(application.TeamId, challenge.Booking!, id) || await Busy(challenge.TeamId, challenge.Booking!, id)))
            return ApiResponse<object>.Fail("Một trong hai đội đã có trận trùng giờ", 409);
        application.Status = accept ? "Accepted" : "Rejected";
        if (accept)
        {
            challenge.Status = "Matched";
            foreach (var other in challenge.Requests.Where(r => r.Status == "Pending"))
            {
                other.Status = "Rejected";
                Notify(other.Team!.CaptainUserId, "Kèo đã chọn đối thủ", $"{challenge.Team.Name} đã ghép với một đội khác.");
            }
        }
        challenge.Revision++;
        Notify(application.Team!.CaptainUserId, accept ? "Ghép đội thành công" : "Lời mời chưa được nhận",
            $"Đội {challenge.Team.Name}: {(accept ? "đã chấp nhận" : "đã từ chối")} lời mời của bạn.");
        await db.SaveChangesAsync();
        return ApiResponse<object>.Ok(new { challenge.Status });
    });

    public Task<ApiResponse<object>> Cancel(int userId, int id) => Write(async () =>
    {
        var challenge = await Challenges.FirstOrDefaultAsync(c => c.Id == id);
        if (challenge == null) return ApiResponse<object>.Fail("Không tìm thấy kèo", 404);
        if (challenge.Team!.CaptainUserId != userId) return ApiResponse<object>.Fail("Chỉ chủ kèo được đóng kèo", 403);
        if (challenge.Status == "Cancelled" || !MatchRules.IsUpcoming(challenge.Booking!))
            return ApiResponse<object>.Fail("Kèo đã đóng hoặc đã bắt đầu", 409);
        challenge.Status = "Cancelled";
        challenge.Revision++;
        foreach (var r in challenge.Requests.Where(r => r.Status is "Pending" or "Accepted"))
        {
            r.Status = "Cancelled";
            Notify(r.Team!.CaptainUserId, "Kèo đối kháng đã đóng", $"Đội {challenge.Team.Name} đã đóng kèo. Lịch đặt sân vẫn được giữ.");
        }
        await db.SaveChangesAsync();
        return ApiResponse<object>.Ok(new { challenge.Status });
    });

    public Task<ApiResponse<object>> Withdraw(int userId, int id, int requestId) => Write(async () =>
    {
        var challenge = await Challenges.FirstOrDefaultAsync(c => c.Id == id);
        var r = challenge?.Requests.FirstOrDefault(r => r.Id == requestId);
        if (r == null) return ApiResponse<object>.Fail("Không tìm thấy lời mời", 404);
        if (r.Team!.CaptainUserId != userId) return ApiResponse<object>.Fail("Bạn không phải đội trưởng", 403);
        if (r.Status is not ("Pending" or "Accepted") || !MatchRules.IsUpcoming(challenge!.Booking!))
            return ApiResponse<object>.Fail("Không thể rút lời mời này", 409);
        if (r.Status == "Accepted") challenge!.Status = "Open";
        r.Status = "Withdrawn";
        challenge!.Revision++;
        Notify(challenge.Team!.CaptainUserId, "Đội đối thủ rút lời mời", $"Đội {r.Team.Name} đã rút khỏi kèo.");
        await db.SaveChangesAsync();
        return ApiResponse<object>.Ok(new { r.Status });
    });

    private async Task<bool> Busy(int teamId, Booking booking, int excludeId = 0)
    {
        var candidates = await Challenges.Where(c => c.Id != excludeId && c.Status != "Cancelled"
            && c.Booking!.PlayDate == booking.PlayDate && (c.TeamId == teamId
            || (c.Status == "Matched" && c.Requests.Any(r => r.TeamId == teamId && r.Status == "Accepted")))).ToListAsync();
        var start = booking.BookingDetails.Min(d => d.TimeSlot!.StartTime);
        var end = booking.BookingDetails.Max(d => d.TimeSlot!.EndTime);
        return candidates.Any(c => c.Booking!.Status != "Cancelled" && c.Booking.BookingDetails.Any(d =>
            string.CompareOrdinal(d.TimeSlot!.StartTime, end) < 0 && string.CompareOrdinal(d.TimeSlot.EndTime, start) > 0));
    }

    private async Task<ApiResponse<object>> Write(Func<Task<ApiResponse<object>>> action)
    {
        await using var tx = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        try
        {
            var result = await action();
            if (result.Success) await tx.CommitAsync();
            else await tx.RollbackAsync();
            return result;
        }
        catch (DbUpdateException) { await tx.RollbackAsync(); return ApiResponse<object>.Fail("Kèo vừa thay đổi. Vui lòng tải lại.", 409); }
        catch (System.Data.Common.DbException) { await tx.RollbackAsync(); return ApiResponse<object>.Fail("Lịch vừa thay đổi. Vui lòng tải lại.", 409); }
    }

    private void Notify(int userId, string title, string message) => db.Notifications.Add(new Notification
        { UserId = userId, Title = title, Message = message, Type = "match" });
    private static TeamDto MapTeam(Team t) => new(t.Id, t.Name, t.CaptainUserId, t.CaptainUser?.FullName ?? "", t.TeamSize, t.SkillLevel);
    private static TeamChallengeDto Map(TeamChallenge c, int userId)
    {
        var b = c.Booking!;
        var host = c.Team!.CaptainUserId == userId;
        var status = b.Status == "Cancelled" || c.Status == "Cancelled" ? "Cancelled" : !MatchRules.IsUpcoming(b) ? "Expired" : c.Status;
        var accepted = c.Requests.FirstOrDefault(r => r.Status == "Accepted");
        var contact = accepted == null || status != "Matched" ? null : host ? accepted.Team?.CaptainUser?.PhoneNumber
            : accepted.Team?.CaptainUserId == userId ? c.Team.CaptainUser?.PhoneNumber : null;
        return new(c.Id, MapTeam(c.Team), b.Id, b.SubVenue!.Venue!.Name, b.SubVenue.Name,
            b.SubVenue.Venue.District, b.PlayDate, b.BookingDetails.OrderBy(d => d.TimeSlot!.StartTime)
                .Select(d => $"{d.TimeSlot!.StartTime}-{d.TimeSlot.EndTime}").ToList(),
            (b.CourtPrice + 1) / 2, c.Note, status, host,
            c.Requests.Where(r => host || r.Team!.CaptainUserId == userId || r.Status == "Accepted")
                .Select(r => new TeamApplicationDto(r.Id, MapTeam(r.Team!), r.Message, r.Status)).ToList(), contact);
    }
}
