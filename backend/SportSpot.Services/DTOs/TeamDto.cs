using System.ComponentModel.DataAnnotations;

namespace SportSpot.Services.DTOs;

public class CreateTeamRequest
{
    [Required, StringLength(100, MinimumLength = 2)] public string Name { get; set; } = "";
    [Range(5, 11)] public int TeamSize { get; set; } = 7;
    [Required, StringLength(30)] public string SkillLevel { get; set; } = "Cơ bản";
}
public class CreateTeamChallengeRequest
{
    public int TeamId { get; set; }
    public int BookingId { get; set; }
    [StringLength(500)] public string Note { get; set; } = "";
}
public class ApplyTeamChallengeRequest
{
    public int TeamId { get; set; }
    [StringLength(500)] public string Message { get; set; } = "";
}
public record TeamDto(int Id, string Name, int CaptainUserId, string CaptainName, int TeamSize, string SkillLevel);
public record TeamApplicationDto(int Id, TeamDto Team, string Message, string Status);
public record TeamChallengeDto(int Id, TeamDto Team, int BookingId, string VenueName,
    string SubVenueName, string District, DateOnly PlayDate, List<string> TimeSlots,
    int OpponentCourtShare, string Note, string Status, bool IsHost,
    List<TeamApplicationDto> Requests, string? ContactPhone);
