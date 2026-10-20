using SportSpot.Data.Entities;

namespace SportSpot.Data.Repositories.Interfaces;

public interface ITransactionRepository : IGenericRepository<Transaction>
{
    Task<List<Transaction>> GetByBookingIdAsync(int bookingId);
    Task<Transaction?> GetByTransactionCodeAsync(string transactionCode);
}
