using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Implementations;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;
using SportSpot.Services.Implementations;

using var connection = new SqliteConnection("Data Source=:memory:");
connection.Open();
var options = new DbContextOptionsBuilder<SportSpotDbContext>().UseSqlite(connection).Options;
SportSpotDbContext Context() => new(options);
UnitOfWork Uow(SportSpotDbContext db) => new(db, new UserRepository(db), new SportRepository(db),
    new VenueRepository(db), new BookingRepository(db), new MatchRepository(db), new TransactionRepository(db));
MatchService Service(SportSpotDbContext db) => new(Uow(db), db);
var passed = 0;
void Check(bool condition, string label) {
    if (!condition) throw new Exception($"FAIL: {label}");
    passed++; Console.WriteLine($"PASS: {label}");
}
async Task<ApiResponse<T>> Run<T>(Func<MatchService, Task<ApiResponse<T>>> action) {
    using var db = Context(); return await action(Service(db));
}
using (var db = Context()) {
    db.Database.EnsureCreated();
    SqliteModule4Upgrade.Apply(db);
    SqliteModule4Upgrade.Apply(db);
    db.Venues.AddRange(new Venue { Id = 1, SportId = 1, Name = "Test Court", District = "Thủ Đức", BasePrice = 200000, PeakPrice = 300000 },
        new Venue { Id = 2, SportId = 2, Name = "Other Court" });
    db.SubVenues.Add(new SubVenue { Id = 1, VenueId = 1, Name = "Court 1" });
    db.Services.Add(new Service { Id = 1, VenueId = 1, Name = "Water", Price = 10000, StockQuantity = 100 });
    db.Users.AddRange(Enumerable.Range(1, 8).Select(id => new User { Id = id, PhoneNumber = $"090000000{id}", FullName = $"User {id}",
        Role = id is 3 or 4 ? "VenueStaff" : "Player", StaffVenueId = id == 3 ? 1 : id == 4 ? 2 : null }));
    db.SaveChanges();
}
var tomorrow = DateOnly.FromDateTime(MatchRules.VietnamNow).AddDays(2);
async Task<int> Booking(int day, bool recruit = true, int deposit = 30) {
    using var db = Context(); var uow = Uow(db);
    var result = await new SportSpot.Services.Implementations.BookingService(uow, new TicketService(uow)).CreateBookingAsync(new CreateBookingRequest {
        UserId = 1, SubVenueId = 1, PlayDate = tomorrow.AddDays(day), SlotIds = new() { 10, 11 },
        IsOpenMatch = recruit, TotalExpectedPlayers = 10, NeededPlayers = 4, DepositPercentage = deposit
    });
    Check(result.Success, $"Booking day {day} with recruitment={recruit}");
    return result.Data!.BookingId;
}
int bookingId = await Booking(0);
int matchId;
using (var db = Context()) matchId = await db.OpenMatches.Where(m => m.BookingId == bookingId).Select(m => m.Id).SingleAsync();
Check(MatchRules.SplitCost(600000, 10) == 60000 && MatchRules.SplitCost(201, 2) == 101, "Cost uses decimal and half-up rounding");
var detail = await Run(s => s.GetMatchAsync(matchId));
Check(detail.Data!.CostPerPerson == 60000 && detail.Data.RemainingBalanceForHost == 420000, "600k court, 10 players -> fixed 60k, 30% deposit");
Check((await Run(s => s.GetOpenMatchesAsync(1, "Thủ Đức"))).Data!.Count == 1, "Feed filters sport and district");
Check((await Run(s => s.GetOpenMatchesAsync(2, null))).Data!.Count == 0, "Feed excludes other sports");
Check((await Run(s => s.GetStaffMatchesAsync(4))).Data!.Count == 0, "Staff only sees own venue");
Check((await Run(s => s.GetStaffMatchesAsync(2))).StatusCode == 403, "Player cannot use staff desk");
Check((await Run(s => s.JoinMatchAsync(matchId, new() { UserId = 1 }))).StatusCode == 409, "Host cannot join own match");
Check((await Run(s => s.JoinMatchAsync(matchId, new() { UserId = 2, PaymentGateway = "VNPay" }))).StatusCode == 400, "Unverified real payment cannot create paid member");
Check((await Run(s => s.JoinMatchAsync(matchId, new() { UserId = 2 }))).Success, "App player joins");
Check((await Run(s => s.GetMyTicketAsync(matchId, 2))).Success, "Joined player can retrieve own private ticket");
Check((await Run(s => s.GetMyTicketAsync(matchId, 6))).StatusCode == 404, "Other player cannot retrieve member ticket");
Check((await Run(s => s.JoinMatchAsync(matchId, new() { UserId = 2 }))).StatusCode == 409, "Duplicate join rejected");
Check((await Run(s => s.AssignWalkInAtDeskAsync(matchId, 4))).StatusCode == 403, "Other venue staff cannot assign");
Check((await Run(s => s.AssignWalkInAtDeskAsync(matchId, 3))).Success, "Own venue staff assigns cash guest");
detail = await Run(s => s.GetMatchAsync(matchId));
Check(detail.Data!.RemainingBalanceForHost == 300000 && detail.Data.Members.Count == 2, "App + desk reduce host balance by exactly 120k");
using (var db = Context()) {
    Check(await db.Transactions.CountAsync(t => t.BookingId == bookingId) == 3, "Deposit and both contributions recorded");
    Check(await db.Transactions.AnyAsync(t => t.BookingId == bookingId && t.PaymentGateway == "Cash" && t.Status == "Settled"), "Cash payment audited");
    var qr = (await db.MatchMembers.SingleAsync(m => m.UserId == 2)).TicketQrPayload;
    Check(QrChecksumHelper.ValidateSignedQrPayload(qr!, out _, out var uid, out _) && uid == 2, "App player gets signed private QR");
}
// Force two requests to observe the same revision before either writes.
using (var stale = Context()) {
    await new MatchRepository(stale).GetMatchByIdWithDetailsAsync(matchId);
    Check((await Run(s => s.JoinMatchAsync(matchId, new() { UserId = 5 }))).Success, "First competing request succeeds");
    Check((await Service(stale).JoinMatchAsync(matchId, new() { UserId = 6 })).StatusCode == 409, "Stale competing request returns 409");
}
using (var db = Context()) {
    Check(await db.MatchMembers.CountAsync(m => m.MatchId == matchId) == 3 &&
        await db.Transactions.CountAsync(t => t.BookingId == bookingId) == 4 &&
        (await db.Bookings.FindAsync(bookingId))!.RemainingBalance == 240000, "Conflict rolls back member, payment and balance together");
}
Check((await Run(s => s.AssignWalkInAtDeskAsync(matchId, 3))).Success, "Last available slot assigned");
Check((await Run(s => s.GetMatchAsync(matchId))).Data!.Status == "Full", "App + desk automatically close full match");
Check((await Run(s => s.JoinMatchAsync(matchId, new() { UserId = 6 }))).StatusCode == 409, "No over-capacity join");
Check((await Run(s => s.LeaveMatchAsync(matchId, 2))).Success, "Player leaves before four hours");
Check((await Run(s => s.GetMatchAsync(matchId))).Data!.Status == "Open", "Full match reopens one vacancy");
Check((await Run(s => s.StopRecruitingAsync(matchId, 0))).StatusCode == 403, "Zero identity cannot bypass host check");
Check((await Run(s => s.StopRecruitingAsync(matchId, 2))).StatusCode == 403, "Non-host cannot stop recruitment");
Check((await Run(s => s.StopRecruitingAsync(matchId, 1))).Success, "Host stops recruitment");
Check((await Run(s => s.JoinMatchAsync(matchId, new() { UserId = 6 }))).StatusCode == 409, "Stopped match rejects joins");
Check((await Run(s => s.LeaveMatchAsync(matchId, 5))).Success && (await Run(s => s.GetMatchAsync(matchId))).Data!.Status == "Stopped", "Leaving never reopens host-stopped recruitment");
var plain = await Booking(1, false);
Check((await Run(s => s.CreateMatchAsync(2, new() { BookingId = plain, TotalExpectedPlayers = 10, NeededPlayers = 4 }))).StatusCode == 403, "Cannot recruit against another host booking");
Check((await Run(s => s.CreateMatchAsync(1, new() { BookingId = plain, TotalExpectedPlayers = 0, NeededPlayers = 4 }))).StatusCode == 400, "Invalid totals rejected before division");
Check((await Run(s => s.CreateMatchAsync(1, new() { BookingId = plain, TotalExpectedPlayers = 4, NeededPlayers = 4 }))).StatusCode == 400, "Recruit count must leave a place for host");
var created = await Run(s => s.CreateMatchAsync(1, new() { BookingId = plain, TotalExpectedPlayers = 10, NeededPlayers = 4 }));
Check(created.Success, "Host creates recruitment for an existing booking");
Check(!(await Run(s => s.CreateMatchAsync(1, new() { BookingId = plain, TotalExpectedPlayers = 10, NeededPlayers = 4 }))).Success, "Only one match per booking");
var prepaid = await Booking(2, true, 100);
using (var db = Context()) matchId = await db.OpenMatches.Where(m => m.BookingId == prepaid).Select(m => m.Id).SingleAsync();
await Run(s => s.JoinMatchAsync(matchId, new() { UserId = 2 }));
Check((await Run(s => s.GetMatchAsync(matchId))).Data!.RemainingBalanceForHost == -60000, "Prepaid host retains contribution as credit");
using (var db = Context()) {
    var booking = (await db.Bookings.FindAsync(prepaid))!; booking.Status = "Cancelled"; await db.SaveChangesAsync();
}
Check((await Run(s => s.JoinMatchAsync(matchId, new() { UserId = 6 }))).StatusCode == 409, "Cancelled booking rejects new members");
using (var db = Context()) {
    var uow = Uow(db);
    var svc = new SportSpot.Services.Implementations.BookingService(uow, new TicketService(uow));
    var response = await svc.CreateBookingAsync(new CreateBookingRequest {
        UserId = 1, SubVenueId = 1, PlayDate = tomorrow.AddDays(3), SlotIds = new() { 10, 11 },
        Services = new() { new() { ServiceId = 1, Quantity = 2 } },
        IsOpenMatch = true, TotalExpectedPlayers = 10, NeededPlayers = 4, DepositPercentage = 30
    });
    Check(response.Success && response.Data!.TotalPrice == 620000, "Accessory charges remain part of host booking");
    Check((await db.OpenMatches.SingleAsync(m => m.BookingId == response.Data!.BookingId)).CostPerPerson == 60000,
        "Split cost excludes accessory charges");
    var invalid = await svc.CreateBookingAsync(new CreateBookingRequest {
        UserId = 1, SubVenueId = 1, PlayDate = tomorrow.AddDays(4), SlotIds = new() { 5, 6 },
        IsOpenMatch = true, TotalExpectedPlayers = 10, NeededPlayers = 4
    });
    Check(!invalid.Success, "Adjacent slot IDs with non-adjacent times cannot be booked");
}
Console.WriteLine($"All {passed} checks passed (isolated SQLite, no user database touched).");
