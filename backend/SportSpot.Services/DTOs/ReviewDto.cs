using System.ComponentModel.DataAnnotations;

namespace SportSpot.Services.DTOs;

public class CreateReviewRequest
{
    [Required]
    public int VenueId { get; set; }

    [Range(1, 5, ErrorMessage = "Điểm đánh giá phải từ 1 đến 5 sao")]
    public int Rating { get; set; } = 5;

    [Required(ErrorMessage = "Nội dung nhận xét không được để trống")]
    [MaxLength(1000)]
    public string Comment { get; set; } = string.Empty;
}

public class ReviewDto
{
    public int Id { get; set; }
    public int VenueId { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string? UserAvatarUrl { get; set; }
    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class VenueReviewSummaryDto
{
    public int VenueId { get; set; }
    public decimal AverageRating { get; set; }
    public int TotalReviews { get; set; }
    public Dictionary<int, int> RatingBreakdown { get; set; } = new();
    public List<ReviewDto> Reviews { get; set; } = new();
}
