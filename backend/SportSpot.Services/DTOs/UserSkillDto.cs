namespace SportSpot.Services.DTOs;

public class UserSkillDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int SportId { get; set; }
    public string SportName { get; set; } = string.Empty;
    public string SkillLevel { get; set; } = string.Empty;
    public decimal RatingScore { get; set; }
    public bool IsVerified { get; set; }
    public string? VerifiedBy { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class UpdateUserSkillItemRequest
{
    public int? SportId { get; set; }
    public string SportName { get; set; } = string.Empty;
    public string SkillLevel { get; set; } = "Phong trào";
    public decimal RatingScore { get; set; } = 3.5m;
}

public class UpdateUserSkillsRequest
{
    public List<UpdateUserSkillItemRequest> Skills { get; set; } = new();
}
