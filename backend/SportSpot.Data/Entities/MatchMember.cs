using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("MatchMembers")]
public class MatchMember
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int MatchId { get; set; }

    [ForeignKey(nameof(MatchId))]
    public OpenMatch? OpenMatch { get; set; }

    public int? UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    [Required]
    [MaxLength(20)]
    public string MemberType { get; set; } = "AppUser"; // 'AppUser' hoặc 'WalkInAtDesk'

    public int PaidAmount { get; set; }

    [Required]
    [MaxLength(20)]
    public string PaymentStatus { get; set; } = "Paid";

    [MaxLength(255)]
    public string? TicketQrPayload { get; set; }

    public bool IsCheckedIn { get; set; } = false;

    public DateTime? CheckedInAt { get; set; }

    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
}
