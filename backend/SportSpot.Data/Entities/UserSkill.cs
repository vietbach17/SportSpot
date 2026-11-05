using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("UserSkills")]
public class UserSkill
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    [Required]
    public int SportId { get; set; }

    [ForeignKey(nameof(SportId))]
    public Sport? Sport { get; set; }

    [Required]
    [MaxLength(50)]
    public string SkillLevel { get; set; } = "Phong trào";

    [Column(TypeName = "numeric(3,1)")]
    public decimal RatingScore { get; set; } = 3.5m;

    public bool IsVerified { get; set; } = false;

    [MaxLength(100)]
    public string? VerifiedBy { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
