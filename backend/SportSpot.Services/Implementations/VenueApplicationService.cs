using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class VenueApplicationService(SportSpotDbContext db, IVenueImageStorage storage)
{
    public IQueryable<Venue> Applications => db.Venues
        .Include(v => v.OwnerUser)
        .Include(v => v.Sport)
        .Include(v => v.SubVenues)
        .Include(v => v.Services)
        .Include(v => v.Images)
        .Include(v => v.SlotConfigs)
        .Include(v => v.ModerationHistory)
            .ThenInclude(l => l.AdminUser);

    public async Task<ApiResponse<List<VenueSlotConfigItemDto>>> SlotTemplates()
    {
        var allSlots = await db.TimeSlots.Where(s => s.Id <= 19).OrderBy(s => s.StartTime).ThenBy(s => s.Id).ToListAsync();
        var dummy = new Venue { BasePrice = 100000, PeakPrice = 150000 };
        return ApiResponse<List<VenueSlotConfigItemDto>>.Ok(VenueSlotHelper.BuildFullSlotConfigDtos(dummy, allSlots));
    }

    public async Task<ApiResponse<UploadedVenueImageDto>> Upload(int userId, byte[] bytes, CancellationToken cancellationToken = default)
    {
        var user = await db.Users.FindAsync(new object[] { userId }, cancellationToken);
        if (user == null || !user.IsActive) return ApiResponse<UploadedVenueImageDto>.Fail("Vui lòng đăng nhập bằng tài khoản đang hoạt động", 401);
        if (user.Role == "VenueStaff") return ApiResponse<UploadedVenueImageDto>.Fail("Tài khoản lễ tân không đăng ký cụm sân", 403);
        if (bytes.Length is < 12 or > 8388608) return ApiResponse<UploadedVenueImageDto>.Fail("Ảnh phải có dung lượng tối đa 8 MB");
        var type = DetectImageType(bytes);
        if (type == null) return ApiResponse<UploadedVenueImageDto>.Fail("Chỉ nhận ảnh JPG, PNG hoặc WebP");
        if (await db.VenueImages.CountAsync(i => i.UploadedByUserId == userId && i.VenueId == null, cancellationToken) >= 24)
            return ApiResponse<UploadedVenueImageDto>.Fail("Bạn có nhiều ảnh chưa sử dụng. Vui lòng dùng ảnh đã tải trong hồ sơ trước.", 409);
        try
        {
            var stored = await storage.UploadAsync(bytes, type, cancellationToken);
            var image = new VenueImage { UploadedByUserId = userId, Url = stored.Url, PublicId = stored.PublicId };
            db.VenueImages.Add(image);
            await db.SaveChangesAsync(cancellationToken);
            return ApiResponse<UploadedVenueImageDto>.Created(new(image.Id, image.Url));
        }
        catch (InvalidOperationException e) { return ApiResponse<UploadedVenueImageDto>.Fail(e.Message, 503); }
        catch (HttpRequestException e) { return ApiResponse<UploadedVenueImageDto>.Fail(e.Message, 502); }
        catch (TaskCanceledException) when (!cancellationToken.IsCancellationRequested)
        { return ApiResponse<UploadedVenueImageDto>.Fail("Tải ảnh quá thời gian chờ. Vui lòng thử lại.", 504); }
    }

    public static string? DetectImageType(byte[] b)
    {
        if (b.Length < 12) return null;
        if (b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) return "image/jpeg";
        if (b.AsSpan(0, 8).SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 })) return "image/png";
        if (System.Text.Encoding.ASCII.GetString(b, 0, 4) == "RIFF" && System.Text.Encoding.ASCII.GetString(b, 8, 4) == "WEBP") return "image/webp";
        return null;
    }

    public async Task<ApiResponse<List<VenueApplicationDto>>> Mine(int userId)
    {
        var allSlots = await db.TimeSlots.Where(s => s.Id <= 19).OrderBy(s => s.StartTime).ThenBy(s => s.Id).ToListAsync();
        var venues = await Applications.Where(v => v.OwnerUserId == userId).OrderByDescending(v => v.Id).ToListAsync();
        return ApiResponse<List<VenueApplicationDto>>.Ok(venues.Select(v => Map(v, allSlots)).ToList());
    }

    public async Task<ApiResponse<List<UploadedVenueImageDto>>> UnusedImages(int userId) =>
        ApiResponse<List<UploadedVenueImageDto>>.Ok(await db.VenueImages.Where(i => i.UploadedByUserId == userId && i.VenueId == null)
            .OrderByDescending(i => i.Id).Select(i => new UploadedVenueImageDto(i.Id, i.Url)).ToListAsync());

    public async Task<ApiResponse<VenueApplicationDto>> Submit(int userId, SubmitVenueRequest request, int? id = null)
    {
        var user = await db.Users.FindAsync(userId);
        if (user == null || !user.IsActive) return ApiResponse<VenueApplicationDto>.Fail("Vui lòng đăng nhập", 401);
        if (user.Role is "Admin" or "VenueStaff") return ApiResponse<VenueApplicationDto>.Fail("Tài khoản này không đăng ký sân", 403);
        if (!Validator.TryValidateObject(request, new ValidationContext(request), new List<ValidationResult>(), true)
            || request.Name.Trim().Length < 3 || request.Address.Trim().Length < 5 || string.IsNullOrWhiteSpace(request.District)
            || request.CourtNames.Any(n => string.IsNullOrWhiteSpace(n) || n.Trim().Length > 50)
            || request.CourtNames.Select(n => n.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).Count() != request.CourtNames.Count
            || request.ImageIds.Distinct().Count() != request.ImageIds.Count)
            return ApiResponse<VenueApplicationDto>.Fail("Kiểm tra thông tin sân, giá từ 1.000đ, 1–20 sân con và 1–8 ảnh hợp lệ");

        var minDep = request.MinDepositPercent is 30 or 50 or 100 ? request.MinDepositPercent : 30;
        var maxSlots = request.MaxSlotsPerBooking is >= 1 and <= 12 ? request.MaxSlotsPerBooking : 3;

        var allSlots = await db.TimeSlots.Where(s => s.Id <= 19).OrderBy(s => s.StartTime).ThenBy(s => s.Id).ToListAsync();
        var validSlotIds = allSlots.Select(s => s.Id).ToHashSet();

        if (request.SlotConfigs is { Count: > 0 })
        {
            if (!request.SlotConfigs.Any(s => s.IsActive && validSlotIds.Contains(s.SlotId)))
                return ApiResponse<VenueApplicationDto>.Fail("Cụm sân phải mở ít nhất 1 khung giờ hoạt động trong ngày");
            if (request.SlotConfigs.Any(s => s.CustomPrice.HasValue && (s.CustomPrice.Value < 1000 || s.CustomPrice.Value > 50000000)))
                return ApiResponse<VenueApplicationDto>.Fail("Giá tùy chỉnh của khung giờ phải từ 1.000đ trở lên");
        }

        if (!await db.Sports.AnyAsync(s => s.Id == request.SportId)) return ApiResponse<VenueApplicationDto>.Fail("Môn thể thao không hợp lệ");
        var venue = id.HasValue ? await Applications.FirstOrDefaultAsync(v => v.Id == id) : null;
        if (id.HasValue && venue?.OwnerUserId != userId) return ApiResponse<VenueApplicationDto>.Fail("Không tìm thấy hồ sơ sân của bạn", 404);
        if (venue != null && (venue.ApprovalStatus != "Rejected" || venue.ReviewRevision != request.Revision))
            return ApiResponse<VenueApplicationDto>.Fail("Chỉ sửa hồ sơ bị từ chối. Vui lòng tải lại trạng thái mới nhất.", 409);
        var images = await db.VenueImages.Where(i => request.ImageIds.Contains(i.Id)).ToListAsync();
        if (images.Count != request.ImageIds.Count || images.Any(i => i.UploadedByUserId != userId || (i.VenueId != null && i.VenueId != id)))
            return ApiResponse<VenueApplicationDto>.Fail("Chọn ảnh do chính bạn tải lên và chưa dùng cho sân khác");
        if (await db.Venues.AnyAsync(v => v.Id != (id ?? 0) && v.OwnerUserId == userId && v.ApprovalStatus != "Rejected"
            && v.Name == request.Name.Trim() && v.Address == request.Address.Trim()))
            return ApiResponse<VenueApplicationDto>.Fail("Bạn đã gửi hồ sơ cho sân này", 409);

        venue ??= new Venue { OwnerUserId = userId, OwnerUser = user };
        venue.Name = request.Name.Trim();
        venue.SportId = request.SportId;
        venue.Address = request.Address.Trim();
        venue.District = request.District.Trim();
        venue.Hotline = request.Hotline.Trim();
        venue.Latitude = request.Latitude;
        venue.Longitude = request.Longitude;
        venue.BasePrice = request.BasePrice;
        venue.PeakPrice = request.PeakPrice;
        venue.MaxSlotsPerBooking = maxSlots;
        venue.MinDepositPercent = minDep;
        venue.Description = request.Description.Trim();
        venue.Amenities = request.Amenities.Trim();
        venue.ApprovalStatus = "Pending";
        venue.IsActive = false;
        venue.SubmittedAt = DateTime.UtcNow;
        venue.RejectionReason = null;
        venue.ReviewedAt = null;
        venue.ReviewedByUserId = null;
        venue.ReviewRevision++;

        venue.SubVenues.Clear();
        foreach (var name in request.CourtNames) venue.SubVenues.Add(new SubVenue { Name = name.Trim() });

        if (request.SlotConfigs is { Count: > 0 })
        {
            venue.SlotConfigs.Clear();
            var grouped = request.SlotConfigs
                .Where(s => validSlotIds.Contains(s.SlotId))
                .GroupBy(s => s.SlotId)
                .ToDictionary(g => g.Key, g => g.First());

            foreach (var slot in allSlots)
            {
                if (grouped.TryGetValue(slot.Id, out var cfg))
                {
                    venue.SlotConfigs.Add(new VenueSlotConfig
                    {
                        SlotId = slot.Id,
                        IsActive = cfg.IsActive,
                        IsPeak = cfg.IsPeak,
                        CustomPrice = cfg.CustomPrice is > 0 ? cfg.CustomPrice : null
                    });
                }
                else
                {
                    venue.SlotConfigs.Add(new VenueSlotConfig
                    {
                        SlotId = slot.Id,
                        IsActive = false,
                        IsPeak = slot.IsPeak,
                        CustomPrice = null
                    });
                }
            }
        }

        if (request.Services != null)
        {
            venue.Services.Clear();
            foreach (var s in request.Services.Where(x => !string.IsNullOrWhiteSpace(x.Name) && x.Price >= 1000))
            {
                venue.Services.Add(new Service
                {
                    Name = s.Name.Trim(),
                    Type = s.Type is "Rental" or "Sale" ? s.Type : "Sale",
                    Price = s.Price,
                    StockQuantity = Math.Max(0, s.StockQuantity)
                });
            }
        }

        foreach (var previous in venue.Images.ToList()) if (!request.ImageIds.Contains(previous.Id)) previous.Venue = null;
        for (var position = 0; position < request.ImageIds.Count; position++)
        {
            var image = images.Single(i => i.Id == request.ImageIds[position]);
            image.Venue = venue;
            image.Position = position;
        }
        venue.ImageUrl = images.Single(i => i.Id == request.ImageIds[0]).Url;
        if (!id.HasValue) db.Venues.Add(venue);
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException) { return ApiResponse<VenueApplicationDto>.Fail("Hồ sơ hoặc ảnh vừa thay đổi. Vui lòng tải lại.", 409); }
        venue.Sport = await db.Sports.FindAsync(request.SportId);
        return ApiResponse<VenueApplicationDto>.Created(Map(venue, allSlots), "Đã gửi hồ sơ. Sân sẽ nhận đặt lịch sau khi được duyệt.");
    }

    public static VenueApplicationDto Map(Venue v, IEnumerable<TimeSlot>? allSlots = null)
    {
        var slotsList = (allSlots ?? Array.Empty<TimeSlot>()).ToList();
        var slotDtos = slotsList.Count > 0
            ? VenueSlotHelper.BuildFullSlotConfigDtos(v, slotsList, v.SlotConfigs)
            : v.SlotConfigs.OrderBy(c => c.SlotId)
                .Select(c => new VenueSlotConfigItemDto(
                    c.SlotId,
                    c.TimeSlot?.StartTime ?? "",
                    c.TimeSlot?.EndTime ?? "",
                    c.IsActive,
                    c.IsPeak,
                    c.CustomPrice,
                    c.CustomPrice is > 0 ? c.CustomPrice.Value : (c.IsPeak ? v.PeakPrice : v.BasePrice)))
                .ToList();

        var activeSlotCount = slotDtos.Count > 0 ? slotDtos.Count(s => s.IsActive) : 13;
        var summary = slotDtos.Count > 0
            ? VenueSlotHelper.SummarizeOperatingHours(slotDtos)
            : "06:00 - 22:00 (13 slot/ngày)";

        return new VenueApplicationDto(
            v.Id,
            v.Name,
            v.SportId,
            v.Sport?.Name ?? "",
            v.Address,
            v.District,
            v.Hotline,
            v.Latitude,
            v.Longitude,
            v.BasePrice,
            v.PeakPrice,
            v.MaxSlotsPerBooking > 0 ? v.MaxSlotsPerBooking : 3,
            v.MinDepositPercent is 30 or 50 or 100 ? v.MinDepositPercent : 30,
            activeSlotCount,
            summary,
            v.Description ?? "",
            v.Amenities ?? "",
            v.ApprovalStatus,
            v.IsActive,
            v.OwnerUserId,
            v.OwnerUser?.FullName ?? "Dữ liệu khởi tạo hệ thống",
            v.OwnerUser?.PhoneNumber ?? "",
            v.SubmittedAt,
            v.RejectionReason,
            v.ReviewRevision,
            v.SubVenues.OrderBy(s => s.Id).Select(s => s.Name).ToList(),
            v.Images.OrderBy(i => i.Position).Select(i => new UploadedVenueImageDto(i.Id, i.Url)).ToList(),
            slotDtos,
            v.Services.OrderBy(s => s.Id).Select(s => new ServiceDto
            {
                Id = s.Id,
                Name = s.Name,
                Type = s.Type,
                Price = s.Price,
                StockQuantity = s.StockQuantity
            }).ToList(),
            v.ModerationHistory.OrderByDescending(l => l.CreatedAt)
                .Select(l => new ModerationLogDto(l.Decision, l.Reason, l.AdminUser?.FullName ?? "Admin", l.CreatedAt))
                .ToList());
    }
}
