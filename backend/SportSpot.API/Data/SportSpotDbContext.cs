using Microsoft.EntityFrameworkCore;
using SportSpot.API.Models;

namespace SportSpot.API.Data;

public class SportSpotDbContext : DbContext
{
    public SportSpotDbContext(DbContextOptions<SportSpotDbContext> options) : base(options)
    {
    }

    public DbSet<Sport> Sports => Set<Sport>();
    public DbSet<Venue> Venues => Set<Venue>();
    public DbSet<SubVenue> SubVenues => Set<SubVenue>();
    public DbSet<Service> Services => Set<Service>();
    public DbSet<TimeSlot> TimeSlots => Set<TimeSlot>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<BookingDetail> BookingDetails => Set<BookingDetail>();
    public DbSet<BookingService> BookingServices => Set<BookingService>();
    public DbSet<OpenMatch> OpenMatches => Set<OpenMatch>();
    public DbSet<MatchMember> MatchMembers => Set<MatchMember>();
    public DbSet<Transaction> Transactions => Set<Transaction>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Sports Unique
        modelBuilder.Entity<Sport>()
            .HasIndex(s => s.Name)
            .IsUnique();

        // Users Unique
        modelBuilder.Entity<User>()
            .HasIndex(u => u.PhoneNumber)
            .IsUnique();

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        // Bookings Unique
        modelBuilder.Entity<Booking>()
            .HasIndex(b => b.BookingCode)
            .IsUnique();

        // Transactions Unique
        modelBuilder.Entity<Transaction>()
            .HasIndex(t => t.TransactionCode)
            .IsUnique();

        // BookingDetail Unique within booking
        modelBuilder.Entity<BookingDetail>()
            .HasIndex(bd => new { bd.BookingId, bd.SlotId })
            .IsUnique();

        // RÀNG BUỘC CHỐNG TRÙNG LỊCH:
        // Ngăn chặn 2 booking khác nhau đặt cùng 1 sân con + cùng ngày + cùng slot giờ (cho các đơn chưa hủy)
        modelBuilder.Entity<BookingDetail>()
            .HasIndex(bd => new { bd.SubVenueId, bd.PlayDate, bd.SlotId })
            .HasDatabaseName("UQ_SubVenue_Date_Slot_Active")
            .HasFilter("\"Status\" != 'Cancelled'")
            .IsUnique();

        // Seed Sports
        modelBuilder.Entity<Sport>().HasData(
            new Sport { Id = 1, Name = "Cầu lông", IconUrl = "https://cdn-icons-png.flaticon.com/512/2906/2906478.png" },
            new Sport { Id = 2, Name = "Pickleball", IconUrl = "https://cdn-icons-png.flaticon.com/512/8144/8144709.png" },
            new Sport { Id = 3, Name = "Bóng đá mini", IconUrl = "https://cdn-icons-png.flaticon.com/512/861/861512.png" },
            new Sport { Id = 4, Name = "Bóng rổ", IconUrl = "https://cdn-icons-png.flaticon.com/512/889/889455.png" }
        );

        // Seed TimeSlots (6:00 - 22:00)
        modelBuilder.Entity<TimeSlot>().HasData(
            new TimeSlot { Id = 1, StartTime = "06:00", EndTime = "07:00", IsPeak = false },
            new TimeSlot { Id = 2, StartTime = "07:00", EndTime = "08:00", IsPeak = false },
            new TimeSlot { Id = 3, StartTime = "08:00", EndTime = "09:00", IsPeak = false },
            new TimeSlot { Id = 4, StartTime = "09:00", EndTime = "10:00", IsPeak = false },
            new TimeSlot { Id = 5, StartTime = "10:00", EndTime = "11:00", IsPeak = false },
            new TimeSlot { Id = 6, StartTime = "14:00", EndTime = "15:00", IsPeak = false },
            new TimeSlot { Id = 7, StartTime = "15:00", EndTime = "16:00", IsPeak = false },
            new TimeSlot { Id = 8, StartTime = "16:00", EndTime = "17:00", IsPeak = false },
            new TimeSlot { Id = 9, StartTime = "17:00", EndTime = "18:00", IsPeak = true },
            new TimeSlot { Id = 10, StartTime = "18:00", EndTime = "19:00", IsPeak = true },
            new TimeSlot { Id = 11, StartTime = "19:00", EndTime = "20:00", IsPeak = true },
            new TimeSlot { Id = 12, StartTime = "20:00", EndTime = "21:00", IsPeak = true },
            new TimeSlot { Id = 13, StartTime = "21:00", EndTime = "22:00", IsPeak = true }
        );
    }
}
