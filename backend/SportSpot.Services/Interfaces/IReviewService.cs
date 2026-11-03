using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IReviewService
{
    Task<ApiResponse<VenueReviewSummaryDto>> GetVenueReviewsAsync(int venueId);
    Task<ApiResponse<ReviewDto>> CreateReviewAsync(int userId, CreateReviewRequest request);
}
