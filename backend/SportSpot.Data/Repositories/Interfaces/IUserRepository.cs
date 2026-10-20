using SportSpot.Data.Entities;

namespace SportSpot.Data.Repositories.Interfaces;

public interface IUserRepository : IGenericRepository<User>
{
    Task<User?> GetByPhoneNumberAsync(string phoneNumber);
}
