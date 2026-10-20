using Microsoft.EntityFrameworkCore.Storage;

namespace SportSpot.Data.Repositories.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IUserRepository Users { get; }
    ISportRepository Sports { get; }
    IVenueRepository Venues { get; }
    IBookingRepository Bookings { get; }
    IMatchRepository Matches { get; }
    ITransactionRepository Transactions { get; }

    Task<int> SaveChangesAsync();
    Task<IDbContextTransaction> BeginTransactionAsync();
}
