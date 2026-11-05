using System.Data;
using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;

namespace SportSpot.Services.Implementations;

public class OwnerScheduleService(SportSpotDbContext db)
{
    public async Task<bool> CanManage(int userId, int venueId, bool ownerOnly = false)
    {
        var user = await db.Users.FindAsync(userId);
        var venue = await db.Venues.FindAsync(venueId);
        return user is { IsActive: true } && venue?.ApprovalStatus == "Approved" && (user.Role == "Admin"
            || (user.Role == "Owner" && (venue.OwnerUserId == userId || (venue.OwnerUserId == null && user.StaffVenueId == venueId)))
            || (!ownerOnly && user.Role == "VenueStaff" && user.StaffVenueId == venueId));
    }

    public async Task<ApiResponse<List<ManagedVenueDto>>> Venues(int userId)
    {
        var user = await db.Users.FindAsync(userId);
        if (user == null || !user.IsActive || user.Role is not ("Owner" or "VenueStaff" or "Admin"))
            return ApiResponse<List<ManagedVenueDto>>.Fail("Bạn không có quyền quản lý sân", 403);
        var rows = await db.Venues.Where(v => v.ApprovalStatus == "Approved" && (user.Role == "Admin"
            || (user.Role == "Owner" && (v.OwnerUserId == userId || (v.OwnerUserId == null && v.Id == user.StaffVenueId)))
            || (user.Role == "VenueStaff" && v.Id == user.StaffVenueId)))
            .OrderBy(v => v.Name).Select(v => new ManagedVenueDto(v.Id, v.Name, v.BasePrice, v.PeakPrice)).ToListAsync();
        return ApiResponse<List<ManagedVenueDto>>.Ok(rows);
    }

    public async Task<ApiResponse<OwnerScheduleDto>> Schedule(int userId, int venueId, DateOnly from, DateOnly to)
    {
        if (!await CanManage(userId, venueId)) return ApiResponse<OwnerScheduleDto>.Fail("Không có quyền quản lý cụm sân này", 403);
        if (to < from || to.DayNumber - from.DayNumber > 30) return ApiResponse<OwnerScheduleDto>.Fail("Chọn khoảng thời gian tối đa 31 ngày");
        var venue = await db.Venues.Include(v => v.SubVenues).Include(v => v.SlotConfigs).FirstOrDefaultAsync(v => v.Id == venueId);
        if (venue == null) return ApiResponse<OwnerScheduleDto>.Fail("Không tìm thấy sân", 404);
        var allSlots = await db.TimeSlots.OrderBy(s => s.StartTime).ThenBy(s => s.Id).ToListAsync();
        var activeSlots = VenueSlotHelper.ResolveActiveSlots(venue, allSlots, venue.SlotConfigs);
        var slots = activeSlots.Select(s => new ScheduleSlotDto(s.SlotId, s.StartTime, s.EndTime, s.IsPeak, s.EffectivePrice)).ToList();
        var bookings = await db.Bookings.Include(b => b.User).Include(b => b.BookingDetails)
            .Where(b => b.SubVenue!.VenueId == venueId && b.PlayDate >= from && b.PlayDate <= to && b.Status != "Cancelled")
            .OrderBy(b => b.PlayDate).ThenBy(b => b.Id).ToListAsync();
        return ApiResponse<OwnerScheduleDto>.Ok(new(new(venue.Id, venue.Name, venue.BasePrice, venue.PeakPrice),
            venue.SubVenues.OrderBy(s => s.Id).Select(s => new ScheduleCourtDto(s.Id, s.Name, s.IsActive)).ToList(), slots,
            bookings.Select(b => new ScheduleBookingDto(b.Id, b.BookingCode, b.SubVenueId, b.PlayDate,
                b.BookingDetails.Where(d => d.Status != "Cancelled").Select(d => d.SlotId).ToList(), b.BookingType, b.Status,
                b.CustomerName ?? b.User?.FullName ?? "", b.CustomerPhone ?? b.User?.PhoneNumber ?? "",
                b.ManagementNote ?? "", b.TotalPrice, b.TotalPrice - b.RemainingBalance, b.RemainingBalance)).ToList()));
    }

    public async Task<ApiResponse<object>> Create(int userId, CreateManagedBookingRequest request)
    {
        var court = await db.SubVenues.Include(s => s.Venue).ThenInclude(v => v!.SlotConfigs).FirstOrDefaultAsync(s => s.Id == request.SubVenueId);
        if (court == null) return ApiResponse<object>.Fail("Không tìm thấy sân con", 404);
        if (!await CanManage(userId, court.VenueId)) return ApiResponse<object>.Fail("Không có quyền quản lý sân", 403);
        if ((!court.IsActive || !court.Venue!.IsActive) && !request.Maintenance) return ApiResponse<object>.Fail("Sân đang ngừng hoạt động");
        if (request.SlotIds.Count == 0 || request.SlotIds.Count > 19 || request.SlotIds.Distinct().Count() != request.SlotIds.Count)
            return ApiResponse<object>.Fail("Chọn khung giờ hợp lệ, không trùng lặp");

        var allSlots = await db.TimeSlots.ToListAsync();
        var activeSlots = VenueSlotHelper.ResolveActiveSlots(court.Venue!, allSlots, court.Venue!.SlotConfigs);
        var activeMap = activeSlots.ToDictionary(s => s.SlotId);

        var slots = allSlots.Where(s => request.SlotIds.Contains(s.Id)).OrderBy(s => s.StartTime).ToList();
        if (slots.Count != request.SlotIds.Count || slots.Any(s => !activeMap.ContainsKey(s.Id)))
            return ApiResponse<object>.Fail("Khung giờ không hợp lệ hoặc cụm sân không hoạt động vào giờ này");
        if (request.PlayDate.ToDateTime(TimeOnly.Parse(slots[0].StartTime)) <= MatchRules.VietnamNow)
            return ApiResponse<object>.Fail("Chỉ được tạo lịch cho khung giờ chưa bắt đầu");
        if (!request.Maintenance && (string.IsNullOrWhiteSpace(request.CustomerName)
            || !System.Text.RegularExpressions.Regex.IsMatch(request.CustomerPhone, @"^\+?[0-9]{9,15}$")))
            return ApiResponse<object>.Fail("Nhập tên và số điện thoại khách (9–15 chữ số)");
        if (request.Maintenance && string.IsNullOrWhiteSpace(request.Note)) return ApiResponse<object>.Fail("Nhập lý do chặn lịch");
        for (var i = 1; i < slots.Count; i++)
            if (slots[i - 1].EndTime != slots[i].StartTime) return ApiResponse<object>.Fail("Chọn các khung giờ liên tiếp");
        var total = request.Maintenance ? 0 : slots.Sum(s => activeMap[s.Id].EffectivePrice);
        if (request.CollectedAmount < 0 || request.CollectedAmount > total) return ApiResponse<object>.Fail("Tiền đã thu phải nằm trong tổng tiền sân");
        return await Write(async () =>
        {
            if (await db.BookingDetails.AnyAsync(d => d.SubVenueId == court.Id && d.PlayDate == request.PlayDate
                && request.SlotIds.Contains(d.SlotId) && d.Status != "Cancelled"))
                return ApiResponse<object>.Fail("Khung giờ đã được đặt hoặc bị chặn. Vui lòng tải lại lịch.", 409);
            var booking = new Booking
            {
                BookingCode = $"OW-{Guid.NewGuid():N}"[..18].ToUpperInvariant(),
                UserId = userId,
                SubVenueId = court.Id,
                PlayDate = request.PlayDate,
                BookingType = request.Maintenance ? "Maintenance" : "WalkIn",
                Status = "Upcoming",
                CustomerName = request.Maintenance ? "Bảo trì" : request.CustomerName.Trim(),
                CustomerPhone = request.CustomerPhone.Trim(),
                ManagementNote = request.Note.Trim(),
                CourtPrice = total,
                TotalPrice = total,
                DepositAmount = request.CollectedAmount,
                RemainingBalance = total - request.CollectedAmount
            };
            foreach (var slot in slots)
                booking.BookingDetails.Add(new BookingDetail
                {
                    SubVenueId = court.Id,
                    PlayDate = booking.PlayDate,
                    SlotId = slot.Id,
                    Price = request.Maintenance ? 0 : activeMap[slot.Id].EffectivePrice
                });
            if (request.CollectedAmount > 0) booking.Transactions.Add(Cash(userId, request.CollectedAmount));
            db.Bookings.Add(booking);
            await db.SaveChangesAsync();
            return ApiResponse<object>.Created(new { booking.Id, booking.BookingCode, booking.TotalPrice, booking.RemainingBalance });
        });
    }

    public async Task<ApiResponse<object>> Cancel(int userId, int id, bool confirmCashRefund) => await Write(async () =>
    {
        var b = await db.Bookings.Include(b => b.SubVenue).Include(b => b.BookingDetails).ThenInclude(d => d.TimeSlot)
            .Include(b => b.Transactions).FirstOrDefaultAsync(b => b.Id == id);
        if (b == null) return ApiResponse<object>.Fail("Không tìm thấy lịch", 404);
        if (!await CanManage(userId, b.SubVenue!.VenueId)) return ApiResponse<object>.Fail("Không có quyền quản lý sân", 403);
        if (b.BookingType is not ("Maintenance" or "WalkIn"))
            return ApiResponse<object>.Fail("Đơn trên app phải dùng luồng hủy và hoàn cọc của khách", 409);
        if (b.Status != "Upcoming") return ApiResponse<object>.Fail("Lịch đã hủy hoặc hoàn tất", 409);
        if (b.BookingType == "WalkIn" && !MatchRules.IsUpcoming(b))
            return ApiResponse<object>.Fail("Đơn tại quầy đã bắt đầu, không thể hủy. Thu đủ tiền rồi hoàn tất đơn.", 409);
        var collected = b.TotalPrice - b.RemainingBalance;
        if (collected > 0 && !confirmCashRefund) return ApiResponse<object>.Fail("Cần xác nhận đã trả lại tiền mặt cho khách trước khi hủy", 409);
        b.Status = "Cancelled";
        foreach (var d in b.BookingDetails) d.Status = "Cancelled";
        if (collected > 0) b.Transactions.Add(Cash(userId, -collected));
        b.RemainingBalance = b.TotalPrice;
        await db.SaveChangesAsync();
        return ApiResponse<object>.Ok(new { refundedCash = collected });
    });

    public async Task<ApiResponse<object>> Collect(int userId, int id, int amount) => await Write(async () =>
    {
        var b = await db.Bookings.Include(b => b.SubVenue).FirstOrDefaultAsync(b => b.Id == id);
        if (b == null) return ApiResponse<object>.Fail("Không tìm thấy đơn", 404);
        if (!await CanManage(userId, b.SubVenue!.VenueId)) return ApiResponse<object>.Fail("Không có quyền quản lý sân", 403);
        if (b.BookingType == "Maintenance" || b.Status == "Cancelled"
            || (b.BookingType == "WalkIn" && b.Status != "Upcoming")
            || amount <= 0 || amount > b.RemainingBalance)
            return ApiResponse<object>.Fail("Số tiền thu không hợp lệ hoặc vượt quá số tiền còn thiếu tại sân");
        b.RemainingBalance -= amount;
        b.Transactions.Add(Cash(userId, amount));
        await db.SaveChangesAsync();
        return ApiResponse<object>.Ok(new { b.RemainingBalance });
    });

    public async Task<ApiResponse<object>> Prices(int userId, int venueId, UpdateVenuePricesRequest request)
    {
        if (!await CanManage(userId, venueId, true)) return ApiResponse<object>.Fail("Chỉ chủ sân được chỉnh giá", 403);
        if (request.BasePrice is < 1 or > 10000000 || request.PeakPrice is < 1 or > 10000000)
            return ApiResponse<object>.Fail("Giá sân phải từ 1 đến 10.000.000 đồng");
        var venue = await db.Venues.FindAsync(venueId);
        if (venue == null) return ApiResponse<object>.Fail("Không tìm thấy sân", 404);
        venue.BasePrice = request.BasePrice; venue.PeakPrice = request.PeakPrice;
        await db.SaveChangesAsync();
        return ApiResponse<object>.Ok(new { venue.BasePrice, venue.PeakPrice });
    }

    public Task<ApiResponse<object>> Complete(int userId, int id) => Write(async () =>
    {
        var b = await db.Bookings.Include(b => b.SubVenue).Include(b => b.BookingDetails).ThenInclude(d => d.TimeSlot)
            .FirstOrDefaultAsync(b => b.Id == id);
        if (b == null) return ApiResponse<object>.Fail("Không tìm thấy đơn", 404);
        if (!await CanManage(userId, b.SubVenue!.VenueId)) return ApiResponse<object>.Fail("Không có quyền quản lý sân", 403);
        if (b.BookingType != "WalkIn" || b.Status != "Upcoming" || b.RemainingBalance != 0)
            return ApiResponse<object>.Fail("Chỉ hoàn tất đơn tại quầy đã thu đủ tiền", 409);
        var end = b.BookingDetails.Select(d => d.TimeSlot!.EndTime).OrderByDescending(t => t).First();
        if (b.PlayDate.ToDateTime(TimeOnly.Parse(end)) > MatchRules.VietnamNow)
            return ApiResponse<object>.Fail("Chỉ hoàn tất sau khi kết thúc giờ thuê sân", 409);
        b.Status = "Completed";
        foreach (var d in b.BookingDetails) d.Status = "Completed";
        await db.SaveChangesAsync();
        return ApiResponse<object>.Ok(new { b.Status });
    });

    private static Transaction Cash(int userId, int amount) => new()
    {
        UserId = userId,
        Amount = amount,
        PaymentGateway = "Cash",
        Status = "Settled",
        TransactionCode = $"CASH-{Guid.NewGuid():N}"
    };

    private async Task<ApiResponse<object>> Write(Func<Task<ApiResponse<object>>> action)
    {
        await using var tx = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        try
        {
            var result = await action();
            if (result.Success) await tx.CommitAsync(); else await tx.RollbackAsync();
            return result;
        }
        catch (DbUpdateException) { await tx.RollbackAsync(); return ApiResponse<object>.Fail("Lịch vừa thay đổi. Vui lòng tải lại.", 409); }
        catch (System.Data.Common.DbException) { await tx.RollbackAsync(); return ApiResponse<object>.Fail("Lịch vừa thay đổi. Vui lòng tải lại.", 409); }
    }
}
