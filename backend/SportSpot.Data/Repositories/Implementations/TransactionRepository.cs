using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;

namespace SportSpot.Data.Repositories.Implementations;

public class TransactionRepository : GenericRepository<Transaction>, ITransactionRepository
{
    public TransactionRepository(SportSpotDbContext context) : base(context)
    {
    }

    public async Task<List<Transaction>> GetByBookingIdAsync(int bookingId)
    {
        return await _dbSet
            .Where(t => t.BookingId == bookingId)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();
    }

    public async Task<Transaction?> GetByTransactionCodeAsync(string transactionCode)
    {
        return await _dbSet
            .Include(t => t.Booking)
            .FirstOrDefaultAsync(t => t.TransactionCode == transactionCode);
    }
}
