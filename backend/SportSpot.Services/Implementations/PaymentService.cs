using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class PaymentService : IPaymentService
{
    private readonly IUnitOfWork _unitOfWork;

    public PaymentService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<PaymentIntentResponseDto>> CreatePaymentIntentAsync(CreatePaymentIntentRequest request)
    {
        var booking = await _unitOfWork.Bookings.GetByIdAsync(request.BookingId);
        if (booking == null)
        {
            return ApiResponse<PaymentIntentResponseDto>.Fail("Không tìm thấy đơn đặt sân", 404);
        }

        var transactionCode = $"TXN-{Guid.NewGuid():N}"[..20].ToUpper();
        var transaction = new Transaction
        {
            BookingId = booking.Id,
            UserId = request.UserId > 0 ? request.UserId : booking.UserId,
            Amount = request.Amount > 0 ? request.Amount : booking.DepositAmount,
            PaymentGateway = string.IsNullOrWhiteSpace(request.PaymentGateway) ? "VNPay" : request.PaymentGateway,
            TransactionCode = transactionCode,
            Status = "Holding",
            CreatedAt = DateTime.UtcNow
        };

        await _unitOfWork.Transactions.AddAsync(transaction);
        await _unitOfWork.SaveChangesAsync();

        var response = new PaymentIntentResponseDto
        {
            TransactionCode = transactionCode,
            PaymentUrl = $"https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_TxnRef={transactionCode}&vnp_Amount={transaction.Amount * 100}",
            EscrowStatus = "Holding"
        };

        return ApiResponse<PaymentIntentResponseDto>.Ok(response, "Khởi tạo giao dịch thanh toán Escrow thành công");
    }

    public async Task<ApiResponse<object>> ProcessWebhookAsync(PaymentWebhookRequest request)
    {
        var transaction = await _unitOfWork.Transactions.GetByTransactionCodeAsync(request.TransactionCode);
        if (transaction == null)
        {
            return ApiResponse<object>.Fail("Không tìm thấy mã giao dịch", 404);
        }

        transaction.Status = request.IsSuccess ? "Holding" : "Failed";
        if (transaction.Booking != null && request.IsSuccess)
        {
            transaction.Booking.Status = "Upcoming";
        }

        _unitOfWork.Transactions.Update(transaction);
        await _unitOfWork.SaveChangesAsync();

        return ApiResponse<object>.Ok(new
        {
            transactionCode = transaction.TransactionCode,
            escrowStatus = transaction.Status,
            bookingId = transaction.BookingId
        }, "Cập nhật Webhook thanh toán thành công");
    }

    public async Task<ApiResponse<BookingResponseDto>> MockInstantPayAsync(string bookingCode)
    {
        var booking = await _unitOfWork.Bookings.GetBookingByCodeWithDetailsAsync(bookingCode);
        if (booking == null)
        {
            return ApiResponse<BookingResponseDto>.Fail("Không tìm thấy mã đặt sân", 404);
        }

        booking.Status = "Upcoming";
        var fullBook = await _unitOfWork.Bookings.GetBookingByIdWithDetailsAsync(booking.Id);

        var existingHolding = booking.Transactions.FirstOrDefault(t => t.Status == "Holding");
        if (existingHolding == null)
        {
            await _unitOfWork.Transactions.AddAsync(new Transaction
            {
                BookingId = booking.Id,
                UserId = booking.UserId,
                Amount = booking.DepositAmount,
                PaymentGateway = "MockSandbox",
                TransactionCode = $"MOCK-{Guid.NewGuid():N}"[..16].ToUpper(),
                Status = "Holding",
                CreatedAt = DateTime.UtcNow
            });
        }

        await _unitOfWork.SaveChangesAsync();

        var qrPayload = QrChecksumHelper.BuildSignedQrPayload(booking.BookingCode, booking.UserId, "Host");

        var dto = new BookingResponseDto
        {
            BookingId = booking.Id,
            BookingCode = booking.BookingCode,
            VenueName = fullBook?.SubVenue?.Venue?.Name ?? string.Empty,
            SubVenueName = fullBook?.SubVenue?.Name ?? string.Empty,
            SportName = fullBook?.SubVenue?.Venue?.Sport?.Name ?? string.Empty,
            Address = fullBook?.SubVenue?.Venue?.Address ?? string.Empty,
            PlayDate = booking.PlayDate,
            TimeSlots = fullBook?.BookingDetails
                .OrderBy(bd => bd.SlotId)
                .Select(bd => $"{bd.TimeSlot?.StartTime}-{bd.TimeSlot?.EndTime}")
                .ToList() ?? new List<string>(),
            CourtPrice = booking.CourtPrice,
            ServicesPrice = booking.ServicesPrice,
            TotalPrice = booking.TotalPrice,
            DepositAmount = booking.DepositAmount,
            RemainingBalance = booking.RemainingBalance,
            Status = booking.Status,
            QrPayload = qrPayload,
            IsCheckedIn = booking.IsCheckedIn
        };

        return ApiResponse<BookingResponseDto>.Ok(dto, "Thanh toán giả lập (Mock Sandbox) thành công! Tiền cọc đang được giữ an toàn (Escrow Holding).");
    }
}
