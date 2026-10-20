using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("Transactions")]
public class Transaction
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int BookingId { get; set; }

    [ForeignKey(nameof(BookingId))]
    public Booking? Booking { get; set; }

    [Required]
    public int UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    public int Amount { get; set; }

    [Required]
    [MaxLength(30)]
    public string PaymentGateway { get; set; } = "MockPayment"; // 'VNPay', 'MoMo', 'MockPayment'

    [Required]
    [MaxLength(100)]
    public string TransactionCode { get; set; } = string.Empty;

    [Required]
    [MaxLength(30)]
    public string Status { get; set; } = "Holding"; // 'Holding', 'Settled', 'Refunded'

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
