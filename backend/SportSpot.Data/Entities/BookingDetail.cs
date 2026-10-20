using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("BookingDetails")]
public class BookingDetail
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int BookingId { get; set; }

    [ForeignKey(nameof(BookingId))]
    public Booking? Booking { get; set; }

    [Required]
    public int SubVenueId { get; set; }

    [ForeignKey(nameof(SubVenueId))]
    public SubVenue? SubVenue { get; set; }

    [Column(TypeName = "date")]
    public DateOnly PlayDate { get; set; }

    [Required]
    public int SlotId { get; set; }

    [ForeignKey(nameof(SlotId))]
    public TimeSlot? TimeSlot { get; set; }

    public int Price { get; set; }

    [Required]
    [MaxLength(30)]
    public string Status { get; set; } = "Upcoming"; // 'Upcoming', 'Completed', 'Cancelled'
}
