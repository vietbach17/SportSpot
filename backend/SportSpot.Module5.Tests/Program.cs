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
UnitOfWork Uow(SportSpotDbContext db) => new(
    db,
    new UserRepository(db),
    new SportRepository(db),
    new VenueRepository(db),
    new BookingRepository(db),
    new MatchRepository(db),
    new TransactionRepository(db));

var passed = 0;
void Check(bool condition, string label)
{
    if (!condition) throw new Exception($"FAIL: {label}");
    passed++;
    Console.WriteLine($"PASS: {label}");
}

using (var db = Context())
{
    db.Database.EnsureCreated();
    SqliteModule4Upgrade.Apply(db);
    db.Venues.Add(new Venue
    {
        Id = 1,
        SportId = 1,
        Name = "CLB Cầu Lông Cầu Giấy",
        Address = "35 Trần Quý Kiên, Cầu Giấy",
        District = "Cầu Giấy",
        BasePrice = 100000,
        PeakPrice = 150000,
        IsActive = true
    });
    db.SubVenues.Add(new SubVenue { Id = 1, VenueId = 1, Name = "Sân Số 1 (Thảm Yonex)", IsActive = true });
    db.Users.AddRange(
        new User { Id = 1, PhoneNumber = "0901111111", FullName = "Đội Trưởng Minh", Role = "Player", WalletBalance = 0 },
        new User { Id = 2, PhoneNumber = "0902222222", FullName = "Vãng Lai Hùng", Role = "Player", WalletBalance = 0 }
    );
    db.SaveChanges();
}

// 1. Test QrChecksumHelper SHA-256 signing & tamper detection
var signedQr = QrChecksumHelper.BuildSignedQrPayload("SP-999999", 1, "Host");
Check(QrChecksumHelper.ValidateSignedQrPayload(signedQr, out var code, out var uid, out var role)
      && code == "SP-999999" && uid == 1 && role == "Host",
      "SHA-256 QR Payload signing and validation");

var tamperedQr = signedQr[..^1] + (signedQr[^1] == 'A' ? 'B' : 'A');
Check(!QrChecksumHelper.ValidateSignedQrPayload(tamperedQr, out _, out _, out _),
      "Tampered QR Payload is rejected by SHA-256 Checksum");

// 2. Test PaymentService: CreatePaymentIntent -> Holding, ProcessWebhook -> Holding, MockInstantPay
int bookingCheckInId;
string bookingCheckInCode;
using (var db = Context())
{
    var uow = Uow(db);
    var bookingSvc = new SportSpot.Services.Implementations.BookingService(uow, new TicketService(uow));
    var created = await bookingSvc.CreateBookingAsync(new CreateBookingRequest
    {
        UserId = 1,
        SubVenueId = 1,
        PlayDate = DateOnly.FromDateTime(MatchRules.VietnamNow).AddDays(2),
        SlotIds = new() { 10, 11 }, // 2 peak slots -> 300,000 VND
        DepositPercentage = 50
    });
    Check(created.Success && created.Data != null, "Create booking for payment & check-in flow");
    bookingCheckInId = created.Data!.BookingId;
    bookingCheckInCode = created.Data.BookingCode;

    var paymentSvc = new PaymentService(uow);
    var intentRes = await paymentSvc.CreatePaymentIntentAsync(new CreatePaymentIntentRequest
    {
        BookingId = bookingCheckInId,
        UserId = 1,
        Amount = 150000,
        PaymentGateway = "VNPay"
    });
    Check(intentRes.Success && intentRes.Data!.EscrowStatus == "Holding", "CreatePaymentIntent creates Holding escrow transaction");

    var webhookRes = await paymentSvc.ProcessWebhookAsync(new PaymentWebhookRequest
    {
        TransactionCode = intentRes.Data!.TransactionCode,
        IsSuccess = true
    });
    Check(webhookRes.Success, "ProcessWebhook confirms Holding escrow status");

    var mockRes = await paymentSvc.MockInstantPayAsync(bookingCheckInCode);
    Check(mockRes.Success && !string.IsNullOrEmpty(mockRes.Data!.QrPayload), "MockInstantPay returns signed QR payload");
}

// 3. Test TicketService: VerifyQrAndSettleEscrowAsync (Holding -> Settled) + Duplicate Check-in rejection
using (var db = Context())
{
    var uow = Uow(db);
    var ticketSvc = new TicketService(uow);
    var myTickets = await ticketSvc.GetMyTicketsAsync(1);
    Check(myTickets.Success && myTickets.Data!.Count == 1 && myTickets.Data[0].EscrowStatus == "Holding",
          "GetMyTickets returns Host ticket with Holding escrow status");

    var qrToScan = myTickets.Data![0].QrPayload;
    var badScan = await ticketSvc.VerifyQrAndSettleEscrowAsync(new CheckInRequest { QrPayload = qrToScan + "X" });
    Check(!badScan.Success, "VerifyQr rejects tampered QR checksum");

    var goodScan = await ticketSvc.VerifyQrAndSettleEscrowAsync(new CheckInRequest { QrPayload = qrToScan });
    Check(goodScan.Success, "VerifyQr succeeds and settles Escrow to venue owner");

    var dupScan = await ticketSvc.VerifyQrAndSettleEscrowAsync(new CheckInRequest { QrPayload = qrToScan });
    Check(!dupScan.Success, "Duplicate QR check-in is rejected");

    var settledTxs = await db.Transactions.Where(t => t.BookingId == bookingCheckInId).ToListAsync();
    Check(settledTxs.All(t => t.Status == "Settled"), "All Holding transactions transitioned to Settled after check-in");
}

// Helper to create a booking at an exact offset (in hours) from MatchRules.VietnamNow
async Task<int> CreateBookingAtOffsetHoursAsync(string codeSuffix, int depositAmount)
{
    using var db = Context();
    var targetTime = MatchRules.VietnamNow.AddHours(double.Parse(codeSuffix));
    var playDate = DateOnly.FromDateTime(targetTime);
    var slotTime = targetTime.ToString("HH:mm");

    var slot = new TimeSlot { StartTime = slotTime, EndTime = targetTime.AddHours(1).ToString("HH:mm"), IsPeak = true };
    db.TimeSlots.Add(slot);
    await db.SaveChangesAsync();

    var booking = new Booking
    {
        BookingCode = $"SP-T{Guid.NewGuid():N}"[..10].ToUpper(),
        UserId = 1,
        SubVenueId = 1,
        PlayDate = playDate,
        CourtPrice = depositAmount * 2,
        TotalPrice = depositAmount * 2,
        DepositAmount = depositAmount,
        RemainingBalance = depositAmount,
        Status = "Upcoming"
    };
    db.Bookings.Add(booking);
    await db.SaveChangesAsync();

    db.BookingDetails.Add(new BookingDetail
    {
        BookingId = booking.Id,
        SubVenueId = 1,
        PlayDate = playDate,
        SlotId = slot.Id,
        Price = depositAmount * 2,
        Status = "Booked"
    });
    db.Transactions.Add(new Transaction
    {
        BookingId = booking.Id,
        UserId = 1,
        Amount = depositAmount,
        PaymentGateway = "VNPay",
        TransactionCode = $"TXN-{Guid.NewGuid():N}"[..14].ToUpper(),
        Status = "Holding"
    });
    await db.SaveChangesAsync();
    return booking.Id;
}

// 4. Test Tiered Cancellation Policy:
// Tier 1 (>= 4h): 100% refund
var bTier1 = await CreateBookingAtOffsetHoursAsync("6", 200000);
using (var db = Context())
{
    var res = await new TicketService(Uow(db)).CancelTicketWithTieredRefundAsync(bTier1, 1);
    Check(res.Success && res.Data!.RefundPercentage == 100 && res.Data.RefundAmount == 200000 && res.Data.PenaltyAmount == 0,
          "Tier 1 (>= 4h): 100% deposit refunded (200,000 VND)");
    Check(res.Data!.NewWalletBalance == 200000, "User wallet credited with 200,000 VND");
}

// Tier 2 (2h - 4h): 50% refund, 50% penalty
var bTier2 = await CreateBookingAtOffsetHoursAsync("3", 200000);
using (var db = Context())
{
    var res = await new TicketService(Uow(db)).CancelTicketWithTieredRefundAsync(bTier2, 1);
    Check(res.Success && res.Data!.RefundPercentage == 50 && res.Data.RefundAmount == 100000 && res.Data.PenaltyAmount == 100000,
          "Tier 2 (2h - 4h): 50% deposit refunded (100,000 VND), 50% penalty (100,000 VND)");
    Check(res.Data!.NewWalletBalance == 300000, "User wallet credited to 300,000 VND total");
}

// Tier 3 (< 2h): 0% refund, 100% penalty
var bTier3 = await CreateBookingAtOffsetHoursAsync("1", 200000);
using (var db = Context())
{
    var res = await new TicketService(Uow(db)).CancelTicketWithTieredRefundAsync(bTier3, 1);
    Check(res.Success && res.Data!.RefundPercentage == 0 && res.Data.RefundAmount == 0 && res.Data.PenaltyAmount == 200000,
          "Tier 3 (< 2h): 0% refunded, 100% penalty (200,000 VND)");
    Check(res.Data!.NewWalletBalance == 300000, "User wallet unchanged at 300,000 VND");
}

// 5. Test Paying with refunded WalletBalance
using (var db = Context())
{
    var uow = Uow(db);
    var paymentSvc = new PaymentService(uow);
    var bWallet = await CreateBookingAtOffsetHoursAsync("8", 120000);
    var walletPay = await paymentSvc.CreatePaymentIntentAsync(new CreatePaymentIntentRequest
    {
        BookingId = bWallet,
        UserId = 1,
        Amount = 120000,
        PaymentGateway = "Wallet"
    });
    Check(walletPay.Success, "Pay deposit using refunded WalletBalance");
    var hist = await paymentSvc.GetUserTransactionsAsync(1);
    Check(hist.Success && hist.Data!.WalletBalance == 180000, "WalletBalance deducted accurately (300k - 120k = 180k)");
}

// 6. Test Slot Release upon Booking Cancellation
using (var db = Context())
{
    var uow = Uow(db);
    var bookingSvc = new SportSpot.Services.Implementations.BookingService(uow, new TicketService(uow));
    var playDate = DateOnly.FromDateTime(MatchRules.VietnamNow).AddDays(2);
    // Booking 1 for slot 1
    var createRes = await bookingSvc.CreateBookingAsync(new CreateBookingRequest
    {
        UserId = 1,
        SubVenueId = 1,
        PlayDate = playDate,
        SlotIds = new List<int> { 1 }
    });
    Check(createRes.Success, "Booking slot 1 succeeds");
    var bookingId = createRes.Data!.BookingId;

    // Competing booking for same slot fails with conflict
    var conflictRes = await bookingSvc.CreateBookingAsync(new CreateBookingRequest
    {
        UserId = 2,
        SubVenueId = 1,
        PlayDate = playDate,
        SlotIds = new List<int> { 1 }
    });
    Check(!conflictRes.Success, "Conflicting booking for same slot rejected");

    // Cancel booking 1
    var cancelRes = await bookingSvc.CancelBookingAsync(bookingId, 1);
    Check(cancelRes.Success, "Cancel booking 1 succeeds");

    // After cancellation, slot 1 is released and booking succeeds!
    var rebookRes = await bookingSvc.CreateBookingAsync(new CreateBookingRequest
    {
        UserId = 2,
        SubVenueId = 1,
        PlayDate = playDate,
        SlotIds = new List<int> { 1 }
    });
    Check(rebookRes.Success, "Released slot rebooked successfully after cancellation");
}

// 7. Test Reviews & Average Rating calculation
using (var db = Context())
{
    var reviewSvc = new ReviewService(db);
    var rev1 = await reviewSvc.CreateReviewAsync(1, new CreateReviewRequest
    {
        VenueId = 1,
        Rating = 5,
        Comment = "Sân chất lượng cao, thảm êm!"
    });
    Check(rev1.Success && rev1.Data!.Rating == 5, "Create review 5-star succeeds");

    var rev2 = await reviewSvc.CreateReviewAsync(2, new CreateReviewRequest
    {
        VenueId = 1,
        Rating = 3,
        Comment = "Sân ổn nhưng hơi đông vào giờ cao điểm"
    });
    Check(rev2.Success && rev2.Data!.Rating == 3, "Create review 3-star succeeds");

    var summary = await reviewSvc.GetVenueReviewsAsync(1);
    Check(summary.Success && summary.Data!.TotalReviews == 2 && summary.Data.AverageRating == 4.0m,
          "Venue average rating accurately computed ( (5+3)/2 = 4.0 )");
    Check(summary.Data!.RatingBreakdown[5] == 1 && summary.Data.RatingBreakdown[3] == 1,
          "Review breakdown contains correct star counts");
}

// 8. Test Owner Dashboard & SubVenue Toggle
using (var db = Context())
{
    var ownerSvc = new OwnerService(db);
    var dash = await ownerSvc.GetOwnerDashboardAsync(1);
    Check(dash.Success && dash.Data!.VenueId == 1 && dash.Data.TotalBookings > 0,
          "Owner dashboard statistics retrieved with non-zero bookings");
    Check(dash.Data!.DailyRevenues.Count == 7, "Daily revenue spans past 7 days");
    Check(dash.Data!.SubVenues.Count > 0, "Owner dashboard lists subvenues");

    var subVenueId = dash.Data!.SubVenues.First().Id;
    var toggleRes = await ownerSvc.ToggleSubVenueStatusAsync(subVenueId, false);
    Check(toggleRes.Success && !toggleRes.Data, "Subvenue toggled to inactive (maintenance)");

    var toggleBack = await ownerSvc.ToggleSubVenueStatusAsync(subVenueId, true);
    Check(toggleBack.Success && toggleBack.Data, "Subvenue toggled back to active");
}

// 9. Test Top-Up Wallet
using (var db = Context())
{
    var uow = Uow(db);
    var paymentSvc = new PaymentService(uow);
    var topupRes = await paymentSvc.TopUpWalletAsync(new TopUpWalletRequest
    {
        UserId = 1,
        Amount = 200000,
        PaymentGateway = "VNPay"
    });
    Check(topupRes.Success && topupRes.Data!.WalletBalance >= 200000, "Wallet top-up succeeds and updates balance");
    Check(topupRes.Data!.Transactions.Any(t => t.TransactionCode.StartsWith("TOPUP")), "TopUp transaction recorded");
}

// 10. Test Notifications System
using (var db = Context())
{
    db.Notifications.Add(new Notification
    {
        UserId = 1,
        Title = "Nhắc lịch test",
        Message = "Còn 2 tiếng nữa đến giờ ra sân",
        Type = "Reminder",
        IsRead = false,
        CreatedAt = DateTime.UtcNow
    });
    await db.SaveChangesAsync();

    var notifSvc = new NotificationService(db);
    var summary = await notifSvc.GetNotificationsAsync(1);
    Check(summary.Success && summary.Data!.UnreadCount > 0, "Retrieve unread notifications succeeds");

    var firstNotif = summary.Data!.Notifications.First(n => !n.IsRead);
    var markRes = await notifSvc.MarkAsReadAsync(firstNotif.Id, 1);
    Check(markRes.Success, "Mark notification as read succeeds");

    var markAllRes = await notifSvc.MarkAllAsReadAsync(1);
    Check(markAllRes.Success, "Mark all notifications as read succeeds");
}

// 11. Test Favorite Venues Toggle
using (var db = Context())
{
    db.FavoriteVenues.Add(new FavoriteVenue
    {
        UserId = 1,
        VenueId = 1,
        CreatedAt = DateTime.UtcNow
    });
    await db.SaveChangesAsync();

    var hasFav = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.AnyAsync(
        db.FavoriteVenues, f => f.UserId == 1 && f.VenueId == 1
    );
    Check(hasFav, "Venue marked as favorite");

    var existing = await db.FavoriteVenues.FirstAsync(f => f.UserId == 1 && f.VenueId == 1);
    db.FavoriteVenues.Remove(existing);
    await db.SaveChangesAsync();

    var unFav = !await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.AnyAsync(
        db.FavoriteVenues, f => f.UserId == 1 && f.VenueId == 1
    );
    Check(unFav, "Venue unfavorited successfully");
}

// 12. Test Match Comments & Discussion
using (var db = Context())
{
    var booking = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.FirstAsync(db.Bookings);
    var match = new OpenMatch
    {
        BookingId = booking.Id,
        HostUserId = 1,
        TotalExpectedPlayers = 4,
        NeededPlayers = 2,
        CostPerPerson = 50000,
        Status = "Open",
        SkillLevel = "Cơ bản",
        CreatedAt = DateTime.UtcNow
    };
    db.OpenMatches.Add(match);
    await db.SaveChangesAsync();

    db.MatchComments.Add(new MatchComment
    {
        MatchId = match.Id,
        UserId = 1,
        Content = "Anh em nhớ mang giày sân thảm nhé!",
        CreatedAt = DateTime.UtcNow
    });
    await db.SaveChangesAsync();

    var comments = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.ToListAsync(
        db.MatchComments.Where(c => c.MatchId == match.Id)
    );
    Check(comments.Count > 0 && comments.First().Content.Contains("giày sân thảm"), "Match discussion comment saved and retrieved");
}


// 12. Test FCM Push Service (Token & Push notifications)
using (var db = Context())
{
    var fcmConfig = new Microsoft.Extensions.Configuration.ConfigurationBuilder().Build();
    var fcmService = new FcmPushService(db, Microsoft.Extensions.Logging.Abstractions.NullLogger<FcmPushService>.Instance, fcmConfig);

    // Save token
    var saveTokenRes = await fcmService.SaveFcmTokenAsync(1, "fcm_test_token_user_1", "android");
    Check(saveTokenRes, "Save FCM token for User 1 succeeds");

    var user1 = await db.Users.FindAsync(1);
    Check(user1 != null && user1.FcmToken == "fcm_test_token_user_1", "User 1 has updated FcmToken in database");

    // Send fallback push directly to token
    var pushRes = await fcmService.SendPushAsync("fcm_test_token_user_1", "Nhắc lịch thi đấu", "Bạn có trận cầu lông lúc 18:00");
    Check(pushRes, "Fallback SendPushAsync succeeds without service account");

    // Build and verify FCM v1 High-Priority Message for background/terminated wake
    var v1Msg = fcmService.BuildHighPriorityMessage("fcm_test_token_user_1", "Kèo mới gần bạn", "Có 1 kèo Pickleball vừa mở", new Dictionary<string, string> { { "matchId", "10" } });
    Check(v1Msg.Token == "fcm_test_token_user_1" &&
          v1Msg.Android?.Priority == FirebaseAdmin.Messaging.Priority.High &&
          v1Msg.Android?.Notification?.ChannelId == FcmPushService.DefaultHighImportanceChannelId &&
          v1Msg.Android?.Notification?.Priority == FirebaseAdmin.Messaging.NotificationPriority.MAX &&
          v1Msg.Android?.Notification?.ClickAction == "FLUTTER_NOTIFICATION_CLICK" &&
          v1Msg.Apns?.Headers?["apns-priority"] == "10",
          "FCM v1 High-Priority message payload configured for terminated app wake");

    // Send push to user (persists in Notifications table + dispatches)
    var sendUserRes = await fcmService.SendToUserAsync(1, "Kèo mới gần bạn", "Có 1 kèo Pickleball vừa mở", "match");
    Check(sendUserRes, "SendToUserAsync succeeds and saves Notification entity");

    var lastNotif = await db.Notifications.OrderByDescending(n => n.Id).FirstOrDefaultAsync();
    Check(lastNotif != null && lastNotif.Title == "Kèo mới gần bạn" && lastNotif.UserId == 1, "Notification successfully persisted in database table");

    // 13. Test Real FCM HTTP v1 push with service account credentials to active device token
    var serviceAccountPath = Path.Combine(Directory.GetCurrentDirectory(), "backend/SportSpot.API/firebase-service-account.json");
    if (!File.Exists(serviceAccountPath))
    {
        serviceAccountPath = Path.Combine(Directory.GetCurrentDirectory(), "../SportSpot.API/firebase-service-account.json");
    }
    if (File.Exists(serviceAccountPath))
    {
        var realConfig = new TestConfig(new Dictionary<string, string?>
        {
            { "Firebase:Enabled", "true" },
            { "Firebase:ProjectId", "sportspot-prm393" },
            { "Firebase:ServiceAccountJsonPath", serviceAccountPath }
        });

        var realFcmService = new FcmPushService(db, Microsoft.Extensions.Logging.Abstractions.NullLogger<FcmPushService>.Instance, realConfig);
        var activeDeviceToken = "fQXVcWCrROGl5O_oUskrhY:APA91bEcozVkXy2eas-LXF_YF7wMEB78ToCeSX42x_W2xpUYjuggv9YZGV1ByLrH8_rOUaudJARbfyNnt_fgZox-7j4ZWDEsPTwp8wD28298R4Sz5xKuUzg";

        var realPushRes = await realFcmService.SendPushAsync(
            activeDeviceToken,
            "⚡ SportSpot Real-time Push",
            "Thông báo tức thời (<1s) qua FCM HTTP v1 chính thức!",
            new Dictionary<string, string> { { "type", "Reminder" }, { "timestamp", DateTime.UtcNow.ToString("o") } }
        );
        Check(realPushRes, "Real FCM HTTP v1 push dispatched to emulator device token successfully");
    }
}

// 12. Test UserSkills Save & Retrieval
using (var db = Context())
{
    var uow = Uow(db);
    var userService = new UserService(uow, db);

    var saveReq = new UpdateUserSkillsRequest
    {
        Skills = new List<UpdateUserSkillItemRequest>
        {
            new() { SportName = "Cầu lông", SkillLevel = "Khá", RatingScore = 4.0m },
            new() { SportName = "Pickleball", SkillLevel = "Phong trào", RatingScore = 3.5m }
        }
    };

    var saveRes = await userService.SaveUserSkillsAsync(1, saveReq);
    Check(saveRes.Success && saveRes.Data.Count == 2, "SaveUserSkillsAsync saves 2 skills successfully");
    Check(saveRes.Data.Any(s => s.SportName == "Cầu lông" && s.RatingScore == 4.0m && s.SkillLevel == "Khá"), "Skill Cầu lông has level Khá and score 4.0");

    var getRes = await userService.GetUserSkillsAsync(1);
    Check(getRes.Success && getRes.Data.Count == 2, "GetUserSkillsAsync retrieves saved skills");

    var user = await db.Users.FindAsync(1);
    Check(user != null && user.FavoriteSports != null && user.FavoriteSports.Contains("Cầu lông"), "User.FavoriteSports is kept in sync with UserSkills");
}

Console.WriteLine($"All {passed} Module 5 backend checks passed!");

class TestConfig : Microsoft.Extensions.Configuration.IConfiguration
{
    private readonly Dictionary<string, string?> _dict;
    public TestConfig(Dictionary<string, string?> dict) => _dict = dict;
    public string? this[string key] { get => _dict.TryGetValue(key, out var v) ? v : null; set => _dict[key] = value; }
    public IEnumerable<Microsoft.Extensions.Configuration.IConfigurationSection> GetChildren() => Enumerable.Empty<Microsoft.Extensions.Configuration.IConfigurationSection>();
    public Microsoft.Extensions.Primitives.IChangeToken GetReloadToken() => new DummyChangeToken();
    public Microsoft.Extensions.Configuration.IConfigurationSection GetSection(string key) => null!;
}

class DummyChangeToken : Microsoft.Extensions.Primitives.IChangeToken
{
    public bool HasChanged => false;
    public bool ActiveChangeCallbacks => false;
    public IDisposable RegisterChangeCallback(Action<object?> callback, object? state) => new DummyDisposable();
}

class DummyDisposable : IDisposable { public void Dispose() {} }
