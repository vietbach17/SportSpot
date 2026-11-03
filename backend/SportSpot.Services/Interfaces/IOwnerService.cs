using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IOwnerService
{
    Task<ApiResponse<OwnerDashboardDto>> GetOwnerDashboardAsync(int venueId);
    Task<ApiResponse<bool>> ToggleSubVenueStatusAsync(int subVenueId, bool? isActive);
}
