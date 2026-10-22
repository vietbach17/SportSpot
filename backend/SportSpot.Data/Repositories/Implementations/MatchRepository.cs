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
            .Include(m => m.MatchMembers).ThenInclude(mm => mm.User)
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

        var matches = await query.OrderByDescending(m => m.CreatedAt).ToListAsync();
        // SQLite lower() only handles ASCII; compare Vietnamese names consistently on both providers.
        return string.IsNullOrWhiteSpace(district) ? matches : matches.Where(m =>
            m.Booking?.SubVenue?.Venue?.District.Contains(district.Trim(), StringComparison.OrdinalIgnoreCase) == true).ToList();
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

    public async Task<List<MatchMember>> GetUserJoinedMatchesWithDetailsAsync(int userId)
    {
        return await _context.MatchMembers
            .Include(mm => mm.OpenMatch)
                .ThenInclude(m => m!.Booking)
                    .ThenInclude(b => b!.SubVenue)
                        .ThenInclude(sv => sv!.Venue)
                            .ThenInclude(v => v!.Sport)
            .Include(mm => mm.OpenMatch)
                .ThenInclude(m => m!.Booking)
                    .ThenInclude(b => b!.BookingDetails)
                        .ThenInclude(bd => bd.TimeSlot)
            .Include(mm => mm.OpenMatch)
                .ThenInclude(m => m!.Booking)
                    .ThenInclude(b => b!.Transactions)
            .Where(mm => mm.UserId == userId && mm.TicketQrPayload != null)
            .OrderByDescending(mm => mm.JoinedAt)
            .ToListAsync();
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
