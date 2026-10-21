using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace SportSpot.Data.Context;

/// <summary>Additive upgrade for existing local dev databases created using EnsureCreated.</summary>
public static class SqliteModule4Upgrade
{
    public static void Apply(SportSpotDbContext db)
    {
        if (!db.Database.IsSqlite()) return;
        db.Database.OpenConnection();
        try
        {
            using var transaction = db.Database.BeginTransaction();
            AddColumn(db, "Users", "StaffVenueId", "INTEGER NULL REFERENCES Venues(Id)");
            AddColumn(db, "OpenMatches", "Revision", "INTEGER NOT NULL DEFAULT 0");
            AddColumn(db, "OpenMatches", "SkillLevel", "TEXT NOT NULL DEFAULT 'Cơ bản'");
            db.Database.ExecuteSqlRaw("CREATE UNIQUE INDEX IF NOT EXISTS IX_MatchMembers_MatchId_UserId ON MatchMembers(MatchId, UserId)");
            db.Database.ExecuteSqlRaw("CREATE INDEX IF NOT EXISTS IX_Users_StaffVenueId ON Users(StaffVenueId)");
            transaction.Commit();
        }
        finally { db.Database.CloseConnection(); }
    }

    private static void AddColumn(SportSpotDbContext db, string table, string column, string definition)
    {
        using var command = db.Database.GetDbConnection().CreateCommand();
        command.Transaction = db.Database.CurrentTransaction!.GetDbTransaction();
        command.CommandText = $"PRAGMA table_info({table})";
        using (var reader = command.ExecuteReader())
        {
            while (reader.Read()) if (reader.GetString(1) == column) return;
        }
        // Identifiers and definitions come exclusively from the constants above.
        command.CommandText = $"ALTER TABLE {table} ADD COLUMN {column} {definition}";
        command.ExecuteNonQuery();
    }
}
