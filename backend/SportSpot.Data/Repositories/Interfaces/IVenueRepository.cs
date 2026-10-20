using SportSpot.Data.Entities;

namespace SportSpot.Data.Repositories.Interfaces;

public interface IVenueRepository : IGenericRepository<Venue>
{
    Task<List<Venue>> GetActiveVenuesAsync(int? sportId, string? search);
    Task<Venue?> GetVenueDetailByIdAsync(int id);
    Task<List<TimeSlot>> GetAllTimeSlotsOrderedAsync();
    Task<List<int>> GetBookedSlotIdsAsync(int subVenueId, DateOnly playDate);
}
