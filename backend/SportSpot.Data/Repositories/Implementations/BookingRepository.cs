using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;

namespace SportSpot.Data.Repositories.Implementations;

public class BookingRepository : GenericRepository<Booking>, IBookingRepository
{
    public BookingRepository(SportSpotDbContext context) : base(context)
    {
    }

    public async Task<SubVenue?> GetActiveSubVenueWithVenueAsync(int subVenueId)
    {
        return await _context.SubVenues
            .Include(sv => sv.Venue)
                .ThenInclude(v => v!.Sport)
            .FirstOrDefaultAsync(sv => sv.Id == subVenueId && sv.IsActive);
    }

    public async Task<List<TimeSlot>> GetTimeSlotsByIdsAsync(List<int> slotIds)
    {
        return await _context.TimeSlots
            .Where(ts => slotIds.Contains(ts.Id))
            .OrderBy(ts => ts.Id)
            .ToListAsync();
    }

    public async Task<List<BookingDetail>> GetConflictedSlotsAsync(int subVenueId, DateOnly playDate, List<int> slotIds)
    {
        return await _context.BookingDetails
            .Include(bd => bd.TimeSlot)
            .Where(bd => bd.SubVenueId == subVenueId &&
                         bd.PlayDate == playDate &&
                         slotIds.Contains(bd.SlotId) &&
                         bd.Status != "Cancelled")
            .ToListAsync();
    }

    public async Task<Dictionary<int, Service>> GetVenueServicesDictionaryAsync(int venueId, List<int> serviceIds)
    {
        return await _context.Services
            .Where(s => serviceIds.Contains(s.Id) && s.VenueId == venueId)
            .ToDictionaryAsync(s => s.Id);
    }

    public async Task<List<Booking>> GetUserBookingsWithDetailsAsync(int userId)
    {
        return await _dbSet
            .Include(b => b.SubVenue)
                .ThenInclude(sv => sv!.Venue)
                    .ThenInclude(v => v!.Sport)
            .Include(b => b.BookingDetails)
                .ThenInclude(bd => bd.TimeSlot)
            .Include(b => b.Transactions)
            .Where(b => b.UserId == userId)
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync();
    }

    public async Task<Booking?> GetBookingByCodeWithDetailsAsync(string bookingCode)
    {
        return await _dbSet
            .Include(b => b.User)
            .Include(b => b.SubVenue)
                .ThenInclude(sv => sv!.Venue)
                    .ThenInclude(v => v!.Sport)
            .Include(b => b.BookingDetails)
                .ThenInclude(bd => bd.TimeSlot)
            .Include(b => b.Transactions)
            .Include(b => b.OpenMatch)
                .ThenInclude(m => m!.MatchMembers)
                    .ThenInclude(mm => mm.User)
            .FirstOrDefaultAsync(b => b.BookingCode == bookingCode);
    }

    public async Task<Booking?> GetBookingByIdAndUserAsync(int bookingId, int userId)
    {
        return await _dbSet
            .Include(b => b.User)
            .Include(b => b.BookingDetails)
                .ThenInclude(bd => bd.TimeSlot)
            .Include(b => b.Transactions)
            .Include(b => b.OpenMatch)
                .ThenInclude(m => m!.MatchMembers)
                    .ThenInclude(mm => mm.User)
            .FirstOrDefaultAsync(b => b.Id == bookingId && b.UserId == userId);
    }

    public async Task<Booking?> GetBookingByIdWithDetailsAsync(int bookingId)
    {
        return await _dbSet
            .Include(b => b.User)
            .Include(b => b.SubVenue)
                .ThenInclude(sv => sv!.Venue)
                    .ThenInclude(v => v!.Sport)
            .Include(b => b.BookingDetails)
                .ThenInclude(bd => bd.TimeSlot)
            .Include(b => b.Transactions)
            .FirstOrDefaultAsync(b => b.Id == bookingId);
    }
}
