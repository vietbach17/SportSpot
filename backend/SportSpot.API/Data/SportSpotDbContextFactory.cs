using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace SportSpot.API.Data;

/// <summary>
/// Factory để EF Core CLI luôn sử dụng Npgsql (PostgreSQL provider) khi sinh migrations,
/// tránh bị nhầm lẫn kiểu dữ liệu với SQLite (VD: bool thành INTEGER).
/// </summary>
public class SportSpotDbContextFactory : IDesignTimeDbContextFactory<SportSpotDbContext>
{
    public SportSpotDbContext CreateDbContext(string[] args)
    {
        DotNetEnv.Env.TraversePath().Load();

        var connectionString = Environment.GetEnvironmentVariable("DATABASE_CONNECTION_STRING");
        if (string.IsNullOrWhiteSpace(connectionString) || connectionString.Contains("your-project"))
        {
            connectionString = "Host=localhost;Port=5432;Database=SportSpotDb;Username=postgres;Password=postgres;";
        }

        var optionsBuilder = new DbContextOptionsBuilder<SportSpotDbContext>();
        optionsBuilder.UseNpgsql(connectionString);

        return new SportSpotDbContext(optionsBuilder.Options);
    }
}
