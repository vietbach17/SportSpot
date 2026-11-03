using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class ReviewService : IReviewService
{
    private readonly SportSpotDbContext _context;

    public ReviewService(SportSpotDbContext context)
    {
        _context = context;
    }

    public async Task<ApiResponse<VenueReviewSummaryDto>> GetVenueReviewsAsync(int venueId)
    {
        var venue = await _context.Venues.FirstOrDefaultAsync(v => v.Id == venueId);
        if (venue == null)
        {
            return ApiResponse<VenueReviewSummaryDto>.Fail("Không tìm thấy cụm sân", 404);
        }

        var reviews = await _context.Reviews
            .Include(r => r.User)
            .Where(r => r.VenueId == venueId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        var breakdown = new Dictionary<int, int>
        {
            [5] = reviews.Count(r => r.Rating == 5),
            [4] = reviews.Count(r => r.Rating == 4),
            [3] = reviews.Count(r => r.Rating == 3),
            [2] = reviews.Count(r => r.Rating == 2),
            [1] = reviews.Count(r => r.Rating == 1)
        };

        var avg = reviews.Count > 0
            ? Math.Round((decimal)reviews.Average(r => r.Rating), 1)
            : venue.Rating;

        var reviewDtos = reviews.Select(r => new ReviewDto
        {
            Id = r.Id,
            VenueId = r.VenueId,
            UserId = r.UserId,
            UserName = r.User?.FullName ?? "Khách hàng SportSpot",
            UserAvatarUrl = r.User?.AvatarUrl,
            Rating = r.Rating,
            Comment = r.Comment,
            CreatedAt = r.CreatedAt
        }).ToList();

        var summary = new VenueReviewSummaryDto
        {
            VenueId = venueId,
            AverageRating = avg,
            TotalReviews = reviews.Count,
            RatingBreakdown = breakdown,
            Reviews = reviewDtos
        };

        return ApiResponse<VenueReviewSummaryDto>.Ok(summary);
    }

    public async Task<ApiResponse<ReviewDto>> CreateReviewAsync(int userId, CreateReviewRequest request)
    {
        if (request.Rating < 1 || request.Rating > 5)
        {
            return ApiResponse<ReviewDto>.Fail("Điểm đánh giá phải từ 1 đến 5 sao", 400);
        }

        if (string.IsNullOrWhiteSpace(request.Comment))
        {
            return ApiResponse<ReviewDto>.Fail("Nội dung nhận xét không được để trống", 400);
        }

        var venue = await _context.Venues.FirstOrDefaultAsync(v => v.Id == request.VenueId);
        if (venue == null)
        {
            return ApiResponse<ReviewDto>.Fail("Không tìm thấy cụm sân", 404);
        }

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
        {
            return ApiResponse<ReviewDto>.Fail("Không tìm thấy người dùng", 404);
        }

        var existingReview = await _context.Reviews
            .FirstOrDefaultAsync(r => r.VenueId == request.VenueId && r.UserId == userId);

        Review review;
        if (existingReview != null)
        {
            existingReview.Rating = request.Rating;
            existingReview.Comment = request.Comment.Trim();
            existingReview.CreatedAt = DateTime.UtcNow;
            review = existingReview;
        }
        else
        {
            review = new Review
            {
                VenueId = request.VenueId,
                UserId = userId,
                Rating = request.Rating,
                Comment = request.Comment.Trim(),
                CreatedAt = DateTime.UtcNow
            };
            _context.Reviews.Add(review);
        }

        await _context.SaveChangesAsync();

        // Tự động tính lại điểm đánh giá trung bình của sân
        var allRatings = await _context.Reviews
            .Where(r => r.VenueId == request.VenueId)
            .Select(r => r.Rating)
            .ToListAsync();

        if (allRatings.Count > 0)
        {
            venue.Rating = Math.Round((decimal)allRatings.Average(), 1);
            await _context.SaveChangesAsync();
        }

        var dto = new ReviewDto
        {
            Id = review.Id,
            VenueId = review.VenueId,
            UserId = review.UserId,
            UserName = user.FullName,
            UserAvatarUrl = user.AvatarUrl,
            Rating = review.Rating,
            Comment = review.Comment,
            CreatedAt = review.CreatedAt
        };

        return ApiResponse<ReviewDto>.Ok(dto, "Gửi đánh giá thành công! Cảm ơn bạn đã phản hồi.");
    }
}
