using SportSpot.Data.Entities;

namespace SportSpot.Services.Helpers;

public static class MatchRules
{
    public static bool ValidPlayers(int total, int needed) => total > 1 && needed > 0 && needed < total;
    public static int SplitCost(int courtPrice, int total) =>
        checked((int)Math.Round((decimal)courtPrice / total, MidpointRounding.AwayFromZero));

    // Booking dates and times are local to the Vietnamese venue (UTC+7).
    public static DateTime VietnamNow => DateTime.UtcNow.AddHours(7);
    public static bool IsUpcoming(Booking booking)
    {
        var first = booking.BookingDetails.Select(d => d.TimeSlot?.StartTime)
            .Where(t => t != null).OrderBy(t => t).FirstOrDefault();
        return booking.Status == "Upcoming" && !booking.IsCheckedIn &&
            TimeOnly.TryParse(first, out var time) &&
            booking.PlayDate.ToDateTime(time) > VietnamNow;
    }
}
