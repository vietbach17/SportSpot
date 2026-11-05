using System.ComponentModel.DataAnnotations;

namespace SportSpot.Services.DTOs;

public class SlotConfigItemInput
{
    public int SlotId { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsPeak { get; set; }
    [Range(1000, 50000000)]
    public int? CustomPrice { get; set; }
}

public class InitialServiceInput
{
    [Required, StringLength(100, MinimumLength = 2)] public string Name { get; set; } = "";
    [Required, RegularExpression(@"^(Rental|Sale)$")] public string Type { get; set; } = "Sale";
    [Range(1000, 10000000)] public int Price { get; set; }
    [Range(0, 100000)] public int StockQuantity { get; set; } = 50;
}

public class SubmitVenueRequest
{
    [Required, StringLength(150, MinimumLength = 3)] public string Name { get; set; } = "";
    public int SportId { get; set; }
    [Required, StringLength(255, MinimumLength = 5)] public string Address { get; set; } = "";
    [Required, StringLength(100)] public string District { get; set; } = "";
    [Required, RegularExpression(@"^\+?[0-9]{9,15}$")] public string Hotline { get; set; } = "";
    [Range(-90, 90)] public decimal Latitude { get; set; }
    [Range(-180, 180)] public decimal Longitude { get; set; }
    [Range(1000, 10000000)] public int BasePrice { get; set; }
    [Range(1000, 10000000)] public int PeakPrice { get; set; }
    [Range(1, 12)] public int MaxSlotsPerBooking { get; set; } = 3;
    public int MinDepositPercent { get; set; } = 30;
    [StringLength(3000)] public string Description { get; set; } = "";
    [StringLength(1000)] public string Amenities { get; set; } = "";
    [Required, MinLength(1), MaxLength(20)] public List<string> CourtNames { get; set; } = new();
    [Required, MinLength(1), MaxLength(8)] public List<int> ImageIds { get; set; } = new();
    public List<SlotConfigItemInput>? SlotConfigs { get; set; }
    public List<InitialServiceInput>? Services { get; set; }
    public int Revision { get; set; }
}

public class ReviewVenueRequest
{
    public bool Approve { get; set; }
    [StringLength(1000)] public string Reason { get; set; } = "";
    public int Revision { get; set; }
}

public class SetActiveRequest { public bool IsActive { get; set; } }

public class AssignRoleVenueRequest
{
    [Required] public string Role { get; set; } = "Player";
    public int? VenueId { get; set; }
}

public record UploadedVenueImageDto(int Id, string Url);
public record ModerationLogDto(string Decision, string Reason, string AdminName, DateTime CreatedAt);
public record VenueSlotConfigItemDto(
    int SlotId,
    string StartTime,
    string EndTime,
    bool IsActive,
    bool IsPeak,
    int? CustomPrice,
    int EffectivePrice);

public record VenueApplicationDto(
    int Id,
    string Name,
    int SportId,
    string SportName,
    string Address,
    string District,
    string Hotline,
    decimal Latitude,
    decimal Longitude,
    int BasePrice,
    int PeakPrice,
    int MaxSlotsPerBooking,
    int MinDepositPercent,
    int ActiveSlotCount,
    string OperatingHoursSummary,
    string Description,
    string Amenities,
    string Status,
    bool IsActive,
    int? OwnerUserId,
    string OwnerName,
    string OwnerPhone,
    DateTime? SubmittedAt,
    string? RejectionReason,
    int Revision,
    List<string> CourtNames,
    List<UploadedVenueImageDto> Images,
    List<VenueSlotConfigItemDto> SlotConfigs,
    List<ServiceDto> Services,
    List<ModerationLogDto> History);

public record AdminUserDto(
    int Id,
    string Name,
    string Phone,
    string Email,
    string Role,
    bool IsActive,
    DateTime CreatedAt,
    int VenueCount,
    int? StaffVenueId,
    string? StaffVenueName);

public record AdminDayDto(string Date, int BookingCount, long BookingValue);
public record AdminOverviewDto(
    int TotalUsers,
    int ActiveUsers,
    int TotalVenues,
    int PendingVenues,
    int ActiveVenues,
    int UpcomingBookings,
    long BookingValue30Days,
    long EscrowHolding,
    List<AdminDayDto> Activity,
    List<VenueApplicationDto> PendingApplications);
