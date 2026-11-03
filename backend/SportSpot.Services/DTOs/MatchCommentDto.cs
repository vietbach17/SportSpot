using System.ComponentModel.DataAnnotations;

namespace SportSpot.Services.DTOs;

public class CreateMatchCommentRequest
{
    [Required(ErrorMessage = "Nội dung bình luận không được để trống")]
    [MaxLength(1000)]
    public string Content { get; set; } = string.Empty;
}

public class MatchCommentDto
{
    public int Id { get; set; }
    public int MatchId { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string? UserAvatarUrl { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
