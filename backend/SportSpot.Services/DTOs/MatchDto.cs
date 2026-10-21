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
    public int VenueId { get; set; }
    public int SportId { get; set; }
    public string District { get; set; } = string.Empty;
    public string SkillLevel { get; set; } = string.Empty;
    public int RemainingBalanceForHost { get; set; }
    public List<MatchMemberDto> Members { get; set; } = new();
}

public record MatchMemberDto(int MemberId, int? UserId, string Name, string? AvatarUrl, string MemberType);

public class CreateMatchRequest
{
    public int BookingId { get; set; }
    public int TotalExpectedPlayers { get; set; }
    public int NeededPlayers { get; set; }
    public string SkillLevel { get; set; } = "Cơ bản";
}

public class JoinMatchRequest
{
    public int UserId { get; set; }
    public string PaymentGateway { get; set; } = "MockPayment";
}
