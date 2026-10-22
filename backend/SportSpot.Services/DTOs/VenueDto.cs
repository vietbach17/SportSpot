namespace SportSpot.Services.DTOs;

public class VenueListDto
{
    public int Id { get; set; }
    public int SportId { get; set; }
    public string SportName { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string District { get; set; } = string.Empty;
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public string Hotline { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public int BasePrice { get; set; }
    public int PeakPrice { get; set; }
    public decimal Rating { get; set; }
    public string? Amenities { get; set; }
    public double? DistanceKm { get; set; }
}

public class VenueDetailDto : VenueListDto
{
    public string? Description { get; set; }
    public List<SubVenueDto> SubVenues { get; set; } = new();
    public List<ServiceDto> Services { get; set; } = new();
}

public class SubVenueDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

public class ServiceDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty; // 'Rental' / 'Sale'
    public int Price { get; set; }
    public int StockQuantity { get; set; }
}

public class TimeSlotStatusDto
{
    public int SlotId { get; set; }
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty;
    public bool IsPeak { get; set; }
    public int Price { get; set; }
    public bool IsBooked { get; set; }
    public string Status { get; set; } = "Available"; // "Available", "Booked", "Past", "Holding"
}
