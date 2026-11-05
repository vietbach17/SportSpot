using SportSpot.Data.Entities;

namespace SportSpot.Data.Repositories.Interfaces;

public interface IVenueRepository : IGenericRepository<Venue>
{
    Task<List<Venue>> GetActiveVenuesAsync(int? sportId, string? search);
    Task<Venue?> GetVenueDetailByIdAsync(int id);
    Task<List<TimeSlot>> GetAllTimeSlotsOrderedAsync();
    Task<List<VenueSlotConfig>> GetVenueSlotConfigsAsync(int venueId);
    Task<List<int>> GetBookedSlotIdsAsync(int subVenueId, DateOnly playDate);
    Task<List<int>> GetFavoriteVenueIdsAsync(int userId);
    Task<FavoriteVenue?> GetFavoriteVenueAsync(int userId, int venueId);
    Task AddFavoriteVenueAsync(FavoriteVenue favorite);
    void RemoveFavoriteVenue(FavoriteVenue favorite);
}
