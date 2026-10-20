using SportSpot.Data.Entities;

namespace SportSpot.Data.Repositories.Interfaces;

public interface IBookingRepository : IGenericRepository<Booking>
{
    Task<SubVenue?> GetActiveSubVenueWithVenueAsync(int subVenueId);
    Task<List<TimeSlot>> GetTimeSlotsByIdsAsync(List<int> slotIds);
    Task<List<BookingDetail>> GetConflictedSlotsAsync(int subVenueId, DateOnly playDate, List<int> slotIds);
    Task<Dictionary<int, Service>> GetVenueServicesDictionaryAsync(int venueId, List<int> serviceIds);
    Task<List<Booking>> GetUserBookingsWithDetailsAsync(int userId);
    Task<Booking?> GetBookingByCodeWithDetailsAsync(string bookingCode);
    Task<Booking?> GetBookingByIdAndUserAsync(int bookingId, int userId);
    Task<Booking?> GetBookingByIdWithDetailsAsync(int bookingId);
}
