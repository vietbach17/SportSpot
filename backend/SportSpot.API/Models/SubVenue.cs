using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.API.Models;

[Table("SubVenues")]
public class SubVenue
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int VenueId { get; set; }

    [ForeignKey(nameof(VenueId))]
    public Venue? Venue { get; set; }

    [Required]
    [MaxLength(50)]
    public string Name { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
}
