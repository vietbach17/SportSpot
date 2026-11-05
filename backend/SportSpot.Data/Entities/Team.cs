using System.ComponentModel.DataAnnotations;

namespace SportSpot.Data.Entities;

public class Team
{
    public int Id { get; set; }
    [MaxLength(100)] public string Name { get; set; } = "";
    public int CaptainUserId { get; set; }
    public User? CaptainUser { get; set; }
    public int TeamSize { get; set; }
    [MaxLength(30)] public string SkillLevel { get; set; } = "Cơ bản";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class TeamChallenge
{
    public int Id { get; set; }
    public int TeamId { get; set; }
    public Team? Team { get; set; }
    public int BookingId { get; set; }
    public Booking? Booking { get; set; }
    [MaxLength(500)] public string Note { get; set; } = "";
    [MaxLength(20)] public string Status { get; set; } = "Open";
    public int Revision { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ICollection<TeamChallengeRequest> Requests { get; set; } = new List<TeamChallengeRequest>();
}

public class TeamChallengeRequest
{
    public int Id { get; set; }
    public int TeamChallengeId { get; set; }
    public TeamChallenge? TeamChallenge { get; set; }
    public int TeamId { get; set; }
    public Team? Team { get; set; }
    [MaxLength(500)] public string Message { get; set; } = "";
    [MaxLength(20)] public string Status { get; set; } = "Pending";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
