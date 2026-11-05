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
            AddColumn(db, "Users", "FcmToken", "TEXT NULL");
            AddColumn(db, "Users", "DateOfBirth", "TEXT NULL");
            AddColumn(db, "OpenMatches", "Revision", "INTEGER NOT NULL DEFAULT 0");
            AddColumn(db, "OpenMatches", "SkillLevel", "TEXT NOT NULL DEFAULT 'Cơ bản'");
            AddColumn(db, "OpenMatches", "Title", "TEXT NULL");
            AddColumn(db, "OpenMatches", "HostNote", "TEXT NULL");
            AddColumn(db, "OpenMatches", "HostPhone", "TEXT NULL");
            db.Database.ExecuteSqlRaw("CREATE UNIQUE INDEX IF NOT EXISTS IX_MatchMembers_MatchId_UserId ON MatchMembers(MatchId, UserId)");
            db.Database.ExecuteSqlRaw("CREATE INDEX IF NOT EXISTS IX_Users_StaffVenueId ON Users(StaffVenueId)");
            db.Database.ExecuteSqlRaw(@"CREATE TABLE IF NOT EXISTS Notifications (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                UserId INTEGER NOT NULL,
                Title TEXT NOT NULL,
                Message TEXT NOT NULL,
                Type TEXT NOT NULL,
                IsRead INTEGER NOT NULL,
                CreatedAt TEXT NOT NULL,
                FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
            );");
            db.Database.ExecuteSqlRaw(@"CREATE TABLE IF NOT EXISTS FavoriteVenues (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                UserId INTEGER NOT NULL,
                VenueId INTEGER NOT NULL,
                CreatedAt TEXT NOT NULL,
                FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
                FOREIGN KEY (VenueId) REFERENCES Venues(Id) ON DELETE CASCADE
            );");
            db.Database.ExecuteSqlRaw(@"CREATE UNIQUE INDEX IF NOT EXISTS IX_FavoriteVenues_UserId_VenueId ON FavoriteVenues(UserId, VenueId);");
            db.Database.ExecuteSqlRaw(@"CREATE TABLE IF NOT EXISTS MatchComments (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                MatchId INTEGER NOT NULL,
                UserId INTEGER NOT NULL,
                Content TEXT NOT NULL,
                CreatedAt TEXT NOT NULL,
                FOREIGN KEY (MatchId) REFERENCES OpenMatches(Id) ON DELETE CASCADE,
                FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
            );");
            db.Database.ExecuteSqlRaw(@"CREATE TABLE IF NOT EXISTS Reviews (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                VenueId INTEGER NOT NULL,
                UserId INTEGER NOT NULL,
                Rating INTEGER NOT NULL,
                Comment TEXT NOT NULL,
                CreatedAt TEXT NOT NULL,
                FOREIGN KEY (VenueId) REFERENCES Venues(Id) ON DELETE CASCADE,
                FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE RESTRICT
            );");
            db.Database.ExecuteSqlRaw(@"CREATE TABLE IF NOT EXISTS UserSkills (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                UserId INTEGER NOT NULL,
                SportId INTEGER NOT NULL,
                SkillLevel TEXT NOT NULL DEFAULT 'Phong trào',
                RatingScore NUMERIC NOT NULL DEFAULT 3.5,
                IsVerified INTEGER NOT NULL DEFAULT 0,
                VerifiedBy TEXT NULL,
                UpdatedAt TEXT NOT NULL,
                FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
                FOREIGN KEY (SportId) REFERENCES Sports(Id) ON DELETE CASCADE
            );");
            db.Database.ExecuteSqlRaw(@"CREATE UNIQUE INDEX IF NOT EXISTS IX_UserSkills_UserId_SportId ON UserSkills(UserId, SportId);");
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
