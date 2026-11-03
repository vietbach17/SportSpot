using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;

    public ReviewsController(IReviewService reviewService)
    {
        _reviewService = reviewService;
    }

    /// <summary>
    /// GET /api/reviews?venueId={venueId}: Lấy danh sách đánh giá kèm điểm trung bình và phân bố sao của sân.
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<VenueReviewSummaryDto>>> GetVenueReviews([FromQuery] int venueId)
    {
        var result = await _reviewService.GetVenueReviewsAsync(venueId);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// GET /api/venues/{venueId}/reviews: Alias route thuận tiện cho RESTful.
    /// </summary>
    [HttpGet("~/api/venues/{venueId}/reviews")]
    public async Task<ActionResult<ApiResponse<VenueReviewSummaryDto>>> GetReviewsByVenue(int venueId)
    {
        var result = await _reviewService.GetVenueReviewsAsync(venueId);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// POST /api/reviews: Khách hàng gửi đánh giá và nhận xét cho cụm sân.
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<ApiResponse<ReviewDto>>> CreateReview([FromBody] CreateReviewRequest request)
    {
        var authUserId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var uid) ? uid : 0;
        var userId = authUserId > 0 ? authUserId : 1; // Fallback dev user
        var result = await _reviewService.CreateReviewAsync(userId, request);
        return StatusCode(result.StatusCode, result);
    }
}
