namespace SportSpot.Services.DTOs;

public class SportDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? IconUrl { get; set; }
    public int VenueCount { get; set; }
}
