using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("MatchComments")]
public class MatchComment
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int MatchId { get; set; }

    [ForeignKey(nameof(MatchId))]
    public OpenMatch? Match { get; set; }

    [Required]
    public int UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    [Required]
    [MaxLength(1000)]
    public string Content { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
