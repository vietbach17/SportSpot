using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportSpot.API.Data;
using SportSpot.API.DTOs;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VenuesController : ControllerBase
{
    private readonly SportSpotDbContext _context;

    public VenuesController(SportSpotDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<VenueListDto>>>> GetVenues(
        [FromQuery] int? sportId,
        [FromQuery] string? search,
        [FromQuery] double? userLat,
        [FromQuery] double? userLng,
        [FromQuery] double? radiusKm)
    {
        var query = _context.Venues
            .Include(v => v.Sport)
            .Where(v => v.IsActive)
            .AsQueryable();

        if (sportId.HasValue && sportId.Value > 0)
        {
            query = query.Where(v => v.SportId == sportId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim().ToLower();
            query = query.Where(v => v.Name.ToLower().Contains(keyword) || 
                                     v.District.ToLower().Contains(keyword) || 
                                     v.Address.ToLower().Contains(keyword));
        }

        var venues = await query.ToListAsync();

        var result = venues.Select(v =>
        {
            double? distance = null;
            if (userLat.HasValue && userLng.HasValue)
            {
                distance = CalculateDistanceKm(userLat.Value, userLng.Value, (double)v.Latitude, (double)v.Longitude);
            }

            return new VenueListDto
            {
                Id = v.Id,
                SportId = v.SportId,
                SportName = v.Sport?.Name ?? string.Empty,
                Name = v.Name,
                Address = v.Address,
                District = v.District,
                Latitude = v.Latitude,
                Longitude = v.Longitude,
                Hotline = v.Hotline,
                ImageUrl = v.ImageUrl,
                BasePrice = v.BasePrice,
                PeakPrice = v.PeakPrice,
                Rating = v.Rating,
                Amenities = v.Amenities,
                DistanceKm = distance
            };
        });

        if (radiusKm.HasValue && userLat.HasValue && userLng.HasValue)
        {
            result = result.Where(v => v.DistanceKm <= radiusKm.Value);
        }

        var sortedResult = userLat.HasValue && userLng.HasValue
            ? result.OrderBy(v => v.DistanceKm).ToList()
            : result.OrderByDescending(v => v.Rating).ToList();

        return Ok(ApiResponse<List<VenueListDto>>.Ok(sortedResult, "Lấy danh sách cụm sân thành công"));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<VenueDetailDto>>> GetVenueDetail(int id)
    {
        var venue = await _context.Venues
            .Include(v => v.Sport)
            .Include(v => v.SubVenues.Where(sv => sv.IsActive))
            .Include(v => v.Services)
            .FirstOrDefaultAsync(v => v.Id == id && v.IsActive);

        if (venue == null)
        {
            return NotFound(ApiResponse<VenueDetailDto>.Fail("Không tìm thấy cụm sân", 404));
        }

        var detail = new VenueDetailDto
        {
            Id = venue.Id,
            SportId = venue.SportId,
            SportName = venue.Sport?.Name ?? string.Empty,
            Name = venue.Name,
            Address = venue.Address,
            District = venue.District,
            Latitude = venue.Latitude,
            Longitude = venue.Longitude,
            Hotline = venue.Hotline,
            ImageUrl = venue.ImageUrl,
            BasePrice = venue.BasePrice,
            PeakPrice = venue.PeakPrice,
            Rating = venue.Rating,
            Amenities = venue.Amenities,
            Description = venue.Description,
            SubVenues = venue.SubVenues.Select(sv => new SubVenueDto
            {
                Id = sv.Id,
                Name = sv.Name,
                IsActive = sv.IsActive
            }).ToList(),
            Services = venue.Services.Select(s => new ServiceDto
            {
                Id = s.Id,
                Name = s.Name,
                Type = s.Type,
                Price = s.Price,
                StockQuantity = s.StockQuantity
            }).ToList()
        };

        return Ok(ApiResponse<VenueDetailDto>.Ok(detail, "Lấy chi tiết cụm sân thành công"));
    }

    [HttpGet("{id}/slots")]
    public async Task<ActionResult<ApiResponse<List<TimeSlotStatusDto>>>> GetVenueTimeSlots(
        int id,
        [FromQuery] int subVenueId,
        [FromQuery] DateOnly playDate)
    {
        var venue = await _context.Venues.FindAsync(id);
        if (venue == null)
        {
            return NotFound(ApiResponse<List<TimeSlotStatusDto>>.Fail("Không tìm thấy cụm sân", 404));
        }

        var allSlots = await _context.TimeSlots
            .OrderBy(s => s.Id)
            .ToListAsync();

        var bookedSlotIds = await _context.BookingDetails
            .Where(bd => bd.SubVenueId == subVenueId && 
                         bd.PlayDate == playDate && 
                         bd.Status != "Cancelled")
            .Select(bd => bd.SlotId)
            .ToListAsync();

        var slotStatuses = allSlots.Select(slot => new TimeSlotStatusDto
        {
            SlotId = slot.Id,
            StartTime = slot.StartTime,
            EndTime = slot.EndTime,
            IsPeak = slot.IsPeak,
            Price = slot.IsPeak ? venue.PeakPrice : venue.BasePrice,
            IsBooked = bookedSlotIds.Contains(slot.Id)
        }).ToList();

        return Ok(ApiResponse<List<TimeSlotStatusDto>>.Ok(slotStatuses, "Lấy danh sách khung giờ thành công"));
    }

    private static double CalculateDistanceKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double earthRadiusKm = 6371.0;
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return Math.Round(earthRadiusKm * c, 2);
    }

    private static double ToRadians(double angle) => (Math.PI / 180) * angle;
}
