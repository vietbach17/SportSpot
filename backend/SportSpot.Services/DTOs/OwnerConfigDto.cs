using System.ComponentModel.DataAnnotations;

namespace SportSpot.Services.DTOs;

public record OwnerVenueConfigDto(
    int VenueId,
    string Name,
    int SportId,
    string SportName,
    string Address,
    string District,
    string Hotline,
    decimal Latitude,
    decimal Longitude,
    string Description,
    string Amenities,
    bool IsActive,
    string ApprovalStatus,
    int BasePrice,
    int PeakPrice,
    int MaxSlotsPerBooking,
    int MinDepositPercent,
    int ActiveSlotCount,
    string OperatingHoursSummary,
    List<UploadedVenueImageDto> Images,
    List<SubVenueDto> SubVenues,
    List<ServiceDto> Services,
    List<VenueSlotConfigItemDto> SlotConfigs,
    List<VenueStaffMemberDto> StaffMembers);

public record VenueStaffMemberDto(
    int UserId,
    string FullName,
    string PhoneNumber,
    string Email,
    bool IsActive);

public class UpdateOwnerVenueInfoRequest
{
    [Required, StringLength(150, MinimumLength = 3)] public string Name { get; set; } = "";
    public int SportId { get; set; }
    [Required, StringLength(255, MinimumLength = 5)] public string Address { get; set; } = "";
    [Required, StringLength(100)] public string District { get; set; } = "";
    [Required, RegularExpression(@"^\+?[0-9]{9,15}$")] public string Hotline { get; set; } = "";
    [Range(-90, 90)] public decimal Latitude { get; set; }
    [Range(-180, 180)] public decimal Longitude { get; set; }
    [StringLength(3000)] public string Description { get; set; } = "";
    [StringLength(1000)] public string Amenities { get; set; } = "";
    public bool IsActive { get; set; } = true;
    public List<int>? ImageIds { get; set; }
}

public class UpdateOwnerSlotConfigRequest
{
    [Range(1000, 10000000)] public int BasePrice { get; set; }
    [Range(1000, 10000000)] public int PeakPrice { get; set; }
    [Range(1, 12)] public int MaxSlotsPerBooking { get; set; } = 3;
    public int MinDepositPercent { get; set; } = 30;
    [Required, MinLength(1)] public List<SlotConfigItemInput> Slots { get; set; } = new();
}

public class UpsertSubVenueRequest
{
    [Required, StringLength(100, MinimumLength = 1)] public string Name { get; set; } = "";
    public bool IsActive { get; set; } = true;
}

public class UpsertVenueServiceRequest
{
    [Required, StringLength(100, MinimumLength = 2)] public string Name { get; set; } = "";
    [Required, RegularExpression(@"^(Rental|Sale)$")] public string Type { get; set; } = "Sale";
    [Range(1000, 10000000)] public int Price { get; set; }
    [Range(0, 100000)] public int StockQuantity { get; set; } = 50;
}

public class AssignVenueStaffRequest
{
    /// <summary>Số điện thoại hoặc Email của tài khoản cần gắn làm Lễ tân (VenueStaff).</summary>
    [Required, StringLength(150)] public string Identifier { get; set; } = "";
}

