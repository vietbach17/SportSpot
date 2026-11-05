using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SportSpot.Data.Entities;

[Table("VenueSlotConfigs")]
public class VenueSlotConfig
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int VenueId { get; set; }

    [ForeignKey(nameof(VenueId))]
    public Venue? Venue { get; set; }

    [Required]
    public int SlotId { get; set; }

    [ForeignKey(nameof(SlotId))]
    public TimeSlot? TimeSlot { get; set; }

    /// <summary>Slot này có mở bán/hoạt động tại cụm sân này không.</summary>
    public bool IsActive { get; set; } = true;

    /// <summary>Khung giờ cao điểm riêng của cụm sân này.</summary>
    public bool IsPeak { get; set; }

    /// <summary>Đơn giá tùy chỉnh cho slot này (VNĐ). Nếu null sẽ dùng BasePrice / PeakPrice của Venue.</summary>
    public int? CustomPrice { get; set; }
}

