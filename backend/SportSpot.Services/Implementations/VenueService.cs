using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class VenueService : IVenueService
{
    private readonly IUnitOfWork _unitOfWork;

    public VenueService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<List<VenueListDto>>> GetVenuesAsync(
        int? sportId,
        string? search,
        double? userLat,
        double? userLng,
        double? radiusKm)
    {
        var venues = await _unitOfWork.Venues.GetActiveVenuesAsync(sportId, search);

        var result = venues.Select(v =>
        {
            double? distance = null;
            if (userLat.HasValue && userLng.HasValue)
            {
                distance = HaversineHelper.CalculateDistanceKm(
                    userLat.Value, userLng.Value, (double)v.Latitude, (double)v.Longitude);
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

        return ApiResponse<List<VenueListDto>>.Ok(sortedResult, "Lấy danh sách cụm sân thành công");
    }

    public async Task<ApiResponse<VenueDetailDto>> GetVenueDetailAsync(int id)
    {
        var venue = await _unitOfWork.Venues.GetVenueDetailByIdAsync(id);
        if (venue == null)
        {
            return ApiResponse<VenueDetailDto>.Fail("Không tìm thấy cụm sân", 404);
        }

        var gallery = new List<string>();
        if (!string.IsNullOrEmpty(venue.ImageUrl)) gallery.Add(venue.ImageUrl);

        if (venue.SportId == 1) // Cầu lông
        {
            gallery.AddRange(new[]
            {
                "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200",
                "https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=1200",
                "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200"
            });
        }
        else if (venue.SportId == 2) // Pickleball
        {
            gallery.AddRange(new[]
            {
                "https://images.unsplash.com/photo-1599586120429-48281b6f0ece?w=1200",
                "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200"
            });
        }
        else if (venue.SportId == 3) // Bóng đá
        {
            gallery.AddRange(new[]
            {
                "https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=1200",
                "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1200",
                "https://images.unsplash.com/photo-1517466787929-bc90951d0974?w=1200"
            });
        }
        else // Bóng rổ
        {
            gallery.AddRange(new[]
            {
                "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200",
                "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1200"
            });
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
            GalleryImages = gallery.Distinct().ToList(),
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

        return ApiResponse<VenueDetailDto>.Ok(detail, "Lấy chi tiết cụm sân thành công");
    }

    public async Task<ApiResponse<List<TimeSlotStatusDto>>> GetVenueTimeSlotsAsync(int id, int subVenueId, DateOnly playDate)
    {
        var venue = await _unitOfWork.Venues.GetByIdAsync(id);
        if (venue == null)
        {
            return ApiResponse<List<TimeSlotStatusDto>>.Fail("Không tìm thấy cụm sân", 404);
        }

        if (subVenueId <= 0)
        {
            var venueDetail = await _unitOfWork.Venues.GetVenueDetailByIdAsync(id);
            subVenueId = venueDetail?.SubVenues.FirstOrDefault()?.Id ?? 0;
        }

        var allSlots = await _unitOfWork.Venues.GetAllTimeSlotsOrderedAsync();
        var bookedSlotIds = subVenueId > 0
            ? await _unitOfWork.Venues.GetBookedSlotIdsAsync(subVenueId, playDate)
            : new List<int>();

        var now = DateTime.Now;
        var isToday = playDate == DateOnly.FromDateTime(now);

        var slotStatuses = allSlots.Select(slot =>
        {
            var isBooked = bookedSlotIds.Contains(slot.Id);
            var isPast = false;
            if (isToday && TimeOnly.TryParse(slot.EndTime, out var endTime))
            {
                isPast = TimeOnly.FromDateTime(now) >= endTime;
            }

            var status = isBooked ? "Booked" : (isPast ? "Past" : "Available");

            return new TimeSlotStatusDto
            {
                SlotId = slot.Id,
                StartTime = slot.StartTime,
                EndTime = slot.EndTime,
                IsPeak = slot.IsPeak,
                Price = slot.IsPeak ? venue.PeakPrice : venue.BasePrice,
                IsBooked = isBooked || isPast,
                Status = status
            };
        }).ToList();

        return ApiResponse<List<TimeSlotStatusDto>>.Ok(slotStatuses, "Lấy danh sách khung giờ thành công");
    }
}
