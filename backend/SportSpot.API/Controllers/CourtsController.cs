using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportSpot.API.Data;
using SportSpot.API.DTOs;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api")]
public class CourtsController : ControllerBase
{
    private readonly SportSpotDbContext _context;

    public CourtsController(SportSpotDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Tra cứu lưới khung giờ và trạng thái (Available, Booked, Past) của sân con theo ngày.
    /// Đáp ứng đặc tả Task M3-BE-02 & Feature F06, F07.
    /// </summary>
    [HttpGet("venues/{venueId}/subvenues/{subVenueId}/slots")]
    public async Task<ActionResult<ApiResponse<List<TimeSlotStatusDto>>>> GetSubVenueSlots(
        int venueId,
        int subVenueId,
        [FromQuery] string? date,
        [FromQuery] string? playDate)
    {
        // 1. Kiểm tra ngày hợp lệ (hỗ trợ cả param 'date' và 'playDate')
        var dateStr = !string.IsNullOrWhiteSpace(date) ? date : playDate;
        if (string.IsNullOrWhiteSpace(dateStr) || !DateOnly.TryParse(dateStr, out var targetDate))
        {
            targetDate = DateOnly.FromDateTime(DateTime.Now);
        }

        // 2. Kiểm tra sân con tồn tại
        var subVenue = await _context.SubVenues
            .Include(sv => sv.Venue)
            .FirstOrDefaultAsync(sv => sv.Id == subVenueId && sv.VenueId == venueId);

        if (subVenue == null || subVenue.Venue == null)
        {
            return NotFound(ApiResponse<List<TimeSlotStatusDto>>.Fail(
                $"Không tìm thấy sân con #{subVenueId} thuộc cụm sân #{venueId}", 404));
        }

        // 3. Lấy tất cả khung giờ hệ thống
        var allSlots = await _context.TimeSlots
            .OrderBy(s => s.Id)
            .ToListAsync();

        // 4. Lấy danh sách slot đã được đặt trong ngày đó
        var bookedSlotIds = await _context.BookingDetails
            .Where(bd => bd.SubVenueId == subVenueId &&
                         bd.PlayDate == targetDate &&
                         bd.Status != "Cancelled")
            .Select(bd => bd.SlotId)
            .ToListAsync();

        // 5. Xác định các slot trong quá khứ nếu targetDate là hôm nay
        var today = DateOnly.FromDateTime(DateTime.Now);
        var nowTime = TimeOnly.FromDateTime(DateTime.Now);

        var result = allSlots.Select(slot =>
        {
            var isBooked = bookedSlotIds.Contains(slot.Id);
            var isPast = false;

            if (targetDate < today)
            {
                isPast = true;
            }
            else if (targetDate == today && TimeOnly.TryParse(slot.EndTime, out var slotEnd))
            {
                if (nowTime >= slotEnd)
                {
                    isPast = true;
                }
            }

            string status = "Available";
            if (isPast)
            {
                status = "Past";
            }
            else if (isBooked)
            {
                status = "Booked";
            }

            return new TimeSlotStatusDto
            {
                SlotId = slot.Id,
                StartTime = slot.StartTime,
                EndTime = slot.EndTime,
                IsPeak = slot.IsPeak,
                Price = slot.IsPeak ? subVenue.Venue.PeakPrice : subVenue.Venue.BasePrice,
                IsBooked = isBooked || isPast,
                Status = status
            };
        }).ToList();

        return Ok(ApiResponse<List<TimeSlotStatusDto>>.Ok(
            result, $"Lấy danh sách khung giờ ngày {targetDate:yyyy-MM-dd} thành công"));
    }
}
