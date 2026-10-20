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

        return ApiResponse<VenueDetailDto>.Ok(detail, "Lấy chi tiết cụm sân thành công");
    }

    public async Task<ApiResponse<List<TimeSlotStatusDto>>> GetVenueTimeSlotsAsync(int id, int subVenueId, DateOnly playDate)
    {
        var venue = await _unitOfWork.Venues.GetByIdAsync(id);
        if (venue == null)
        {
            return ApiResponse<List<TimeSlotStatusDto>>.Fail("Không tìm thấy cụm sân", 404);
        }

        var allSlots = await _unitOfWork.Venues.GetAllTimeSlotsOrderedAsync();
        var bookedSlotIds = await _unitOfWork.Venues.GetBookedSlotIdsAsync(subVenueId, playDate);

        var slotStatuses = allSlots.Select(slot => new TimeSlotStatusDto
        {
            SlotId = slot.Id,
            StartTime = slot.StartTime,
            EndTime = slot.EndTime,
            IsPeak = slot.IsPeak,
            Price = slot.IsPeak ? venue.PeakPrice : venue.BasePrice,
            IsBooked = bookedSlotIds.Contains(slot.Id)
        }).ToList();

        return ApiResponse<List<TimeSlotStatusDto>>.Ok(slotStatuses, "Lấy danh sách khung giờ thành công");
    }
}
