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
        var allSlots = await db.TimeSlots.Where(s => s.Id <= 19).OrderBy(s => s.StartTime).ThenBy(s => s.Id).ToListAsync();
        var list = await applications.Applications
            .OrderByDescending(v => v.ApprovalStatus == "Pending")
            .ThenByDescending(v => v.SubmittedAt)
            .ThenByDescending(v => v.Id)
            .ToListAsync();
        return ApiResponse<List<VenueApplicationDto>>.Ok(list.Select(v => VenueApplicationService.Map(v, allSlots)).ToList());
    }

    public async Task<ApiResponse<List<AdminUserDto>>> Users(int userId)
    {
        if (!await IsAdmin(userId)) return ApiResponse<List<AdminUserDto>>.Fail("Chỉ quản trị viên có quyền truy cập", 403);
        var venuesMap = await db.Venues.ToDictionaryAsync(v => v.Id, v => v.Name);
        var users = await db.Users.OrderByDescending(u => u.CreatedAt).ToListAsync();
        var ownedCounts = await db.Venues
            .Where(v => v.OwnerUserId != null)
            .GroupBy(v => v.OwnerUserId!.Value)
            .Select(g => new { UserId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.UserId, x => x.Count);

        return ApiResponse<List<AdminUserDto>>.Ok(users.Select(u => new AdminUserDto(
            u.Id,
            u.FullName,
            u.PhoneNumber,
            u.Email ?? "",
            u.Role,
            u.IsActive,
            u.CreatedAt,
            ownedCounts.GetValueOrDefault(u.Id, 0),
            u.StaffVenueId,
            u.StaffVenueId.HasValue && venuesMap.TryGetValue(u.StaffVenueId.Value, out var vn) ? vn : null
        )).ToList());
    }

    public async Task<ApiResponse<AdminOverviewDto>> Overview(int userId)
    {
        if (!await IsAdmin(userId)) return ApiResponse<AdminOverviewDto>.Fail("Chỉ quản trị viên có quyền truy cập", 403);
        var today = DateOnly.FromDateTime(MatchRules.VietnamNow);
        var start = today.AddDays(-29);
        var bookings = await db.Bookings.Where(b => b.PlayDate >= start && b.PlayDate <= today
            && b.Status != "Cancelled" && b.BookingType != "Maintenance").Select(b => new { b.PlayDate, b.TotalPrice }).ToListAsync();
        var activity = Enumerable.Range(0, 7).Select(i =>
        {
            var date = today.AddDays(i - 6);
            var rows = bookings.Where(b => b.PlayDate == date).ToList();
            return new AdminDayDto(date.ToString("yyyy-MM-dd"), rows.Count, rows.Sum(b => (long)b.TotalPrice));
        }).ToList();
        var allSlots = await db.TimeSlots.Where(s => s.Id <= 19).OrderBy(s => s.StartTime).ThenBy(s => s.Id).ToListAsync();
        var pending = await applications.Applications.Where(v => v.ApprovalStatus == "Pending").OrderBy(v => v.SubmittedAt).Take(8).ToListAsync();
        var holding = await db.Transactions.Where(t => t.Status == "Holding").Select(t => t.Amount).ToListAsync();
        return ApiResponse<AdminOverviewDto>.Ok(new(
            await db.Users.CountAsync(),
            await db.Users.CountAsync(u => u.IsActive),
            await db.Venues.CountAsync(),
            await db.Venues.CountAsync(v => v.ApprovalStatus == "Pending"),
            await db.Venues.CountAsync(v => v.ApprovalStatus == "Approved" && v.IsActive),
            await db.Bookings.CountAsync(b => b.PlayDate >= today && b.Status == "Upcoming" && b.BookingType != "Maintenance"),
            bookings.Sum(b => (long)b.TotalPrice),
            holding.Sum(a => (long)a),
            activity,
            pending.Select(v => VenueApplicationService.Map(v, allSlots)).ToList()));
    }

    public async Task<ApiResponse<VenueApplicationDto>> Review(int userId, int id, ReviewVenueRequest request)
    {
        if (!await IsAdmin(userId)) return ApiResponse<VenueApplicationDto>.Fail("Chỉ quản trị viên được duyệt sân", 403);
        if (!request.Approve && string.IsNullOrWhiteSpace(request.Reason))
            return ApiResponse<VenueApplicationDto>.Fail("Nhập lý do từ chối để chủ sân có thể bổ sung");
        var venue = await applications.Applications.FirstOrDefaultAsync(v => v.Id == id);
        if (venue == null) return ApiResponse<VenueApplicationDto>.Fail("Không tìm thấy hồ sơ", 404);
        if (venue.ApprovalStatus != "Pending" || venue.ReviewRevision != request.Revision)
            return ApiResponse<VenueApplicationDto>.Fail("Hồ sơ đã được xử lý hoặc vừa thay đổi. Vui lòng tải lại.", 409);
        if (request.Approve && (venue.OwnerUser == null || !venue.OwnerUser.IsActive || !venue.Images.Any() || !venue.SubVenues.Any()))
            return ApiResponse<VenueApplicationDto>.Fail("Hồ sơ thiếu ảnh/sân con hoặc tài khoản chủ sân đã bị khóa", 409);

        venue.ApprovalStatus = request.Approve ? "Approved" : "Rejected";
        venue.IsActive = request.Approve;
        venue.ReviewedAt = DateTime.UtcNow;
        venue.ReviewedByUserId = userId;
        venue.ReviewRevision++;
        venue.RejectionReason = request.Approve ? null : request.Reason.Trim();

        if (request.Approve && venue.OwnerUser != null)
        {
            if (venue.OwnerUser.Role is "Player" or "Customer")
            {
                venue.OwnerUser.Role = "Owner";
            }
            venue.OwnerUser.StaffVenueId ??= venue.Id;
        }

        db.VenueModerationLogs.Add(new VenueModerationLog
        {
            VenueId = id,
            AdminUserId = userId,
            Decision = venue.ApprovalStatus,
            Reason = request.Approve ? (string.IsNullOrWhiteSpace(request.Reason) ? "Hồ sơ hợp lệ, đã phê duyệt mở cụm sân." : request.Reason.Trim()) : request.Reason.Trim()
        });

        if (venue.OwnerUserId.HasValue)
        {
            db.Notifications.Add(new Notification
            {
                UserId = venue.OwnerUserId.Value,
                Type = "venue",
                Title = request.Approve ? "Cụm sân đã được phê duyệt!" : "Hồ sơ đăng ký sân cần bổ sung",
                Message = request.Approve
                    ? $"Cụm sân '{venue.Name}' đã được phê duyệt và mở nhận đặt lịch. Tài khoản của bạn đã được kích hoạt quyền Chủ cụm sân (Owner)."
                    : $"Cụm sân '{venue.Name}': {venue.RejectionReason}"
            });
        }

        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException) { return ApiResponse<VenueApplicationDto>.Fail("Hồ sơ vừa được xử lý. Vui lòng tải lại.", 409); }

        var allSlots = await db.TimeSlots.Where(s => s.Id <= 19).OrderBy(s => s.StartTime).ThenBy(s => s.Id).ToListAsync();
        return ApiResponse<VenueApplicationDto>.Ok(
            VenueApplicationService.Map(venue, allSlots),
            request.Approve ? "Đã phê duyệt cụm sân và nâng cấp quyền Chủ cụm sân" : "Đã từ chối hồ sơ kèm lý do phản hồi");
    }

    public async Task<ApiResponse<bool>> SetUserActive(int adminId, int id, bool active)
    {
        if (!await IsAdmin(adminId)) return ApiResponse<bool>.Fail("Chỉ quản trị viên có quyền truy cập", 403);
        var user = await db.Users.FindAsync(id);
        if (user == null) return ApiResponse<bool>.Fail("Không tìm thấy người dùng", 404);
        if (user.Role == "Admin" || user.Id == adminId) return ApiResponse<bool>.Fail("Không thay đổi trạng thái tài khoản quản trị viên", 409);
        user.IsActive = active;
        await db.SaveChangesAsync();
        return ApiResponse<bool>.Ok(active, active ? "Đã mở khóa tài khoản" : "Đã khóa tài khoản");
    }

    public async Task<ApiResponse<AdminUserDto>> AssignRoleAndVenue(int adminId, int targetUserId, AssignRoleVenueRequest request)
    {
        if (!await IsAdmin(adminId)) return ApiResponse<AdminUserDto>.Fail("Chỉ quản trị viên có quyền truy cập", 403);
        var user = await db.Users.FindAsync(targetUserId);
        if (user == null) return ApiResponse<AdminUserDto>.Fail("Không tìm thấy người dùng", 404);
        if (user.Role == "Admin" || user.Id == adminId)
            return ApiResponse<AdminUserDto>.Fail("Không thay đổi vai trò của quản trị viên", 409);

        var role = request.Role.Trim();
        if (role is not ("Player" or "VenueStaff" or "Owner"))
            return ApiResponse<AdminUserDto>.Fail("Vai trò chỉ nhận Player, VenueStaff hoặc Owner");

        Venue? assignedVenue = null;
        if (request.VenueId.HasValue && request.VenueId.Value > 0)
        {
            assignedVenue = await db.Venues.FindAsync(request.VenueId.Value);
            if (assignedVenue == null || assignedVenue.ApprovalStatus != "Approved")
                return ApiResponse<AdminUserDto>.Fail("Chỉ gán vào cụm sân đã được duyệt", 404);
        }

        if (role == "VenueStaff" && assignedVenue == null)
            return ApiResponse<AdminUserDto>.Fail("Nhân viên lễ tân (VenueStaff) bắt buộc phải gắn với 1 cụm sân cụ thể");

        user.Role = role;
        user.StaffVenueId = role == "Player" ? null : assignedVenue?.Id;

        if (role == "Owner" && assignedVenue != null)
        {
            assignedVenue.OwnerUserId = user.Id;
        }

        await db.SaveChangesAsync();
        var venueCount = await db.Venues.CountAsync(v => v.OwnerUserId == user.Id);
        return ApiResponse<AdminUserDto>.Ok(
            new AdminUserDto(user.Id, user.FullName, user.PhoneNumber, user.Email ?? "", user.Role, user.IsActive,
                user.CreatedAt, venueCount, user.StaffVenueId, assignedVenue?.Name),
            "Đã cập nhật vai trò và cụm sân phụ trách");
    }

    public async Task<ApiResponse<bool>> SetVenueActive(int adminId, int id, bool active)
    {
        if (!await IsAdmin(adminId)) return ApiResponse<bool>.Fail("Chỉ quản trị viên có quyền truy cập", 403);
        var venue = await db.Venues.FindAsync(id);
        if (venue == null) return ApiResponse<bool>.Fail("Không tìm thấy sân", 404);
        if (venue.ApprovalStatus != "Approved") return ApiResponse<bool>.Fail("Chỉ đổi hiển thị sân đã được duyệt", 409);
        venue.IsActive = active;
        venue.ReviewRevision++;
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException) { return ApiResponse<bool>.Fail("Trạng thái vừa thay đổi. Vui lòng tải lại.", 409); }
        return ApiResponse<bool>.Ok(active, active ? "Đã mở hiển thị cụm sân" : "Đã tạm ẩn cụm sân");
    }
}
