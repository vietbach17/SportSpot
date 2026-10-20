using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("TimeSlots")]
public class TimeSlot
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(10)]
    public string StartTime { get; set; } = string.Empty;

    [Required]
    [MaxLength(10)]
    public string EndTime { get; set; } = string.Empty;

    public bool IsPeak { get; set; } = false;
}
