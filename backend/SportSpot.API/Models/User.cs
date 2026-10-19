using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.API.Models;

[Table("Users")]
public class User
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(100)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string PhoneNumber { get; set; } = string.Empty;

    [MaxLength(150)]
    public string? Email { get; set; }

    [Required]
    [MaxLength(255)]
    public string PasswordHash { get; set; } = string.Empty;

    [Required]
    [MaxLength(30)]
    public string Role { get; set; } = "Player"; // 'Player', 'VenueStaff', 'Admin'

    public int WalletBalance { get; set; } = 0;

    [MaxLength(255)]
    public string? AvatarUrl { get; set; }

    public bool IsFindMatchEnabled { get; set; } = false;

    [MaxLength(255)]
    public string? FavoriteSports { get; set; } = "Cầu lông,Bóng đá mini";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
}
