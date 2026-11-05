using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;

namespace SportSpot.Services.Implementations;

public class AdminService(SportSpotDbContext db, VenueApplicationService applications)
{
    public async Task<bool> IsAdmin(int userId) => await db.Users.AnyAsync(u => u.Id == userId && u.Role == "Admin" && u.IsActive);
    public async Task<ApiResponse<List<VenueApplicationDto>>> Venues(int userId)
    {
        if (!await IsAdmin(userId)) return ApiResponse<List<VenueApplicationDto>>.Fail("Chỉ quản trị viên có quyền truy cập", 403);
        return ApiResponse<List<VenueApplicationDto>>.Ok((await applications.Applications.OrderByDescending(v => v.SubmittedAt)
            .ThenByDescending(v => v.Id).ToListAsync()).Select(VenueApplicationService.Map).ToList());
    }
    public async Task<ApiResponse<List<AdminUserDto>>> Users(int userId)
    {
        if (!await IsAdmin(userId)) return ApiResponse<List<AdminUserDto>>.Fail("Chỉ quản trị viên có quyền truy cập", 403);
        return ApiResponse<List<AdminUserDto>>.Ok(await db.Users.OrderByDescending(u => u.CreatedAt)
            .Select(u => new AdminUserDto(u.Id, u.FullName, u.PhoneNumber, u.Email ?? "", u.Role, u.IsActive, u.CreatedAt,
                db.Venues.Count(v => v.OwnerUserId == u.Id))).ToListAsync());
    }
    public async Task<ApiResponse<AdminOverviewDto>> Overview(int userId)
    {
        if (!await IsAdmin(userId)) return ApiResponse<AdminOverviewDto>.Fail("Chỉ quản trị viên có quyền truy cập", 403);
        var today = DateOnly.FromDateTime(MatchRules.VietnamNow);
        var start = today.AddDays(-29);
        var bookings = await db.Bookings.Where(b => b.PlayDate >= start && b.PlayDate <= today
            && b.Status != "Cancelled" && b.BookingType != "Maintenance").Select(b => new { b.PlayDate, b.TotalPrice }).ToListAsync();
        var activity = Enumerable.Range(0, 7).Select(i => {
            var date = today.AddDays(i - 6); var rows = bookings.Where(b => b.PlayDate == date).ToList();
            return new AdminDayDto(date.ToString("yyyy-MM-dd"), rows.Count, rows.Sum(b => (long)b.TotalPrice));
        }).ToList();
        var pending = await applications.Applications.Where(v => v.ApprovalStatus == "Pending").OrderBy(v => v.SubmittedAt).Take(5).ToListAsync();
        // Sum in memory also works with SQLite's decimal/provider limitations.
        var holding = await db.Transactions.Where(t => t.Status == "Holding").Select(t => t.Amount).ToListAsync();
        return ApiResponse<AdminOverviewDto>.Ok(new(await db.Users.CountAsync(), await db.Users.CountAsync(u => u.IsActive),
            await db.Venues.CountAsync(), await db.Venues.CountAsync(v => v.ApprovalStatus == "Pending"),
            await db.Venues.CountAsync(v => v.ApprovalStatus == "Approved" && v.IsActive),
            await db.Bookings.CountAsync(b => b.PlayDate >= today && b.Status == "Upcoming" && b.BookingType != "Maintenance"),
            bookings.Sum(b => (long)b.TotalPrice), holding.Sum(a => (long)a), activity, pending.Select(VenueApplicationService.Map).ToList()));
    }
    public async Task<ApiResponse<VenueApplicationDto>> Review(int userId, int id, ReviewVenueRequest request)
    {
        if (!await IsAdmin(userId)) return ApiResponse<VenueApplicationDto>.Fail("Chỉ quản trị viên được duyệt sân", 403);
        if (!request.Approve && string.IsNullOrWhiteSpace(request.Reason)) return ApiResponse<VenueApplicationDto>.Fail("Nhập lý do từ chối để chủ sân có thể bổ sung");
        var venue = await applications.Applications.FirstOrDefaultAsync(v => v.Id == id);
        if (venue == null) return ApiResponse<VenueApplicationDto>.Fail("Không tìm thấy hồ sơ", 404);
        if (venue.ApprovalStatus != "Pending" || venue.ReviewRevision != request.Revision)
            return ApiResponse<VenueApplicationDto>.Fail("Hồ sơ đã được xử lý hoặc vừa thay đổi. Vui lòng tải lại.", 409);
        if (request.Approve && (venue.OwnerUser == null || !venue.OwnerUser.IsActive || !venue.Images.Any() || !venue.SubVenues.Any()))
            return ApiResponse<VenueApplicationDto>.Fail("Hồ sơ thiếu ảnh/sân con hoặc tài khoản chủ sân đã bị khóa", 409);
        venue.ApprovalStatus = request.Approve ? "Approved" : "Rejected";
        venue.IsActive = request.Approve; venue.ReviewedAt = DateTime.UtcNow; venue.ReviewedByUserId = userId; venue.ReviewRevision++;
        venue.RejectionReason = request.Approve ? null : request.Reason.Trim();
        if (request.Approve && venue.OwnerUser!.Role is "Player" or "Customer") venue.OwnerUser.Role = "Owner";
        db.VenueModerationLogs.Add(new VenueModerationLog { VenueId = id, AdminUserId = userId,
            Decision = venue.ApprovalStatus, Reason = request.Reason.Trim() });
        db.Notifications.Add(new Notification { UserId = venue.OwnerUserId!.Value, Type = "venue",
            Title = request.Approve ? "Sân đã được duyệt" : "Hồ sơ sân cần bổ sung",
            Message = request.Approve ? $"{venue.Name} đã được mở nhận đặt sân. Mở lại tài khoản để cập nhật quyền chủ sân."
                : $"{venue.Name}: {venue.RejectionReason}" });
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException) { return ApiResponse<VenueApplicationDto>.Fail("Hồ sơ vừa được xử lý. Vui lòng tải lại.", 409); }
        return ApiResponse<VenueApplicationDto>.Ok(VenueApplicationService.Map(venue));
    }
    public async Task<ApiResponse<bool>> SetUserActive(int adminId, int id, bool active)
    {
        if (!await IsAdmin(adminId)) return ApiResponse<bool>.Fail("Chỉ quản trị viên có quyền truy cập", 403);
        var user = await db.Users.FindAsync(id);
        if (user == null) return ApiResponse<bool>.Fail("Không tìm thấy người dùng", 404);
        if (user.Role == "Admin" || user.Id == adminId) return ApiResponse<bool>.Fail("Không thay đổi trạng thái tài khoản quản trị viên", 409);
        user.IsActive = active; await db.SaveChangesAsync();
        return ApiResponse<bool>.Ok(active);
    }
    public async Task<ApiResponse<bool>> SetVenueActive(int adminId, int id, bool active)
    {
        if (!await IsAdmin(adminId)) return ApiResponse<bool>.Fail("Chỉ quản trị viên có quyền truy cập", 403);
        var venue = await db.Venues.FindAsync(id);
        if (venue == null) return ApiResponse<bool>.Fail("Không tìm thấy sân", 404);
        if (venue.ApprovalStatus != "Approved") return ApiResponse<bool>.Fail("Chỉ đổi hiển thị sân đã được duyệt", 409);
        venue.IsActive = active; venue.ReviewRevision++;
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException) { return ApiResponse<bool>.Fail("Trạng thái vừa thay đổi. Vui lòng tải lại.", 409); }
        return ApiResponse<bool>.Ok(active);
    }
}
