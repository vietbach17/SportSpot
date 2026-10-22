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

Console.WriteLine($"All {passed} Module 5 backend checks passed!");
