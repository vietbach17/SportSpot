using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("Venues")]
public class Venue
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int SportId { get; set; }

    [ForeignKey(nameof(SportId))]
    public Sport? Sport { get; set; }

    [Required]
    [MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(255)]
    public string Address { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string District { get; set; } = string.Empty;

    [Column(TypeName = "decimal(10,7)")]
    public decimal Latitude { get; set; }

    [Column(TypeName = "decimal(10,7)")]
    public decimal Longitude { get; set; }

    public string? Description { get; set; }

    [Required]
    [MaxLength(20)]
    public string Hotline { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? ImageUrl { get; set; }

    public int BasePrice { get; set; }

    public int PeakPrice { get; set; }

    [Column(TypeName = "decimal(2,1)")]
    public decimal Rating { get; set; } = 5.0m;

    public string? Amenities { get; set; }

    public bool IsActive { get; set; } = true;

    public int? OwnerUserId { get; set; }
    public User? OwnerUser { get; set; }
    [MaxLength(20)] public string ApprovalStatus { get; set; } = "Approved";
    [MaxLength(1000)] public string? RejectionReason { get; set; }
    public DateTime? SubmittedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public int? ReviewedByUserId { get; set; }
    [ConcurrencyCheck] public int ReviewRevision { get; set; }
    public ICollection<VenueImage> Images { get; set; } = new List<VenueImage>();
    public ICollection<VenueModerationLog> ModerationHistory { get; set; } = new List<VenueModerationLog>();

    public ICollection<SubVenue> SubVenues { get; set; } = new List<SubVenue>();
    public ICollection<Service> Services { get; set; } = new List<Service>();
    public ICollection<Review> Reviews { get; set; } = new List<Review>();
}
