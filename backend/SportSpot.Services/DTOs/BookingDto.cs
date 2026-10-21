namespace SportSpot.Services.DTOs;

public class CreateBookingRequest
{
    public int UserId { get; set; }
    public int SubVenueId { get; set; }
    public DateOnly PlayDate { get; set; }
    public List<int> SlotIds { get; set; } = new();
    public List<BookingServiceItemRequest> Services { get; set; } = new();
    public bool IsOpenMatch { get; set; } = false;
    public int? TotalExpectedPlayers { get; set; }
    public int? NeededPlayers { get; set; }
    public string SkillLevel { get; set; } = "Cơ bản";
    public int DepositPercentage { get; set; } = 100; // 30% hoặc 100%
    public string PaymentGateway { get; set; } = "MockPayment";
}

public class BookingServiceItemRequest
{
    public int ServiceId { get; set; }
    public int Quantity { get; set; }
}

public class BookingResponseDto
{
    public int BookingId { get; set; }
    public string BookingCode { get; set; } = string.Empty;
    public string VenueName { get; set; } = string.Empty;
    public string SubVenueName { get; set; } = string.Empty;
    public string SportName { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public DateOnly PlayDate { get; set; }
    public List<string> TimeSlots { get; set; } = new();
    public int CourtPrice { get; set; }
    public int ServicesPrice { get; set; }
    public int TotalPrice { get; set; }
    public int DepositAmount { get; set; }
    public int RemainingBalance { get; set; }
    public string Status { get; set; } = string.Empty;
    public string QrPayload { get; set; } = string.Empty;
    public bool IsCheckedIn { get; set; }
}

public class CheckInRequest
{
    public string QrPayload { get; set; } = string.Empty;
}
