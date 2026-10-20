using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("Bookings")]
public class Booking
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(20)]
    public string BookingCode { get; set; } = string.Empty;

    [Required]
    public int UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    [Required]
    public int SubVenueId { get; set; }

    [ForeignKey(nameof(SubVenueId))]
    public SubVenue? SubVenue { get; set; }

    [Column(TypeName = "date")]
    public DateOnly PlayDate { get; set; }

    public int CourtPrice { get; set; }

    public int ServicesPrice { get; set; } = 0;

    public int TotalPrice { get; set; }

    public int DepositAmount { get; set; }

    public int RemainingBalance { get; set; }

    [Required]
    [MaxLength(30)]
    public string BookingType { get; set; } = "Standard"; // 'Standard', 'OpenMatch'

    [Required]
    [MaxLength(30)]
    public string Status { get; set; } = "Upcoming"; // 'PendingPayment', 'Upcoming', 'Completed', 'Cancelled'

    public bool IsCheckedIn { get; set; } = false;

    public DateTime? CheckedInAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<BookingDetail> BookingDetails { get; set; } = new List<BookingDetail>();
    public ICollection<BookingService> BookingServices { get; set; } = new List<BookingService>();
    public OpenMatch? OpenMatch { get; set; }
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}
