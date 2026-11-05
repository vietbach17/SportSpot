using System.ComponentModel.DataAnnotations;

namespace SportSpot.Services.DTOs;

public record ManagedVenueDto(int Id, string Name, int BasePrice, int PeakPrice);
public record ScheduleCourtDto(int Id, string Name, bool IsActive);
public record ScheduleSlotDto(int Id, string StartTime, string EndTime, bool IsPeak);
public record ScheduleBookingDto(int Id, string Code, int SubVenueId, DateOnly PlayDate,
    List<int> SlotIds, string Type, string Status, string CustomerName, string CustomerPhone,
    string Note, int TotalPrice, int CollectedAmount, int RemainingBalance);
public record OwnerScheduleDto(ManagedVenueDto Venue, List<ScheduleCourtDto> Courts,
    List<ScheduleSlotDto> Slots, List<ScheduleBookingDto> Bookings);
public class CreateManagedBookingRequest
{
    public int SubVenueId { get; set; }
    public DateOnly PlayDate { get; set; }
    [Required, MinLength(1), MaxLength(13)] public List<int> SlotIds { get; set; } = new();
    public bool Maintenance { get; set; }
    [StringLength(100)] public string CustomerName { get; set; } = "";
    [StringLength(20)] public string CustomerPhone { get; set; } = "";
    [StringLength(500)] public string Note { get; set; } = "";
    [Range(0, 100000000)] public int CollectedAmount { get; set; }
}
public class UpdateVenuePricesRequest
{
    [Range(1, 10000000)] public int BasePrice { get; set; }
    [Range(1, 10000000)] public int PeakPrice { get; set; }
}
public class CollectCashRequest { [Range(1, 100000000)] public int Amount { get; set; } }
public class CancelManagedBookingRequest { public bool ConfirmCashRefund { get; set; } }
