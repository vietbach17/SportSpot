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
            AddColumn(db, "Users", "IsActive", "INTEGER NOT NULL DEFAULT 1");

            AddColumn(db, "Venues", "OwnerUserId", "INTEGER NULL REFERENCES Users(Id)");
            AddColumn(db, "Venues", "ApprovalStatus", "TEXT NOT NULL DEFAULT 'Approved'");
            AddColumn(db, "Venues", "RejectionReason", "TEXT NULL");
            AddColumn(db, "Venues", "SubmittedAt", "TEXT NULL");
            AddColumn(db, "Venues", "ReviewedAt", "TEXT NULL");
            AddColumn(db, "Venues", "ReviewedByUserId", "INTEGER NULL");
            AddColumn(db, "Venues", "ReviewRevision", "INTEGER NOT NULL DEFAULT 0");
            AddColumn(db, "Venues", "MaxSlotsPerBooking", "INTEGER NOT NULL DEFAULT 3");
            AddColumn(db, "Venues", "MinDepositPercent", "INTEGER NOT NULL DEFAULT 30");

            AddColumn(db, "OpenMatches", "Revision", "INTEGER NOT NULL DEFAULT 0");
            AddColumn(db, "OpenMatches", "SkillLevel", "TEXT NOT NULL DEFAULT 'Cơ bản'");
            AddColumn(db, "OpenMatches", "Title", "TEXT NULL");
            AddColumn(db, "OpenMatches", "HostNote", "TEXT NULL");
            AddColumn(db, "OpenMatches", "HostPhone", "TEXT NULL");
            AddColumn(db, "Bookings", "CustomerName", "TEXT NULL");
            AddColumn(db, "Bookings", "CustomerPhone", "TEXT NULL");
            AddColumn(db, "Bookings", "ManagementNote", "TEXT NULL");

            db.Database.ExecuteSqlRaw(@"
                CREATE TABLE IF NOT EXISTS VenueImages (
                    Id INTEGER PRIMARY KEY AUTOINCREMENT,
                    UploadedByUserId INTEGER NOT NULL REFERENCES Users(Id) ON DELETE RESTRICT,
                    VenueId INTEGER NULL REFERENCES Venues(Id) ON DELETE SET NULL,
                    Url TEXT NOT NULL,
                    PublicId TEXT NOT NULL,
                    Position INTEGER NOT NULL DEFAULT 0,
                    CreatedAt TEXT NOT NULL);
                CREATE INDEX IF NOT EXISTS IX_VenueImages_UploadedByUserId ON VenueImages(UploadedByUserId);
                CREATE INDEX IF NOT EXISTS IX_VenueImages_VenueId ON VenueImages(VenueId);

                CREATE TABLE IF NOT EXISTS VenueModerationLogs (
                    Id INTEGER PRIMARY KEY AUTOINCREMENT,
                    VenueId INTEGER NOT NULL REFERENCES Venues(Id) ON DELETE CASCADE,
                    AdminUserId INTEGER NOT NULL REFERENCES Users(Id) ON DELETE RESTRICT,
                    Decision TEXT NOT NULL,
                    Reason TEXT NOT NULL,
                    CreatedAt TEXT NOT NULL);
                CREATE INDEX IF NOT EXISTS IX_VenueModerationLogs_VenueId ON VenueModerationLogs(VenueId);
                CREATE INDEX IF NOT EXISTS IX_VenueModerationLogs_AdminUserId ON VenueModerationLogs(AdminUserId);

                CREATE TABLE IF NOT EXISTS VenueSlotConfigs (
                    Id INTEGER PRIMARY KEY AUTOINCREMENT,
                    VenueId INTEGER NOT NULL REFERENCES Venues(Id) ON DELETE CASCADE,
                    SlotId INTEGER NOT NULL REFERENCES TimeSlots(Id) ON DELETE CASCADE,
                    IsActive INTEGER NOT NULL DEFAULT 1,
                    IsPeak INTEGER NOT NULL DEFAULT 0,
                    CustomPrice INTEGER NULL);
                CREATE UNIQUE INDEX IF NOT EXISTS IX_VenueSlotConfigs_VenueId_SlotId ON VenueSlotConfigs(VenueId, SlotId);
                CREATE INDEX IF NOT EXISTS IX_VenueSlotConfigs_SlotId ON VenueSlotConfigs(SlotId);

                INSERT OR IGNORE INTO TimeSlots (Id, StartTime, EndTime, IsPeak) VALUES
                    (14, '05:00', '06:00', 0),
                    (15, '11:00', '12:00', 0),
                    (16, '12:00', '13:00', 0),
                    (17, '13:00', '14:00', 0),
                    (18, '22:00', '23:00', 1),
                    (19, '23:00', '23:59', 1);

                CREATE TABLE IF NOT EXISTS UserSkills (
                    Id INTEGER PRIMARY KEY AUTOINCREMENT,
                    UserId INTEGER NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
                    SportId INTEGER NOT NULL REFERENCES Sports(Id) ON DELETE CASCADE,
                    SkillLevel TEXT NOT NULL, RatingScore TEXT NOT NULL, IsVerified INTEGER NOT NULL,
                    VerifiedBy TEXT NULL, UpdatedAt TEXT NOT NULL);
                CREATE UNIQUE INDEX IF NOT EXISTS IX_UserSkills_UserId_SportId ON UserSkills(UserId, SportId);
                CREATE INDEX IF NOT EXISTS IX_UserSkills_SportId ON UserSkills(SportId);
                CREATE TABLE IF NOT EXISTS Teams (
                    Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL,
                    CaptainUserId INTEGER NOT NULL REFERENCES Users(Id) ON DELETE RESTRICT,
                    TeamSize INTEGER NOT NULL, SkillLevel TEXT NOT NULL, CreatedAt TEXT NOT NULL);
                CREATE INDEX IF NOT EXISTS IX_Teams_CaptainUserId ON Teams(CaptainUserId);
                CREATE TABLE IF NOT EXISTS TeamChallenges (
                    Id INTEGER PRIMARY KEY AUTOINCREMENT,
                    TeamId INTEGER NOT NULL REFERENCES Teams(Id) ON DELETE RESTRICT,
                    BookingId INTEGER NOT NULL REFERENCES Bookings(Id) ON DELETE RESTRICT,
                    Note TEXT NOT NULL, Status TEXT NOT NULL, Revision INTEGER NOT NULL, CreatedAt TEXT NOT NULL);
                CREATE UNIQUE INDEX IF NOT EXISTS IX_TeamChallenges_BookingId ON TeamChallenges(BookingId);
                CREATE INDEX IF NOT EXISTS IX_TeamChallenges_TeamId ON TeamChallenges(TeamId);
                CREATE TABLE IF NOT EXISTS TeamChallengeRequests (
                    Id INTEGER PRIMARY KEY AUTOINCREMENT,
                    TeamChallengeId INTEGER NOT NULL REFERENCES TeamChallenges(Id) ON DELETE CASCADE,
                    TeamId INTEGER NOT NULL REFERENCES Teams(Id) ON DELETE RESTRICT,
                    Message TEXT NOT NULL, Status TEXT NOT NULL, CreatedAt TEXT NOT NULL);
                CREATE UNIQUE INDEX IF NOT EXISTS IX_TeamChallengeRequests_TeamChallengeId_TeamId
                    ON TeamChallengeRequests(TeamChallengeId, TeamId);
                CREATE INDEX IF NOT EXISTS IX_TeamChallengeRequests_TeamId ON TeamChallengeRequests(TeamId);");
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
        command.CommandText = $"ALTER TABLE {table} ADD COLUMN {column} {definition}";
        command.ExecuteNonQuery();
    }
}
