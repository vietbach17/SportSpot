using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("OpenMatches")]
public class OpenMatch
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int BookingId { get; set; }

    [ForeignKey(nameof(BookingId))]
    public Booking? Booking { get; set; }

    [Required]
    public int HostUserId { get; set; }

    [ForeignKey(nameof(HostUserId))]
    public User? HostUser { get; set; }

    public int TotalExpectedPlayers { get; set; }

    public int NeededPlayers { get; set; }

    public int CurrentJoinedPlayers { get; set; } = 0;

    public int CostPerPerson { get; set; }

    [MaxLength(30)]
    public string SkillLevel { get; set; } = "Cơ bản";

    [ConcurrencyCheck]
    public int Revision { get; set; }

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = "Open"; // 'Open', 'Full', 'Stopped', 'Cancelled'

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<MatchMember> MatchMembers { get; set; } = new List<MatchMember>();
}
