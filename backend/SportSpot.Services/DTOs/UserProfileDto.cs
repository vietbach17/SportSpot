namespace SportSpot.Services.DTOs;

public class UserProfileDto
{
    public int UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Role { get; set; } = string.Empty;
    public int WalletBalance { get; set; }
    public string? AvatarUrl { get; set; }
    public bool IsFindMatchEnabled { get; set; }
    public string? FavoriteSports { get; set; }
}

public class UpdateProfileRequest
{
    public string? FullName { get; set; }
    public string? Email { get; set; }
    public bool? IsFindMatchEnabled { get; set; }
    public string? FavoriteSports { get; set; }
    public string? AvatarUrl { get; set; }
}
