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
int count = 0;
void Check(bool ok, string label) { if (!ok) throw new Exception($"FAIL: {label}"); count++; Console.WriteLine($"PASS: {label}"); }
async Task<ApiResponse<T>> TeamRun<T>(Func<TeamService, Task<ApiResponse<T>>> action) { using var db = Context(); return await action(new(db)); }
async Task<ApiResponse<T>> OwnerRun<T>(Func<OwnerScheduleService, Task<ApiResponse<T>>> action) { using var db = Context(); return await action(new(db)); }
var day = DateOnly.FromDateTime(MatchRules.VietnamNow).AddDays(2);
using (var db = Context())
{
    db.Database.EnsureCreated();
    SqliteModule4Upgrade.Apply(db); SqliteModule4Upgrade.Apply(db);
    db.Venues.AddRange(new Venue { Id = 1, SportId = 3, Name = "Football", BasePrice = 300000, PeakPrice = 500000 },
        new Venue { Id = 2, SportId = 1, Name = "Other venue" });
    db.SubVenues.AddRange(new SubVenue { Id = 1, VenueId = 1, Name = "Pitch 1" }, new SubVenue { Id = 2, VenueId = 1, Name = "Pitch 2" },
        new SubVenue { Id = 3, VenueId = 2, Name = "Other court" });
    db.Users.AddRange(Enumerable.Range(1, 8).Select(i => new User { Id = i, FullName = $"User {i}", PhoneNumber = $"090000000{i}",
        Role = i == 5 || i == 6 ? "Owner" : i == 7 ? "VenueStaff" : i == 8 ? "Admin" : "Player",
        StaffVenueId = i == 5 || i == 7 ? 1 : i == 6 ? 2 : null }));
    db.SaveChanges();
}
Check((await OwnerRun(s => s.Venues(1))).StatusCode == 403, "Player cannot access owner venues");
Check((await OwnerRun(s => s.Venues(5))).Data!.Single().Id == 1, "Owner only sees assigned venue");
Check((await OwnerRun(s => s.Venues(8))).Data!.Count == 2, "Admin sees all venues");
using (var db = Context())
{
    db.Users.Add(new User { Id = 90, FullName = "New owner", PhoneNumber = "0900000090", Role = "Owner" });
    await db.SaveChangesAsync();
    var dashboard = new OwnerService(db);
    var empty = await dashboard.GetOwnerDashboardForUserAsync(90);
    Check(empty.Success && empty.StatusCode == 200 && empty.Data is { HasVenue: false },
        "Owner without approved venues receives a successful empty dashboard instead of 403");
    Check((await dashboard.GetOwnerDashboardForUserAsync(1)).StatusCode == 403,
        "Player remains forbidden from owner dashboard");
    Check((await dashboard.GetOwnerDashboardForUserAsync(5, 2)).StatusCode == 403,
        "Owner dashboard denies another owner's venue");
    Check((await dashboard.GetOwnerDashboardForUserAsync(5)).Data is { HasVenue: true, VenueId: 1 },
        "Assigned owner dashboard selects their own approved venue");
    Check((await dashboard.GetOwnerDashboardForUserAsync(90, 0)).StatusCode == 403,
        "Explicit invalid venue does not fall back to a successful empty dashboard");
    var pendingVenue = new Venue { OwnerUserId = 90, Name = "Pending owner venue", SportId = 1, ApprovalStatus = "Pending", IsActive = false };
    db.Venues.Add(pendingVenue);
    await db.SaveChangesAsync();
    Check((await dashboard.GetOwnerDashboardForUserAsync(90)).Data is { HasVenue: false },
        "Pending venue displays onboarding instead of revenue statistics");
    Check((await dashboard.GetOwnerDashboardForUserAsync(90, pendingVenue.Id)).StatusCode == 403,
        "Explicit pending venue remains forbidden");
    pendingVenue.ApprovalStatus = "Approved";
    pendingVenue.IsActive = true;
    await db.SaveChangesAsync();
    Check((await dashboard.GetOwnerDashboardForUserAsync(90)).Data is { HasVenue: true },
        "Dashboard becomes available once the owner's venue is approved");
    (await db.Users.FindAsync(90))!.IsActive = false;
    await db.SaveChangesAsync();
    Check((await dashboard.GetOwnerDashboardForUserAsync(90)).StatusCode == 403,
        "Locked owner cannot access dashboard");
}
Check((await OwnerRun(s => s.Schedule(6, 1, day, day))).StatusCode == 403, "Other owner cannot inspect customer details");
Check((await OwnerRun(s => s.Schedule(7, 1, day, day))).Success, "Assigned staff can access schedule");
Check((await OwnerRun(s => s.Schedule(5, 1, day, day.AddDays(31)))).StatusCode == 400, "Schedule rejects overly broad date range");
CreateManagedBookingRequest Manual(int court, List<int> slots, bool maintenance = false) => new() {
    SubVenueId = court, PlayDate = day, SlotIds = slots, Maintenance = maintenance, CustomerName = "Walk-in customer",
    CustomerPhone = "0901234567", Note = "Repair lighting", CollectedAmount = 0 };
Check((await OwnerRun(s => s.Create(6, Manual(1, new() { 10 })))).StatusCode == 403, "Cross-venue creation denied");
Check((await OwnerRun(s => s.Create(5, Manual(1, new() { 10, 10 })))).StatusCode == 400, "Duplicate slots denied");
Check((await OwnerRun(s => s.Create(5, Manual(1, new() { 1, 3 })))).StatusCode == 400, "Nonconsecutive slots denied");
var past = Manual(1, new() { 10 }); past.PlayDate = day.AddDays(-10);
Check((await OwnerRun(s => s.Create(5, past))).StatusCode == 400, "Past booking denied");
var invalid = Manual(1, new() { 10 }); invalid.CollectedAmount = 500001;
Check((await OwnerRun(s => s.Create(5, invalid))).StatusCode == 400, "Cannot collect more than court price");
Check((await OwnerRun(s => s.Create(5, Manual(1, new() { 10 }, true)))).Success, "Owner can block one hour for maintenance");
int blockId;
using (var db = Context()) blockId = await db.Bookings.Where(b => b.BookingType == "Maintenance").Select(b => b.Id).SingleAsync();
Check((await OwnerRun(s => s.Create(5, Manual(1, new() { 10 })))).StatusCode == 409, "Walk-in booking cannot overlap maintenance");
using (var db = Context())
{
    var u = Uow(db);
    var apiBooking = new SportSpot.Services.Implementations.BookingService(u, new TicketService(u));
    Check((await apiBooking.CreateBookingAsync(new() { UserId = 1, SubVenueId = 1, PlayDate = day, SlotIds = new() { 10 } })).StatusCode == 409,
        "App booking shares database conflict protection with maintenance");
}
Check((await OwnerRun(s => s.Cancel(6, blockId, false))).StatusCode == 403, "Other owner cannot unblock hours");
Check((await OwnerRun(s => s.Cancel(5, blockId, false))).Success, "Cancel maintenance frees slot");
var walkin = Manual(1, new() { 10 }); walkin.CollectedAmount = 100000;
Check((await OwnerRun(s => s.Create(7, walkin))).Success, "Assigned receptionist creates walk-in with cash collection");
int walkinId;
using (var db = Context())
{
    var b = await db.Bookings.Include(b => b.Transactions).SingleAsync(b => b.BookingType == "WalkIn"); walkinId = b.Id;
    Check(b.TotalPrice == 500000 && b.RemainingBalance == 400000 && b.Transactions.Single().Status == "Settled", "Cash is settled and remaining amount correct");
    var u = Uow(db);
    Check((await new TicketService(u).CancelTicketWithTieredRefundAsync(walkinId, 7)).StatusCode == 409, "Cash booking cannot mint a wallet refund through ticket endpoint");
}
Check((await OwnerRun(s => s.Collect(5, walkinId, 400001))).StatusCode == 400, "Overcollection denied");
Check((await OwnerRun(s => s.Collect(5, walkinId, 150000))).Success, "Partial cash collection supported");
Check((await OwnerRun(s => s.Cancel(5, walkinId, false))).StatusCode == 409, "Paid cash cancellation needs refund acknowledgement");
Check((await OwnerRun(s => s.Cancel(5, walkinId, true))).Success, "Acknowledged cash cancellation releases slot");
using (var db = Context())
{
    Check(await db.Transactions.Where(t => t.BookingId == walkinId).SumAsync(t => t.Amount) == 0, "Cash return is audited and offsets collected cash");
    Check(!await db.BookingDetails.AnyAsync(d => d.BookingId == walkinId && d.Status != "Cancelled"), "Cancelled manual booking releases all slot locks");
}
Check((await OwnerRun(s => s.Prices(7, 1, new() { BasePrice = 200000, PeakPrice = 400000 }))).StatusCode == 403, "Staff cannot change prices");
Check((await OwnerRun(s => s.Prices(5, 1, new() { BasePrice = 350000, PeakPrice = 550000 }))).Success, "Owner can update standard and peak prices");
using (var db = Context()) Check((await db.Bookings.FindAsync(walkinId))!.TotalPrice == 500000, "Existing booking retains original price");

var teamA = (await TeamRun(s => s.CreateTeam(1, new() { Name = "Team A", TeamSize = 7 }))).Data!.Id;
var teamB = (await TeamRun(s => s.CreateTeam(2, new() { Name = "Team B", TeamSize = 7 }))).Data!.Id;
var teamC = (await TeamRun(s => s.CreateTeam(3, new() { Name = "Team C", TeamSize = 7 }))).Data!.Id;
var team5 = (await TeamRun(s => s.CreateTeam(4, new() { Name = "Team 5", TeamSize = 5 }))).Data!.Id;
Check((await TeamRun(s => s.CreateTeam(1, new() { Name = "Invalid", TeamSize = 6 }))).StatusCode == 400, "Unsupported team size rejected");
Check((await TeamRun(s => s.MyTeams(2))).Data!.Single().Id == teamB, "My teams does not expose other captains' teams");
async Task<int> Booking(int userId, int courtId, int slotId = 10)
{
    using var db = Context(); var u = Uow(db);
    var r = await new SportSpot.Services.Implementations.BookingService(u, new TicketService(u)).CreateBookingAsync(
        new() { UserId = userId, SubVenueId = courtId, PlayDate = day, SlotIds = new() { slotId } });
    Check(r.Success, $"Create booking for player {userId}, court {courtId}"); return r.Data!.BookingId;
}
var bookingA = await Booking(1, 1);
var bookingOther = await Booking(2, 2);
Check((await TeamRun(s => s.CreateChallenge(2, new() { TeamId = teamA, BookingId = bookingA }))).StatusCode == 403, "Cannot open challenge on another captain's team");
Check((await TeamRun(s => s.CreateChallenge(1, new() { TeamId = teamA, BookingId = bookingOther }))).StatusCode == 403, "Cannot use another user's booking");
Check((await TeamRun(s => s.CreateChallenge(1, new() { TeamId = teamA, BookingId = bookingA, Note = "Friendly match" }))).Success, "Captain opens opponent search from own booking");
Check((await TeamRun(s => s.CreateChallenge(1, new() { TeamId = teamA, BookingId = bookingA }))).StatusCode == 409, "Duplicate challenge for booking rejected");
var challengeId = (await TeamRun(s => s.List(1, true))).Data!.Single().Id;
Check((await TeamRun(s => s.Apply(1, challengeId, new() { TeamId = teamA }))).StatusCode == 400, "Cannot challenge own team");
Check((await TeamRun(s => s.Apply(4, challengeId, new() { TeamId = team5 }))).StatusCode == 400, "Team sizes must match");
Check((await TeamRun(s => s.Apply(3, challengeId, new() { TeamId = teamB }))).StatusCode == 403, "Only captain can apply for team");
Check((await TeamRun(s => s.Apply(2, challengeId, new() { TeamId = teamB, Message = "Ready to play" }))).Success, "Opponent submits request");
Check((await TeamRun(s => s.Apply(2, challengeId, new() { TeamId = teamB }))).StatusCode == 409, "Duplicate application rejected");
Check((await TeamRun(s => s.Apply(3, challengeId, new() { TeamId = teamC }))).Success, "Second opponent may apply while search remains open");
var host = (await TeamRun(s => s.List(1, true))).Data!.Single();
var reqB = host.Requests.Single(r => r.Team.Id == teamB).Id;
var reqC = host.Requests.Single(r => r.Team.Id == teamC).Id;
Check((await TeamRun(s => s.List(4, false))).Data!.Single().Requests.Count == 0, "Public feed hides pending private applications");
Check((await TeamRun(s => s.Decide(3, challengeId, reqB, true))).StatusCode == 403, "Opponent cannot approve applications");
Check((await TeamRun(s => s.Decide(1, challengeId, reqB, true))).Success, "Host accepts one opponent");
host = (await TeamRun(s => s.List(1, true))).Data!.Single();
Check(host.Status == "Matched" && host.Requests.Single(r => r.Id == reqC).Status == "Rejected", "Accepting one team closes others atomically");
Check((await TeamRun(s => s.Decide(1, challengeId, reqC, true))).StatusCode == 409, "Cannot accept a second team");
Check(host.ContactPhone == "0900000002", "Matched host gets opponent captain contact");
Check((await TeamRun(s => s.List(2, true))).Data!.Single().ContactPhone == "0900000001", "Accepted opponent gets host captain contact");
Check((await TeamRun(s => s.List(3, true))).Data!.Single().ContactPhone == null, "Rejected applicant does not see captain phone");
Check((await TeamRun(s => s.List(0, false))).Data!.Count == 0, "Matched challenge removed from open feed");
Check((await TeamRun(s => s.CreateChallenge(2, new() { TeamId = teamB, BookingId = bookingOther }))).StatusCode == 409,
    "Accepted opponent cannot open another simultaneous match on another court");
Check((await TeamRun(s => s.Withdraw(3, challengeId, reqB))).StatusCode == 403, "Other captain cannot withdraw someone else's request");
Check((await TeamRun(s => s.Withdraw(2, challengeId, reqB))).Success, "Accepted opponent can withdraw before match starts");
Check((await TeamRun(s => s.List(0, false))).Data!.Single().Status == "Open", "Opponent withdrawal reopens search");
Check((await TeamRun(s => s.Apply(2, challengeId, new() { TeamId = teamB }))).Success, "Withdrawn team can apply again");
using (var db = Context())
{
    var u = Uow(db);
    Check((await new MatchService(u, db).CreateMatchAsync(1, new() { BookingId = bookingA, TotalExpectedPlayers = 14, NeededPlayers = 2 })).StatusCode == 409,
        "Team challenge booking cannot also recruit individual players");
    Check((await new TicketService(u).CancelTicketWithTieredRefundAsync(bookingA, 1)).Success, "Host cancels underlying booking through existing refund flow");
}
using (var db = Context())
{
    Check((await db.TeamChallenges.FindAsync(challengeId))!.Status == "Cancelled", "Booking cancellation closes linked team challenge");
    Check(!await db.TeamChallengeRequests.AnyAsync(r => r.TeamChallengeId == challengeId && (r.Status == "Pending" || r.Status == "Accepted")), "Booking cancellation closes active requests");
    Check(await db.Notifications.CountAsync() >= 5, "Team workflow records notifications for captains");
}
Check((await TeamRun(s => s.Apply(3, challengeId, new() { TeamId = teamC }))).StatusCode == 409, "Cannot apply to cancelled booking");

Check((await TeamRun(s => s.CreateChallenge(2, new() { TeamId = teamB, BookingId = bookingOther }))).Success, "Cancelled match no longer blocks opponent schedule");
var otherChallenge = (await TeamRun(s => s.List(2, true))).Data!.Single(c => c.BookingId == bookingOther).Id;
Check((await TeamRun(s => s.Apply(3, otherChallenge, new() { TeamId = teamC }))).Success, "Apply before closing opponent search");
Check((await TeamRun(s => s.Cancel(2, otherChallenge))).Success, "Host can close search without cancelling booking");
Check((await TeamRun(s => s.CreateChallenge(2, new() { TeamId = teamB, BookingId = bookingOther }))).Success, "Host can reopen search on the same booking");
Check((await TeamRun(s => s.Apply(3, otherChallenge, new() { TeamId = teamC }))).Success, "Cancelled application can be renewed when host reopens search");
using (var first = Context())
using (var stale = Context())
{
    var a = await first.TeamChallenges.FindAsync(otherChallenge);
    var b = await stale.TeamChallenges.FindAsync(otherChallenge);
    a!.Revision++; a.Note = "First change"; await first.SaveChangesAsync();
    b!.Revision++; b.Note = "Stale change";
    var conflict = false;
    try { await stale.SaveChangesAsync(); } catch (DbUpdateConcurrencyException) { conflict = true; }
    Check(conflict, "Database rejects stale challenge revision instead of overwriting newer decisions");
}
var paid = Manual(1, new() { 11 }); paid.CollectedAmount = 550000;
Check((await OwnerRun(s => s.Create(5, paid))).Success, "Create fully paid walk-in booking");
int paidId;
using (var db = Context()) paidId = await db.Bookings.Where(b => b.BookingType == "WalkIn" && b.Status == "Upcoming").Select(b => b.Id).SingleAsync();
Check((await OwnerRun(s => s.Complete(5, paidId))).StatusCode == 409, "Cannot complete before rental ends");
using (var db = Context())
{
    var b = await db.Bookings.Include(b => b.BookingDetails).SingleAsync(b => b.Id == paidId);
    b.PlayDate = day.AddDays(-4); foreach (var d in b.BookingDetails) d.PlayDate = b.PlayDate;
    await db.SaveChangesAsync();
}
Check((await OwnerRun(s => s.Cancel(5, paidId, true))).StatusCode == 409, "Cannot cancel a walk-in booking after play starts");
Check((await OwnerRun(s => s.Complete(6, paidId))).StatusCode == 403, "Other owner cannot complete rental");
Check((await OwnerRun(s => s.Complete(5, paidId))).Success, "Owner completes paid rental after play ends");
Check((await OwnerRun(s => s.Collect(5, paidId, 1))).StatusCode == 400, "Completed booking cannot collect additional cash");

// =========================================================================
// NEW FLOW TESTS: Venue Registration (Images + Slots) -> Admin Review -> Owner Config Dashboard
// =========================================================================
var fakePng = new byte[] { 137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82 };
using (var db = Context())
{
    var storage = new FakeImageStorage();
    var appSvc = new VenueApplicationService(db, storage);
    var adminSvc = new AdminService(db, appSvc);
    var scheduleSvc = new OwnerScheduleService(db);
    var configSvc = new OwnerConfigService(db, scheduleSvc);

    // 1. Upload 2 images by Player #3
    var up1 = await appSvc.Upload(3, fakePng);
    var up2 = await appSvc.Upload(3, fakePng);
    Check(up1.Success && up2.Success, "Player uploads venue photos via Cloudinary storage");

    var templates = await appSvc.SlotTemplates();
    Check(templates.Success && templates.Data!.Count == 19, "SlotTemplates returns all 19 hourly slots (05:00-23:59)");

    // 2. Submit new venue application with 16 active slots, MaxSlotsPerBooking=4, MinDepositPercent=50, and initial service
    var submitReq = new SubmitVenueRequest
    {
        Name = "Cụm Sân Pickleball Phú Nhuận Pro",
        SportId = 2,
        Address = "128 Nguyễn Trọng Tuyển, Phú Nhuận",
        District = "Phú Nhuận",
        Hotline = "0909112233",
        Latitude = 10.799m,
        Longitude = 106.678m,
        BasePrice = 140000,
        PeakPrice = 210000,
        MaxSlotsPerBooking = 4,
        MinDepositPercent = 50,
        Description = "Sân có mái che thoáng mát",
        Amenities = "Wifi, Bãi xe, Căn tin",
        CourtNames = new() { "Sân Pickle 1", "Sân Pickle 2" },
        ImageIds = new() { up1.Data!.Id, up2.Data!.Id },
        SlotConfigs = templates.Data!.Take(16).Select(t => new SlotConfigItemInput
        {
            SlotId = t.SlotId,
            IsActive = true,
            IsPeak = t.IsPeak,
            CustomPrice = t.SlotId == 14 ? 120000 : null
        }).ToList(),
        Services = new()
        {
            new InitialServiceInput { Name = "Thuê vợt Carbon", Type = "Rental", Price = 40000, StockQuantity = 5 }
        }
    };
    var submitted = await appSvc.Submit(3, submitReq);
    Check(submitted.Success && submitted.Data!.Status == "Pending" && submitted.Data.ActiveSlotCount == 16,
        "Player submits venue application with custom 16-slot schedule and policies");

    var appId = submitted.Data!.Id;

    Check(!submitted.Data.IsActive, "Pending application is inactive");
    Check(await new VenueRepository(db).GetVenueDetailByIdAsync(appId) == null,
        "Pending application is hidden from public venue details");
    var pendingCourtId = await db.SubVenues.Where(s => s.VenueId == appId).Select(s => s.Id).FirstAsync();
    Check(await new BookingRepository(db).GetActiveSubVenueWithVenueAsync(pendingCourtId) == null,
        "Pending venue cannot accept app bookings");
    Check((await appSvc.Submit(3, submitReq, appId)).StatusCode == 409,
        "Applicant cannot edit a pending application");
    Check((await appSvc.Submit(2, submitReq)).StatusCode == 400,
        "Applicant cannot use another user's uploaded images");
    Check((await adminSvc.Review(3, appId, new() { Approve = true, Revision = submitted.Data.Revision })).StatusCode == 403,
        "Applicant cannot approve own application");

    // 3. Admin rejects without reason -> 400; rejects with reason -> Rejected
    Check((await adminSvc.Review(8, appId, new() { Approve = false, Reason = "", Revision = submitted.Data.Revision })).StatusCode == 400,
        "Admin rejection requires reason");
    var rejected = await adminSvc.Review(8, appId, new() { Approve = false, Reason = "Bổ sung ảnh mặt tiền rõ hơn", Revision = submitted.Data.Revision });
    Check(rejected.Success && rejected.Data!.Status == "Rejected", "Admin rejects venue application with feedback");
    Check((await appSvc.Submit(2, submitReq, appId)).StatusCode == 404,
        "Other applicant cannot edit rejected application");
    Check((await appSvc.Submit(3, submitReq, appId)).StatusCode == 409,
        "Rejected application cannot be resubmitted with stale revision");

    // 4. Player edits & resubmits rejected application -> Pending -> Admin approves -> Player upgraded to Owner!
    submitReq.Revision = rejected.Data!.Revision;
    submitReq.Description = "Đã cập nhật ảnh mặt tiền và mái che";
    var resubmitted = await appSvc.Submit(3, submitReq, appId);
    Check(resubmitted.Success && resubmitted.Data!.Status == "Pending", "Applicant resubmits rejected application");
    Check((await adminSvc.Review(8, appId, new() { Approve = true, Revision = submitted.Data.Revision })).StatusCode == 409,
        "Admin cannot approve a stale version after resubmission");

    var approved = await adminSvc.Review(8, appId, new() { Approve = true, Reason = "Đạt chuẩn", Revision = resubmitted.Data.Revision });
    Check(approved.Success && approved.Data!.Status == "Approved" && approved.Data.IsActive, "Admin approves resubmitted venue");
    Check(await new VenueRepository(db).GetVenueDetailByIdAsync(appId) != null,
        "Approved venue is visible in public venue details");
    Check((await adminSvc.Review(8, appId, new() { Approve = true, Revision = approved.Data!.Revision })).StatusCode == 409,
        "Admin cannot approve the same application twice");
    Check(await db.VenueModerationLogs.CountAsync(l => l.VenueId == appId) == 2,
        "Only successful rejection and approval create moderation history");

    var upgradedOwner = await db.Users.FindAsync(3);
    Check(upgradedOwner!.Role == "Owner" && upgradedOwner.StaffVenueId == appId, "Approved applicant is automatically upgraded to Owner role");

    // 5. Owner Config Dashboard: inspect & update slots, SubVenues, Services, and VenueStaff
    var cfg = await configSvc.GetConfig(3, appId);
    Check(cfg.Success && cfg.Data!.ActiveSlotCount == 16 && cfg.Data.Services.Count == 1, "Owner retrieves full venue configuration");

    var addedCourt = await configSvc.AddSubVenue(3, appId, new() { Name = "Sân Pickle 3", IsActive = true });
    Check(addedCourt.Success && addedCourt.Data!.Name == "Sân Pickle 3", "Owner adds SubVenue");

    var addedSvc = await configSvc.AddService(3, appId, new() { Name = "Nước điện giải", Type = "Sale", Price = 20000, StockQuantity = 10 });
    Check(addedSvc.Success, "Owner adds auxiliary service with stock");

    var assignedStaff = await configSvc.AssignStaff(3, appId, new() { Identifier = "0900000004" });
    Check(assignedStaff.Success && (await db.Users.FindAsync(4))!.Role == "VenueStaff", "Owner assigns Player #4 as VenueStaff");

    // 6. Booking enforces custom slot price (Slot 14 = 120,000), MinDepositPercent=50%, deducts stock, and settles 95% net payout on QR check-in
    var uow = Uow(db);
    var ticketSvc = new TicketService(uow);
    var bookingSvc = new SportSpot.Services.Implementations.BookingService(uow, ticketSvc);
    var venueSvc = new VenueService(uow);

    var publicSlots = await venueSvc.GetVenueTimeSlotsAsync(appId, addedCourt.Data.Id, day);
    Check(publicSlots.Success && publicSlots.Data!.Count == 16 && publicSlots.Data.First(s => s.SlotId == 14).Price == 120000,
        "Public venue slots reflect owner's 16 active slots and custom early-bird slot price");

    var bookRes = await bookingSvc.CreateBookingAsync(new()
    {
        UserId = 1,
        SubVenueId = addedCourt.Data.Id,
        PlayDate = day,
        SlotIds = new() { 14 }, // 05:00-06:00 custom price 120,000
        DepositPercentage = 30, // Venue MinDepositPercent is 50 -> automatically raised to 50%!
        Services = new() { new() { ServiceId = addedSvc.Data!.Id, Quantity = 2 } } // +40,000 -> total 160,000 -> 50% deposit = 80,000
    });
    Check(bookRes.Success && bookRes.Data!.TotalPrice == 160000 && bookRes.Data.DepositAmount == 80000,
        "Booking applies custom slot price and enforces venue MinDepositPercent (50%)");
    Check((await db.Services.FindAsync(addedSvc.Data.Id))!.StockQuantity == 8, "Service stock quantity deducted upon booking");

    // Desk cash collection on App Standard booking for remaining 80,000 VND
    var collectAppRes = await scheduleSvc.Collect(4, bookRes.Data.BookingId, 80000);
    Check(collectAppRes.Success, "Assigned VenueStaff collects remaining cash balance on App booking");

    // Check-in QR settles Holding escrow and credits 95% net payout (76,000 VND) to Owner #3 WalletBalance
    var ownerBalanceBefore = (await db.Users.FindAsync(3))!.WalletBalance;
    var checkInRes = await ticketSvc.VerifyQrAndSettleEscrowAsync(new() { QrPayload = bookRes.Data.QrPayload });
    Check(checkInRes.Success && (await db.Users.FindAsync(3))!.WalletBalance == ownerBalanceBefore + 76000,
        "QR check-in settles Escrow and credits 95% net payout to Owner wallet");

    // Cancel another booking restores service stock
    var bookToCancel = await bookingSvc.CreateBookingAsync(new()
    {
        UserId = 1,
        SubVenueId = addedCourt.Data.Id,
        PlayDate = day,
        SlotIds = new() { 1 },
        Services = new() { new() { ServiceId = addedSvc.Data.Id, Quantity = 3 } }
    });
    Check(bookToCancel.Success && (await db.Services.FindAsync(addedSvc.Data.Id))!.StockQuantity == 5, "Second booking deducts stock to 5");
    Check((await ticketSvc.CancelTicketWithTieredRefundAsync(bookToCancel.Data!.BookingId, 1)).Success
        && (await db.Services.FindAsync(addedSvc.Data.Id))!.StockQuantity == 8, "Cancelling booking restores service stock to 8");

    // Remove staff & delete unused subvenue
    Check((await configSvc.RemoveStaff(3, appId, 4)).Success && (await db.Users.FindAsync(4))!.Role == "Player", "Owner removes VenueStaff");
}

Console.WriteLine($"All {count} checks passed.");

class FakeImageStorage : SportSpot.Services.Interfaces.IVenueImageStorage
{
    private int _seq;
    public Task<SportSpot.Services.Interfaces.StoredVenueImage> UploadAsync(byte[] bytes, string contentType, CancellationToken ct = default)
    {
        var id = Interlocked.Increment(ref _seq);
        return Task.FromResult(new SportSpot.Services.Interfaces.StoredVenueImage(
            $"https://res.cloudinary.com/demo/image/upload/v1/sportspot/test_{id}.png",
            $"sportspot/test_{id}"));
    }
}
