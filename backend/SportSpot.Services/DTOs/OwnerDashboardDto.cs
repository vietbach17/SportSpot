namespace SportSpot.Services.DTOs;

public class DailyRevenueDto
{
    public string Date { get; set; } = string.Empty;
    public string DayOfWeek { get; set; } = string.Empty;
    public int Revenue { get; set; }
    public int BookingCount { get; set; }
}

public class OwnerBookingDto
{
    public int BookingId { get; set; }
    public string BookingCode { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerPhone { get; set; } = string.Empty;
    public string SubVenueName { get; set; } = string.Empty;
    public string PlayDate { get; set; } = string.Empty;
    public List<string> TimeSlots { get; set; } = new();
    public int TotalPrice { get; set; }
    public int DepositAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string EscrowStatus { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class SubVenueManagementDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public int TotalSlotsToday { get; set; }
    public int BookedSlotsToday { get; set; }
}

public class OwnerDashboardDto
{
    public int VenueId { get; set; }
    public string VenueName { get; set; } = string.Empty;
    public string VenueAddress { get; set; } = string.Empty;
    public string SportName { get; set; } = string.Empty;
    public int TotalBookings { get; set; }
    public int TotalRevenue { get; set; }
    public int EscrowHoldingAmount { get; set; }
    public int OccupancyRatePercentage { get; set; }
    public int ActiveSubVenuesCount { get; set; }
    public int TotalSubVenuesCount { get; set; }
    public List<DailyRevenueDto> DailyRevenues { get; set; } = new();
    public List<OwnerBookingDto> RecentBookings { get; set; } = new();
    public List<SubVenueManagementDto> SubVenues { get; set; } = new();
}

public class ToggleSubVenueRequest
{
    public bool? IsActive { get; set; }
}
