using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;

namespace SportSpot.Data.Repositories.Implementations;

public class MatchRepository : GenericRepository<OpenMatch>, IMatchRepository
{
    public MatchRepository(SportSpotDbContext context) : base(context)
    {
    }

    public async Task<List<OpenMatch>> GetOpenMatchesWithDetailsAsync(int? sportId, string? district)
    {
        var query = _dbSet
            .Include(m => m.HostUser)
            .Include(m => m.Booking)
                .ThenInclude(b => b!.SubVenue)
                    .ThenInclude(sv => sv!.Venue)
                        .ThenInclude(v => v!.Sport)
            .Include(m => m.Booking)
                .ThenInclude(b => b!.BookingDetails)
                    .ThenInclude(bd => bd.TimeSlot)
            .Where(m => m.Status == "Open")
            .AsQueryable();

        if (sportId.HasValue && sportId.Value > 0)
        {
            query = query.Where(m => m.Booking != null &&
                                     m.Booking.SubVenue != null &&
                                     m.Booking.SubVenue.Venue != null &&
                                     m.Booking.SubVenue.Venue.SportId == sportId.Value);
        }

        if (!string.IsNullOrWhiteSpace(district))
        {
            var d = district.Trim().ToLower();
            query = query.Where(m => m.Booking != null &&
                                     m.Booking.SubVenue != null &&
                                     m.Booking.SubVenue.Venue != null &&
                                     m.Booking.SubVenue.Venue.District.ToLower().Contains(d));
        }

        return await query.OrderByDescending(m => m.CreatedAt).ToListAsync();
    }

    public async Task<OpenMatch?> GetMatchByIdWithDetailsAsync(int matchId)
    {
        return await _dbSet
            .Include(m => m.HostUser)
            .Include(m => m.Booking)
                .ThenInclude(b => b!.SubVenue)
                    .ThenInclude(sv => sv!.Venue)
                        .ThenInclude(v => v!.Sport)
            .Include(m => m.Booking)
                .ThenInclude(b => b!.BookingDetails)
                    .ThenInclude(bd => bd.TimeSlot)
            .Include(m => m.MatchMembers)
                .ThenInclude(mm => mm.User)
            .FirstOrDefaultAsync(m => m.Id == matchId);
    }

    public async Task<MatchMember?> GetMatchMemberAsync(int matchId, int userId)
    {
        return await _context.MatchMembers
            .FirstOrDefaultAsync(mm => mm.MatchId == matchId && mm.UserId == userId);
    }

    public async Task AddMatchMemberAsync(MatchMember member)
    {
        await _context.MatchMembers.AddAsync(member);
    }

    public void RemoveMatchMember(MatchMember member)
    {
        _context.MatchMembers.Remove(member);
    }
}
