using SportSpot.Data.Entities;

namespace SportSpot.Services.Interfaces;

public interface IJwtService
{
    string GenerateToken(User user);
}
