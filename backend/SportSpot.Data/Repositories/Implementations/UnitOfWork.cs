using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using SportSpot.Data.Context;
using SportSpot.Data.Repositories.Interfaces;

namespace SportSpot.Data.Repositories.Implementations;

public class UnitOfWork : IUnitOfWork
{
    private readonly SportSpotDbContext _context;

    public IUserRepository Users { get; }
    public ISportRepository Sports { get; }
    public IVenueRepository Venues { get; }
    public IBookingRepository Bookings { get; }
    public IMatchRepository Matches { get; }
    public ITransactionRepository Transactions { get; }

    public UnitOfWork(
        SportSpotDbContext context,
        IUserRepository userRepository,
        ISportRepository sportRepository,
        IVenueRepository venueRepository,
        IBookingRepository bookingRepository,
        IMatchRepository matchRepository,
        ITransactionRepository transactionRepository)
    {
        _context = context;
        Users = userRepository;
        Sports = sportRepository;
        Venues = venueRepository;
        Bookings = bookingRepository;
        Matches = matchRepository;
        Transactions = transactionRepository;
    }

    public async Task<int> SaveChangesAsync() => await _context.SaveChangesAsync();

    public async Task<IDbContextTransaction> BeginTransactionAsync(IsolationLevel isolationLevel = IsolationLevel.ReadCommitted)
        => await _context.Database.BeginTransactionAsync(isolationLevel);

    public void Dispose()
    {
        _context.Dispose();
    }
}
