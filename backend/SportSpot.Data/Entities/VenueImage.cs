using System.ComponentModel.DataAnnotations;

namespace SportSpot.Data.Entities;

public class VenueImage
{
    public int Id { get; set; }
    public int UploadedByUserId { get; set; }
    public User? UploadedByUser { get; set; }
    public int? VenueId { get; set; }
    public Venue? Venue { get; set; }
    [MaxLength(1000)] public string Url { get; set; } = "";
    [MaxLength(255)] public string PublicId { get; set; } = "";
    public int Position { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class VenueModerationLog
{
    public int Id { get; set; }
    public int VenueId { get; set; }
    public Venue? Venue { get; set; }
    public int AdminUserId { get; set; }
    public User? AdminUser { get; set; }
    [MaxLength(20)] public string Decision { get; set; } = "";
    [MaxLength(1000)] public string Reason { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
