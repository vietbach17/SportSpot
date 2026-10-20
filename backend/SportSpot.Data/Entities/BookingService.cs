using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("BookingServices")]
public class BookingService
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int BookingId { get; set; }

    [ForeignKey(nameof(BookingId))]
    public Booking? Booking { get; set; }

    [Required]
    public int ServiceId { get; set; }

    [ForeignKey(nameof(ServiceId))]
    public Service? Service { get; set; }

    public int Quantity { get; set; }

    public int Price { get; set; }
}
