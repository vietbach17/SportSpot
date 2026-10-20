namespace SportSpot.Services.DTOs;

public class OpenMatchDto
{
    public int MatchId { get; set; }
    public int BookingId { get; set; }
    public string BookingCode { get; set; } = string.Empty;
    public string VenueName { get; set; } = string.Empty;
    public string SubVenueName { get; set; } = string.Empty;
    public string SportName { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public DateOnly PlayDate { get; set; }
    public List<string> TimeSlots { get; set; } = new();
    public int HostUserId { get; set; }
    public string HostName { get; set; } = string.Empty;
    public int TotalExpectedPlayers { get; set; }
    public int NeededPlayers { get; set; }
    public int CurrentJoinedPlayers { get; set; }
    public int CostPerPerson { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class JoinMatchRequest
{
    public int UserId { get; set; }
    public string PaymentGateway { get; set; } = "MockPayment";
}
