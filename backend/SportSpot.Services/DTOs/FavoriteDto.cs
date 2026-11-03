namespace SportSpot.Services.DTOs;

public class FavoriteToggleResultDto
{
    public int VenueId { get; set; }
    public bool IsFavorite { get; set; }
    public string Message { get; set; } = string.Empty;
}
