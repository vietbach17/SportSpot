using SportSpot.Data.Entities;

namespace SportSpot.Data.Repositories.Interfaces;

public interface ISportRepository : IGenericRepository<Sport>
{
    Task<List<Sport>> GetSportsWithVenuesAsync();
}
