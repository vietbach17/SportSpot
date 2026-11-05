using SportSpot.Data.Entities;
using SportSpot.Services.DTOs;

namespace SportSpot.Services.Helpers;

/// <summary>
/// Resolves per-venue active operating slots, peak flags, and custom slot pricing.
/// Legacy/unconfigured venues (with 0 rows in VenueSlotConfigs) automatically fall back
/// to the classic 13 slots (Id &lt;= 13) plus any runtime-created test slots (Id &gt;= 20).
/// </summary>
public static class VenueSlotHelper
{
    public record ResolvedVenueSlot(
        int SlotId,
        string StartTime,
        string EndTime,
        bool IsActive,
        bool IsPeak,
        int? CustomPrice,
        int EffectivePrice);

    public static List<ResolvedVenueSlot> ResolveActiveSlots(
        Venue venue,
        IEnumerable<TimeSlot> allSlots,
        IEnumerable<VenueSlotConfig>? configs = null)
    {
        var cfgList = (configs ?? venue.SlotConfigs ?? Array.Empty<VenueSlotConfig>()).ToList();
        var cfgMap = cfgList.ToDictionary(c => c.SlotId);
        var hasCustomConfig = cfgMap.Count > 0;

        var ordered = allSlots
            .OrderBy(s => s.StartTime)
            .ThenBy(s => s.Id)
            .ToList();

        var result = new List<ResolvedVenueSlot>();
        foreach (var slot in ordered)
        {
            bool isActive;
            bool isPeak;
            int? customPrice = null;

            if (cfgMap.TryGetValue(slot.Id, out var cfg))
            {
                isActive = cfg.IsActive;
                isPeak = cfg.IsPeak;
                customPrice = cfg.CustomPrice;
            }
            else if (hasCustomConfig)
            {
                // When a venue explicitly configures slots, unmentioned seeded slots (1..19) are inactive,
                // while dynamic test slots (Id >= 20) remain active.
                isActive = slot.Id >= 20;
                isPeak = slot.IsPeak;
            }
            else
            {
                // Legacy default: classic 13 slots (Id <= 13) + any dynamic test slots (Id >= 20)
                isActive = slot.Id <= 13 || slot.Id >= 20;
                isPeak = slot.IsPeak;
            }

            if (!isActive) continue;

            var effectivePrice = customPrice is > 0
                ? customPrice.Value
                : (isPeak ? venue.PeakPrice : venue.BasePrice);

            result.Add(new ResolvedVenueSlot(
                slot.Id,
                slot.StartTime,
                slot.EndTime,
                true,
                isPeak,
                customPrice,
                effectivePrice));
        }

        return result;
    }

    public static List<VenueSlotConfigItemDto> BuildFullSlotConfigDtos(
        Venue venue,
        IEnumerable<TimeSlot> allSlots,
        IEnumerable<VenueSlotConfig>? configs = null)
    {
        var cfgList = (configs ?? venue.SlotConfigs ?? Array.Empty<VenueSlotConfig>()).ToList();
        var cfgMap = cfgList.ToDictionary(c => c.SlotId);
        var hasCustomConfig = cfgMap.Count > 0;

        return allSlots
            .Where(s => s.Id <= 19)
            .OrderBy(s => s.StartTime)
            .ThenBy(s => s.Id)
            .Select(slot =>
            {
                bool isActive;
                bool isPeak;
                int? customPrice = null;

                if (cfgMap.TryGetValue(slot.Id, out var cfg))
                {
                    isActive = cfg.IsActive;
                    isPeak = cfg.IsPeak;
                    customPrice = cfg.CustomPrice;
                }
                else if (hasCustomConfig)
                {
                    isActive = false;
                    isPeak = slot.IsPeak;
                }
                else
                {
                    isActive = slot.Id <= 13;
                    isPeak = slot.IsPeak;
                }

                var effectivePrice = customPrice is > 0
                    ? customPrice.Value
                    : (isPeak ? venue.PeakPrice : venue.BasePrice);

                return new VenueSlotConfigItemDto(
                    slot.Id,
                    slot.StartTime,
                    slot.EndTime,
                    isActive,
                    isPeak,
                    customPrice,
                    effectivePrice);
            })
            .ToList();
    }

    public static string SummarizeOperatingHours(IEnumerable<VenueSlotConfigItemDto> items)
    {
        var active = items.Where(i => i.IsActive).OrderBy(i => i.StartTime).ToList();
        if (active.Count == 0) return "Chưa mở khung giờ";
        return $"{active.First().StartTime} - {active.Last().EndTime} ({active.Count} slot/ngày)";
    }
}

