using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IVenueService
{
    Task<ApiResponse<List<VenueListDto>>> GetVenuesAsync(int? sportId, string? search, double? userLat, double? userLng, double? radiusKm);
    Task<ApiResponse<VenueDetailDto>> GetVenueDetailAsync(int id);
    Task<ApiResponse<List<TimeSlotStatusDto>>> GetVenueTimeSlotsAsync(int id, int subVenueId, DateOnly playDate);
    Task<ApiResponse<List<int>>> GetFavoriteVenueIdsAsync(int userId);
    Task<ApiResponse<FavoriteToggleResultDto>> ToggleFavoriteAsync(int venueId, int userId);
}
