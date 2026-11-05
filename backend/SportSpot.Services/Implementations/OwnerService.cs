using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class OwnerService : IOwnerService
{
    private readonly SportSpotDbContext _context;
    private readonly OwnerScheduleService _schedule;

    public OwnerService(SportSpotDbContext context, OwnerScheduleService? schedule = null)
    {
        _context = context;
        _schedule = schedule ?? new OwnerScheduleService(context);
    }

    public async Task<ApiResponse<OwnerDashboardDto>> GetOwnerDashboardForUserAsync(int userId, int? venueId = null)
    {
        var venues = await _schedule.Venues(userId);
        if (!venues.Success)
            return ApiResponse<OwnerDashboardDto>.Fail(venues.Message, venues.StatusCode);

        // No approved venue is a normal onboarding state, not a permission error.
        if (!venueId.HasValue && venues.Data!.Count == 0)
            return ApiResponse<OwnerDashboardDto>.Ok(new OwnerDashboardDto(),
                "Tài khoản chưa có cụm sân được phê duyệt. Hãy đăng ký cụm sân mới hoặc theo dõi hồ sơ đang chờ duyệt.");

        var targetVenueId = venueId ?? venues.Data!.First().Id;
        if (!await _schedule.CanManage(userId, targetVenueId))
            return ApiResponse<OwnerDashboardDto>.Fail("Bạn không có quyền quản lý cụm sân này", 403);

        return await GetOwnerDashboardAsync(targetVenueId);
    }

    public async Task<ApiResponse<OwnerDashboardDto>> GetOwnerDashboardAsync(int venueId)
    {
        var venue = await _context.Venues
            .Include(v => v.Sport)
            .Include(v => v.SubVenues)
            .Include(v => v.SlotConfigs)
            .FirstOrDefaultAsync(v => v.Id == venueId);

        if (venue == null)
        {
            return ApiResponse<OwnerDashboardDto>.Fail("Không tìm thấy cụm sân", 404);
        }

        var subVenueIds = venue.SubVenues.Select(sv => sv.Id).ToList();

        var bookings = await _context.Bookings
            .Include(b => b.User)
            .Include(b => b.SubVenue)
            .Include(b => b.BookingDetails)
                .ThenInclude(bd => bd.TimeSlot)
            .Include(b => b.Transactions)
            .Where(b => subVenueIds.Contains(b.SubVenueId) && b.BookingType != "Maintenance")
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync();

        var allSlots = await _context.TimeSlots.ToListAsync();
        var activeVenueSlots = VenueSlotHelper.ResolveActiveSlots(venue, allSlots, venue.SlotConfigs);
        var totalTimeSlots = activeVenueSlots.Count > 0 ? activeVenueSlots.Count : 13;

        var today = DateOnly.FromDateTime(MatchRules.VietnamNow);

        var activeSubVenuesCount = venue.SubVenues.Count(sv => sv.IsActive);
        var totalSubVenuesCount = venue.SubVenues.Count;

        var totalPossibleSlotsToday = activeSubVenuesCount * totalTimeSlots;
        var bookedDetailsToday = bookings
            .Where(b => b.PlayDate == today && b.Status != "Cancelled")
            .SelectMany(b => b.BookingDetails)
            .Where(bd => bd.Status != "Cancelled")
            .ToList();

        var bookedSlotsTodayCount = bookedDetailsToday.Count;
        var occupancyRate = totalPossibleSlotsToday > 0
            ? (int)Math.Min(100, Math.Round((double)bookedSlotsTodayCount / totalPossibleSlotsToday * 100))
            : 0;

        var nonCancelledBookings = bookings.Where(b => b.Status != "Cancelled" && b.BookingType != "Maintenance").ToList();
        var totalRevenue = nonCancelledBookings.Sum(b => b.TotalPrice);

        var holdingEscrow = bookings
            .SelectMany(b => b.Transactions)
            .Where(t => t.Status == "Holding")
            .Sum(t => t.Amount);

        // Thống kê doanh thu 7 ngày gần nhất
        var dailyRevenues = new List<DailyRevenueDto>();
        for (int i = 6; i >= 0; i--)
        {
            var d = today.AddDays(-i);
            var dayBookings = bookings.Where(b => b.PlayDate == d && b.Status != "Cancelled").ToList();
            var dayOfWeekName = d.DayOfWeek switch
            {
                DayOfWeek.Monday => "T2",
                DayOfWeek.Tuesday => "T3",
                DayOfWeek.Wednesday => "T4",
                DayOfWeek.Thursday => "T5",
                DayOfWeek.Friday => "T6",
                DayOfWeek.Saturday => "T7",
                _ => "CN"
            };

            dailyRevenues.Add(new DailyRevenueDto
            {
                Date = d.ToString("dd/MM"),
                DayOfWeek = dayOfWeekName,
                Revenue = dayBookings.Sum(b => b.TotalPrice),
                BookingCount = dayBookings.Count
            });
        }

        // 15 Đơn đặt gần nhất
        var recentBookings = bookings.Take(15).Select(b =>
        {
            var escrowStatus = b.Transactions.OrderByDescending(t => t.CreatedAt).FirstOrDefault()?.Status ?? "Unpaid";
            if (b.IsCheckedIn) escrowStatus = "Settled";
            else if (b.Status == "Cancelled") escrowStatus = "Refunded";

            return new OwnerBookingDto
            {
                BookingId = b.Id,
                BookingCode = b.BookingCode,
                CustomerName = b.CustomerName ?? b.User?.FullName ?? "Khách đặt sân",
                CustomerPhone = b.CustomerPhone ?? b.User?.PhoneNumber ?? string.Empty,
                SubVenueName = b.SubVenue?.Name ?? "Sân chính",
                PlayDate = b.PlayDate.ToString("yyyy-MM-dd"),
                TimeSlots = b.BookingDetails
                    .OrderBy(bd => bd.TimeSlot != null ? bd.TimeSlot.StartTime : "")
                    .Select(bd => $"{bd.TimeSlot?.StartTime ?? ""}-{bd.TimeSlot?.EndTime ?? ""}")
                    .Where(s => s != "-")
                    .ToList(),
                TotalPrice = b.TotalPrice,
                DepositAmount = b.DepositAmount,
                Status = b.Status,
                EscrowStatus = escrowStatus,
                CreatedAt = b.CreatedAt
            };
        }).ToList();

        // Danh sách sân con và tỷ lệ lấp đầy hôm nay
        var subVenueDtos = venue.SubVenues.Select(sv =>
        {
            var bookedToday = bookings
                .Where(b => b.SubVenueId == sv.Id && b.PlayDate == today && b.Status != "Cancelled")
                .SelectMany(b => b.BookingDetails)
                .Count(bd => bd.Status != "Cancelled");

            return new SubVenueManagementDto
            {
                Id = sv.Id,
                Name = sv.Name,
                IsActive = sv.IsActive,
                TotalSlotsToday = totalTimeSlots,
                BookedSlotsToday = bookedToday
            };
        }).ToList();

        var dto = new OwnerDashboardDto
        {
            VenueId = venue.Id,
            VenueName = venue.Name,
            VenueAddress = venue.Address,
            SportName = venue.Sport?.Name ?? "Thể thao",
            TotalBookings = bookings.Count,
            TotalRevenue = totalRevenue,
            EscrowHoldingAmount = holdingEscrow,
            OccupancyRatePercentage = occupancyRate,
            ActiveSubVenuesCount = activeSubVenuesCount,
            TotalSubVenuesCount = totalSubVenuesCount,
            DailyRevenues = dailyRevenues,
            RecentBookings = recentBookings,
            SubVenues = subVenueDtos
        };

        return ApiResponse<OwnerDashboardDto>.Ok(dto);
    }

    public async Task<ApiResponse<bool>> ToggleSubVenueStatusAsync(int subVenueId, bool? isActive)
    {
        var subVenue = await _context.SubVenues.FirstOrDefaultAsync(sv => sv.Id == subVenueId);
        if (subVenue == null)
        {
            return ApiResponse<bool>.Fail("Không tìm thấy sân con", 404);
        }

        subVenue.IsActive = isActive ?? !subVenue.IsActive;
        await _context.SaveChangesAsync();

        var statusMessage = subVenue.IsActive ? "Đã mở hoạt động sân con" : "Đã tạm dừng hoạt động sân con để bảo trì";
        return ApiResponse<bool>.Ok(subVenue.IsActive, statusMessage);
    }
}
