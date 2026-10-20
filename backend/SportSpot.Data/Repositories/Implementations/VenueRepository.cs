using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;

namespace SportSpot.Data.Repositories.Implementations;

public class VenueRepository : GenericRepository<Venue>, IVenueRepository
{
    public VenueRepository(SportSpotDbContext context) : base(context)
    {
    }

    public async Task<List<Venue>> GetActiveVenuesAsync(int? sportId, string? search)
    {
        var query = _dbSet
            .Include(v => v.Sport)
            .Where(v => v.IsActive)
            .AsQueryable();

        if (sportId.HasValue && sportId.Value > 0)
        {
            query = query.Where(v => v.SportId == sportId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim().ToLower();
            query = query.Where(v => v.Name.ToLower().Contains(keyword) ||
                                     v.District.ToLower().Contains(keyword) ||
                                     v.Address.ToLower().Contains(keyword));
        }

        return await query.ToListAsync();
    }

    public async Task<Venue?> GetVenueDetailByIdAsync(int id)
    {
        return await _dbSet
            .Include(v => v.Sport)
            .Include(v => v.SubVenues.Where(sv => sv.IsActive))
            .Include(v => v.Services)
            .FirstOrDefaultAsync(v => v.Id == id && v.IsActive);
    }

    public async Task<List<TimeSlot>> GetAllTimeSlotsOrderedAsync()
    {
        return await _context.TimeSlots
            .OrderBy(s => s.Id)
            .ToListAsync();
    }

    public async Task<List<int>> GetBookedSlotIdsAsync(int subVenueId, DateOnly playDate)
    {
        return await _context.BookingDetails
            .Where(bd => bd.SubVenueId == subVenueId &&
                         bd.PlayDate == playDate &&
                         bd.Status != "Cancelled")
            .Select(bd => bd.SlotId)
            .ToListAsync();
    }
}
