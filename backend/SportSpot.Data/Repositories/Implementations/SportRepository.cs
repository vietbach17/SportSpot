using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;

namespace SportSpot.Data.Repositories.Implementations;

public class SportRepository : GenericRepository<Sport>, ISportRepository
{
    public SportRepository(SportSpotDbContext context) : base(context)
    {
    }

    public async Task<List<Sport>> GetSportsWithVenuesAsync()
        => await _dbSet.Include(s => s.Venues).ToListAsync();
}
