using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("FavoriteVenues")]
public class FavoriteVenue
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    [Required]
    public int VenueId { get; set; }

    [ForeignKey(nameof(VenueId))]
    public Venue? Venue { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
