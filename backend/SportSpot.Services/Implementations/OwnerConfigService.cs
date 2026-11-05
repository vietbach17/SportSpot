using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;

namespace SportSpot.Services.Implementations;

public class OwnerConfigService(SportSpotDbContext db, OwnerScheduleService schedule)
{
    public async Task<ApiResponse<OwnerVenueConfigDto>> GetConfig(int userId, int venueId)
    {
        if (!await schedule.CanManage(userId, venueId, ownerOnly: true))
            return ApiResponse<OwnerVenueConfigDto>.Fail("Chỉ chủ cụm sân hoặc quản trị viên được cấu hình cụm sân này", 403);

        var venue = await db.Venues
            .Include(v => v.Sport)
            .Include(v => v.SubVenues)
            .Include(v => v.Services)
            .Include(v => v.Images)
            .Include(v => v.SlotConfigs)
            .FirstOrDefaultAsync(v => v.Id == venueId);

        if (venue == null)
            return ApiResponse<OwnerVenueConfigDto>.Fail("Không tìm thấy cụm sân", 404);

        var allSlots = await db.TimeSlots.OrderBy(s => s.StartTime).ThenBy(s => s.Id).ToListAsync();
        var slotDtos = VenueSlotHelper.BuildFullSlotConfigDtos(venue, allSlots, venue.SlotConfigs);
        var staff = await db.Users
            .Where(u => u.Role == "VenueStaff" && u.StaffVenueId == venueId)
            .OrderBy(u => u.FullName)
            .Select(u => new VenueStaffMemberDto(u.Id, u.FullName, u.PhoneNumber, u.Email ?? "", u.IsActive))
            .ToListAsync();

        var images = venue.Images.OrderBy(i => i.Position).Select(i => new UploadedVenueImageDto(i.Id, i.Url)).ToList();
        if (images.Count == 0 && !string.IsNullOrWhiteSpace(venue.ImageUrl))
        {
            images.Add(new UploadedVenueImageDto(0, venue.ImageUrl));
        }

        return ApiResponse<OwnerVenueConfigDto>.Ok(new OwnerVenueConfigDto(
            venue.Id,
            venue.Name,
            venue.SportId,
            venue.Sport?.Name ?? "",
            venue.Address,
            venue.District,
            venue.Hotline,
            venue.Latitude,
            venue.Longitude,
            venue.Description ?? "",
            venue.Amenities ?? "",
            venue.IsActive,
            venue.ApprovalStatus,
            venue.BasePrice,
            venue.PeakPrice,
            venue.MaxSlotsPerBooking > 0 ? venue.MaxSlotsPerBooking : 3,
            venue.MinDepositPercent is 30 or 50 or 100 ? venue.MinDepositPercent : 30,
            slotDtos.Count(s => s.IsActive),
            VenueSlotHelper.SummarizeOperatingHours(slotDtos),
            images,
            venue.SubVenues.OrderBy(sv => sv.Id).Select(sv => new SubVenueDto
            {
                Id = sv.Id,
                Name = sv.Name,
                IsActive = sv.IsActive
            }).ToList(),
            venue.Services.OrderBy(s => s.Id).Select(s => new ServiceDto
            {
                Id = s.Id,
                Name = s.Name,
                Type = s.Type,
                Price = s.Price,
                StockQuantity = s.StockQuantity
            }).ToList(),
            slotDtos,
            staff));
    }

    public async Task<ApiResponse<OwnerVenueConfigDto>> UpdateVenueInfo(int userId, int venueId, UpdateOwnerVenueInfoRequest request)
    {
        if (!await schedule.CanManage(userId, venueId, ownerOnly: true))
            return ApiResponse<OwnerVenueConfigDto>.Fail("Chỉ chủ sân mới được cập nhật thông tin cụm sân", 403);

        var venue = await db.Venues.Include(v => v.Images).FirstOrDefaultAsync(v => v.Id == venueId);
        if (venue == null) return ApiResponse<OwnerVenueConfigDto>.Fail("Không tìm thấy cụm sân", 404);

        if (request.Name.Trim().Length < 3 || request.Address.Trim().Length < 5 || string.IsNullOrWhiteSpace(request.District))
            return ApiResponse<OwnerVenueConfigDto>.Fail("Tên sân từ 3 ký tự, địa chỉ từ 5 ký tự và quận/huyện không được để trống");

        if (!await db.Sports.AnyAsync(s => s.Id == request.SportId))
            return ApiResponse<OwnerVenueConfigDto>.Fail("Môn thể thao không hợp lệ");

        if (request.ImageIds != null)
        {
            var distinctIds = request.ImageIds.Where(id => id > 0).Distinct().ToList();
            if (distinctIds.Count is < 1 or > 8)
                return ApiResponse<OwnerVenueConfigDto>.Fail("Bộ sưu tập ảnh cần từ 1 đến 8 ảnh hợp lệ");

            var imgs = await db.VenueImages.Where(i => distinctIds.Contains(i.Id)).ToListAsync();
            if (imgs.Count != distinctIds.Count || imgs.Any(i =>
                    (i.VenueId != null && i.VenueId != venueId) ||
                    (i.VenueId == null && i.UploadedByUserId != userId && i.UploadedByUserId != venue.OwnerUserId)))
                return ApiResponse<OwnerVenueConfigDto>.Fail("Một số ảnh không thuộc quyền quản lý của cụm sân này");

            foreach (var prev in venue.Images.ToList())
            {
                if (!distinctIds.Contains(prev.Id)) prev.Venue = null;
            }
            for (var pos = 0; pos < distinctIds.Count; pos++)
            {
                var img = imgs.Single(i => i.Id == distinctIds[pos]);
                img.Venue = venue;
                img.Position = pos;
            }
            venue.ImageUrl = imgs.Single(i => i.Id == distinctIds[0]).Url;
        }

        venue.Name = request.Name.Trim();
        venue.SportId = request.SportId;
        venue.Address = request.Address.Trim();
        venue.District = request.District.Trim();
        venue.Hotline = request.Hotline.Trim();
        venue.Latitude = request.Latitude;
        venue.Longitude = request.Longitude;
        venue.Description = request.Description.Trim();
        venue.Amenities = request.Amenities.Trim();
        if (venue.ApprovalStatus == "Approved")
        {
            venue.IsActive = request.IsActive;
        }

        await db.SaveChangesAsync();
        return await GetConfig(userId, venueId);
    }

    public async Task<ApiResponse<OwnerVenueConfigDto>> UpdateSlotConfig(int userId, int venueId, UpdateOwnerSlotConfigRequest request)
    {
        if (!await schedule.CanManage(userId, venueId, ownerOnly: true))
            return ApiResponse<OwnerVenueConfigDto>.Fail("Chỉ chủ sân mới được cấu hình khung giờ và chính sách đặt sân", 403);

        if (request.BasePrice is < 1000 or > 10000000 || request.PeakPrice is < 1000 or > 10000000)
            return ApiResponse<OwnerVenueConfigDto>.Fail("Giá giờ thường và giờ cao điểm phải từ 1.000đ đến 10.000.000đ");

        if (request.MaxSlotsPerBooking is < 1 or > 12)
            return ApiResponse<OwnerVenueConfigDto>.Fail("Số lượng slot tối đa mỗi đơn phải từ 1 đến 12 slot");

        if (request.MinDepositPercent is not (30 or 50 or 100))
            return ApiResponse<OwnerVenueConfigDto>.Fail("Tỷ lệ đặt cọc tối thiểu chỉ nhận 30%, 50% hoặc 100%");

        if (request.Slots == null || request.Slots.Count == 0 || !request.Slots.Any(s => s.IsActive))
            return ApiResponse<OwnerVenueConfigDto>.Fail("Cụm sân phải mở ít nhất 1 khung giờ hoạt động trong ngày");

        var venue = await db.Venues.Include(v => v.SlotConfigs).FirstOrDefaultAsync(v => v.Id == venueId);
        if (venue == null) return ApiResponse<OwnerVenueConfigDto>.Fail("Không tìm thấy cụm sân", 404);

        var validSlotIds = (await db.TimeSlots.Where(s => s.Id <= 19).Select(s => s.Id).ToListAsync()).ToHashSet();
        var normalized = request.Slots
            .Where(s => validSlotIds.Contains(s.SlotId))
            .GroupBy(s => s.SlotId)
            .Select(g => g.First())
            .ToList();

        if (!normalized.Any(s => s.IsActive))
            return ApiResponse<OwnerVenueConfigDto>.Fail("Vui lòng bật ít nhất 1 khung giờ hợp lệ");

        if (normalized.Any(s => s.CustomPrice.HasValue && (s.CustomPrice.Value < 1000 || s.CustomPrice.Value > 50000000)))
            return ApiResponse<OwnerVenueConfigDto>.Fail("Giá tùy chỉnh từng slot phải từ 1.000đ trở lên");

        venue.BasePrice = request.BasePrice;
        venue.PeakPrice = request.PeakPrice;
        venue.MaxSlotsPerBooking = request.MaxSlotsPerBooking;
        venue.MinDepositPercent = request.MinDepositPercent;

        db.VenueSlotConfigs.RemoveRange(venue.SlotConfigs);
        foreach (var slotId in validSlotIds)
        {
            var input = normalized.FirstOrDefault(x => x.SlotId == slotId);
            db.VenueSlotConfigs.Add(new VenueSlotConfig
            {
                VenueId = venueId,
                SlotId = slotId,
                IsActive = input?.IsActive ?? false,
                IsPeak = input?.IsPeak ?? false,
                CustomPrice = input?.CustomPrice is > 0 ? input.CustomPrice : null
            });
        }

        await db.SaveChangesAsync();
        return await GetConfig(userId, venueId);
    }

    public async Task<ApiResponse<SubVenueDto>> AddSubVenue(int userId, int venueId, UpsertSubVenueRequest request)
    {
        if (!await schedule.CanManage(userId, venueId, ownerOnly: true))
            return ApiResponse<SubVenueDto>.Fail("Chỉ chủ sân được thêm sân con", 403);

        var name = request.Name.Trim();
        if (string.IsNullOrWhiteSpace(name) || name.Length > 50)
            return ApiResponse<SubVenueDto>.Fail("Tên sân con từ 1 đến 50 ký tự");

        var existingCount = await db.SubVenues.CountAsync(s => s.VenueId == venueId);
        if (existingCount >= 20)
            return ApiResponse<SubVenueDto>.Fail("Mỗi cụm sân tối đa 20 sân con");

        if (await db.SubVenues.AnyAsync(s => s.VenueId == venueId && s.Name.ToLower() == name.ToLower()))
            return ApiResponse<SubVenueDto>.Fail("Tên sân con đã tồn tại trong cụm sân này", 409);

        var sv = new SubVenue { VenueId = venueId, Name = name, IsActive = request.IsActive };
        db.SubVenues.Add(sv);
        await db.SaveChangesAsync();
        return ApiResponse<SubVenueDto>.Created(new SubVenueDto { Id = sv.Id, Name = sv.Name, IsActive = sv.IsActive }, "Đã thêm sân con mới");
    }

    public async Task<ApiResponse<SubVenueDto>> UpdateSubVenue(int userId, int subVenueId, UpsertSubVenueRequest request)
    {
        var sv = await db.SubVenues.FindAsync(subVenueId);
        if (sv == null) return ApiResponse<SubVenueDto>.Fail("Không tìm thấy sân con", 404);
        if (!await schedule.CanManage(userId, sv.VenueId, ownerOnly: true))
            return ApiResponse<SubVenueDto>.Fail("Chỉ chủ sân được chỉnh sửa sân con", 403);

        var name = request.Name.Trim();
        if (string.IsNullOrWhiteSpace(name) || name.Length > 50)
            return ApiResponse<SubVenueDto>.Fail("Tên sân con từ 1 đến 50 ký tự");

        if (await db.SubVenues.AnyAsync(s => s.VenueId == sv.VenueId && s.Id != subVenueId && s.Name.ToLower() == name.ToLower()))
            return ApiResponse<SubVenueDto>.Fail("Tên sân con đã tồn tại trong cụm sân này", 409);

        sv.Name = name;
        sv.IsActive = request.IsActive;
        await db.SaveChangesAsync();
        return ApiResponse<SubVenueDto>.Ok(new SubVenueDto { Id = sv.Id, Name = sv.Name, IsActive = sv.IsActive }, "Đã cập nhật sân con");
    }

    public async Task<ApiResponse<bool>> DeleteSubVenue(int userId, int subVenueId)
    {
        var sv = await db.SubVenues.FindAsync(subVenueId);
        if (sv == null) return ApiResponse<bool>.Fail("Không tìm thấy sân con", 404);
        if (!await schedule.CanManage(userId, sv.VenueId, ownerOnly: true))
            return ApiResponse<bool>.Fail("Chỉ chủ sân được xóa sân con", 403);

        var totalCourts = await db.SubVenues.CountAsync(s => s.VenueId == sv.VenueId);
        if (totalCourts <= 1)
            return ApiResponse<bool>.Fail("Cụm sân phải giữ lại ít nhất 1 sân con", 409);

        if (await db.Bookings.AnyAsync(b => b.SubVenueId == subVenueId))
            return ApiResponse<bool>.Fail("Sân con này đã có lịch sử đặt sân. Vui lòng chuyển sang trạng thái Tạm ngưng/Bảo trì thay vì xóa.", 409);

        db.SubVenues.Remove(sv);
        await db.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Đã xóa sân con");
    }

    public async Task<ApiResponse<ServiceDto>> AddService(int userId, int venueId, UpsertVenueServiceRequest request)
    {
        if (!await schedule.CanManage(userId, venueId, ownerOnly: true))
            return ApiResponse<ServiceDto>.Fail("Chỉ chủ sân được thêm dịch vụ phụ trợ", 403);

        var name = request.Name.Trim();
        if (name.Length < 2 || request.Type is not ("Rental" or "Sale") || request.Price < 1000 || request.StockQuantity < 0)
            return ApiResponse<ServiceDto>.Fail("Kiểm tra tên dịch vụ, loại (Rental/Sale), đơn giá từ 1.000đ và tồn kho >= 0");

        var svc = new Service
        {
            VenueId = venueId,
            Name = name,
            Type = request.Type,
            Price = request.Price,
            StockQuantity = request.StockQuantity
        };
        db.Services.Add(svc);
        await db.SaveChangesAsync();
        return ApiResponse<ServiceDto>.Created(new ServiceDto
        {
            Id = svc.Id,
            Name = svc.Name,
            Type = svc.Type,
            Price = svc.Price,
            StockQuantity = svc.StockQuantity
        }, "Đã thêm dịch vụ phụ trợ");
    }

    public async Task<ApiResponse<ServiceDto>> UpdateService(int userId, int serviceId, UpsertVenueServiceRequest request)
    {
        var svc = await db.Services.FindAsync(serviceId);
        if (svc == null) return ApiResponse<ServiceDto>.Fail("Không tìm thấy dịch vụ", 404);
        if (!await schedule.CanManage(userId, svc.VenueId, ownerOnly: true))
            return ApiResponse<ServiceDto>.Fail("Chỉ chủ sân được cập nhật dịch vụ phụ trợ", 403);

        var name = request.Name.Trim();
        if (name.Length < 2 || request.Type is not ("Rental" or "Sale") || request.Price < 1000 || request.StockQuantity < 0)
            return ApiResponse<ServiceDto>.Fail("Kiểm tra tên dịch vụ, loại (Rental/Sale), đơn giá từ 1.000đ và tồn kho >= 0");

        svc.Name = name;
        svc.Type = request.Type;
        svc.Price = request.Price;
        svc.StockQuantity = request.StockQuantity;
        await db.SaveChangesAsync();
        return ApiResponse<ServiceDto>.Ok(new ServiceDto
        {
            Id = svc.Id,
            Name = svc.Name,
            Type = svc.Type,
            Price = svc.Price,
            StockQuantity = svc.StockQuantity
        }, "Đã cập nhật dịch vụ");
    }

    public async Task<ApiResponse<bool>> DeleteService(int userId, int serviceId)
    {
        var svc = await db.Services.FindAsync(serviceId);
        if (svc == null) return ApiResponse<bool>.Fail("Không tìm thấy dịch vụ", 404);
        if (!await schedule.CanManage(userId, svc.VenueId, ownerOnly: true))
            return ApiResponse<bool>.Fail("Chỉ chủ sân được xóa dịch vụ", 403);

        if (await db.BookingServices.AnyAsync(bs => bs.ServiceId == serviceId))
        {
            svc.StockQuantity = 0;
            await db.SaveChangesAsync();
            return ApiResponse<bool>.Ok(true, "Dịch vụ đã từng phát sinh đơn hàng nên được đưa tồn kho về 0 (ngừng bán)");
        }

        db.Services.Remove(svc);
        await db.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Đã xóa dịch vụ");
    }

    public async Task<ApiResponse<VenueStaffMemberDto>> AssignStaff(int userId, int venueId, AssignVenueStaffRequest request)
    {
        if (!await schedule.CanManage(userId, venueId, ownerOnly: true))
            return ApiResponse<VenueStaffMemberDto>.Fail("Chỉ chủ sân được phân công nhân viên lễ tân", 403);

        var raw = request.Identifier.Trim();
        if (string.IsNullOrWhiteSpace(raw))
            return ApiResponse<VenueStaffMemberDto>.Fail("Nhập số điện thoại hoặc email của nhân viên");

        User? staffUser;
        if (raw.Contains('@'))
        {
            var lower = raw.ToLowerInvariant();
            staffUser = await db.Users.FirstOrDefaultAsync(u => u.Email != null && u.Email.ToLower() == lower);
        }
        else
        {
            var digits = new string(raw.Where(char.IsDigit).ToArray());
            if (digits.StartsWith("84") && digits.Length >= 10) digits = "0" + digits[2..];
            staffUser = await db.Users.FirstOrDefaultAsync(u => u.PhoneNumber == digits || u.PhoneNumber == raw);
        }

        if (staffUser == null)
            return ApiResponse<VenueStaffMemberDto>.Fail("Không tìm thấy tài khoản với SĐT/Email này. Nhân viên cần đăng ký tài khoản SportSpot trước.", 404);

        if (!staffUser.IsActive)
            return ApiResponse<VenueStaffMemberDto>.Fail("Tài khoản này đang bị khóa", 409);

        if (staffUser.Role is "Admin" or "Owner")
            return ApiResponse<VenueStaffMemberDto>.Fail("Không thể gắn tài khoản Admin hoặc Chủ sân khác làm nhân viên lễ tân", 409);

        if (staffUser.Role == "VenueStaff" && staffUser.StaffVenueId != null && staffUser.StaffVenueId != venueId)
            return ApiResponse<VenueStaffMemberDto>.Fail("Nhân viên này đang trực tại một cụm sân khác", 409);

        staffUser.Role = "VenueStaff";
        staffUser.StaffVenueId = venueId;
        await db.SaveChangesAsync();

        return ApiResponse<VenueStaffMemberDto>.Ok(
            new VenueStaffMemberDto(staffUser.Id, staffUser.FullName, staffUser.PhoneNumber, staffUser.Email ?? "", staffUser.IsActive),
            "Đã phân công nhân viên lễ tân cho cụm sân");
    }

    public async Task<ApiResponse<bool>> RemoveStaff(int userId, int venueId, int staffUserId)
    {
        if (!await schedule.CanManage(userId, venueId, ownerOnly: true))
            return ApiResponse<bool>.Fail("Chỉ chủ sân được gỡ nhân viên lễ tân", 403);

        var staffUser = await db.Users.FindAsync(staffUserId);
        if (staffUser == null || staffUser.Role != "VenueStaff" || staffUser.StaffVenueId != venueId)
            return ApiResponse<bool>.Fail("Không tìm thấy nhân viên lễ tân thuộc cụm sân này", 404);

        staffUser.Role = "Player";
        staffUser.StaffVenueId = null;
        await db.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Đã gỡ quyền lễ tân của nhân viên khỏi cụm sân");
    }
}

