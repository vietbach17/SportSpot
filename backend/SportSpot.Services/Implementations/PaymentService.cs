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
        var booking = await _unitOfWork.Bookings.GetBookingByIdWithDetailsAsync(request.BookingId);
        if (booking == null)
        {
            return ApiResponse<PaymentIntentResponseDto>.Fail("Không tìm thấy đơn đặt sân", 404);
        }

        if (booking.Status == "Cancelled")
        {
            return ApiResponse<PaymentIntentResponseDto>.Fail("Đơn đặt sân đã bị hủy, không thể tạo giao dịch thanh toán", 409);
        }

        var payerUserId = request.UserId > 0 ? request.UserId : booking.UserId;
        var amount = request.Amount > 0 ? request.Amount : booking.DepositAmount;
        var gateway = string.IsNullOrWhiteSpace(request.PaymentGateway) ? "VNPay" : request.PaymentGateway.Trim();

        // Nếu thanh toán bằng Số dư Ví SportSpot (tiền hoàn từ các đơn hủy trước)
        if (string.Equals(gateway, "Wallet", StringComparison.OrdinalIgnoreCase))
        {
            var user = await _unitOfWork.Users.GetByIdAsync(payerUserId);
            if (user == null)
            {
                return ApiResponse<PaymentIntentResponseDto>.Fail("Không tìm thấy thông tin người dùng", 404);
            }
            if (user.WalletBalance < amount)
            {
                return ApiResponse<PaymentIntentResponseDto>.Fail(
                    $"Số dư ví ({user.WalletBalance:N0} đ) không đủ để thanh toán cọc ({amount:N0} đ)", 400);
            }
            user.WalletBalance -= amount;
        }

        var transactionCode = $"TXN-{Guid.NewGuid():N}"[..20].ToUpper();
        var transaction = new Transaction
        {
            BookingId = booking.Id,
            UserId = payerUserId,
            Amount = amount,
            PaymentGateway = gateway,
            TransactionCode = transactionCode,
            Status = "Holding",
            CreatedAt = DateTime.UtcNow
        };

        booking.Status = "Upcoming";
        await _unitOfWork.Transactions.AddAsync(transaction);
        await _unitOfWork.SaveChangesAsync();

        var qrPayload = QrChecksumHelper.BuildSignedQrPayload(booking.BookingCode, payerUserId, "Host");
        var paymentUrl = gateway.ToUpperInvariant() switch
        {
            "MOMO" => $"https://test-payment.momo.vn/v2/gateway/pay?orderId={transactionCode}&amount={amount}",
            "ATM" => $"https://sandbox.napas.com.vn/checkout?txnRef={transactionCode}&amount={amount}",
            "WALLET" => $"sportspot://wallet-paid?txnRef={transactionCode}",
            _ => $"https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_TxnRef={transactionCode}&vnp_Amount={amount * 100}"
        };

        var response = new PaymentIntentResponseDto
        {
            TransactionCode = transactionCode,
            PaymentUrl = paymentUrl,
            EscrowStatus = "Holding",
            Amount = amount,
            PaymentGateway = gateway,
            QrPayload = qrPayload
        };

        return ApiResponse<PaymentIntentResponseDto>.Ok(
            response,
            "Khởi tạo giao dịch thanh toán cọc Escrow thành công. Tiền cọc đang được tạm giữ an toàn (Holding).");
    }

    public async Task<ApiResponse<object>> ProcessWebhookAsync(PaymentWebhookRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.TransactionCode))
        {
            return ApiResponse<object>.Fail("Thiếu mã giao dịch (TransactionCode)", 400);
        }

        var transaction = await _unitOfWork.Transactions.GetByTransactionCodeAsync(request.TransactionCode.Trim());
        if (transaction == null)
        {
            return ApiResponse<object>.Fail("Không tìm thấy mã giao dịch", 404);
        }

        transaction.Status = request.IsSuccess ? "Holding" : "Failed";
        string? qrPayload = null;

        if (transaction.Booking != null && request.IsSuccess)
        {
            transaction.Booking.Status = "Upcoming";
            qrPayload = QrChecksumHelper.BuildSignedQrPayload(
                transaction.Booking.BookingCode,
                transaction.UserId,
                "Host");
        }

        _unitOfWork.Transactions.Update(transaction);
        await _unitOfWork.SaveChangesAsync();

        return ApiResponse<object>.Ok(new
        {
            transactionCode = transaction.TransactionCode,
            escrowStatus = transaction.Status,
            bookingId = transaction.BookingId,
            bookingCode = transaction.Booking?.BookingCode,
            qrPayload
        }, request.IsSuccess
            ? "Xác nhận Webhook IPN thành công! Tiền cọc đã chuyển sang trạng thái tạm giữ Escrow (Holding)."
            : "Giao dịch thanh toán thất bại.");
    }

    public async Task<ApiResponse<BookingResponseDto>> MockInstantPayAsync(string bookingCode)
    {
        if (string.IsNullOrWhiteSpace(bookingCode))
        {
            return ApiResponse<BookingResponseDto>.Fail("Mã đặt sân không hợp lệ", 400);
        }

        var booking = await _unitOfWork.Bookings.GetBookingByCodeWithDetailsAsync(bookingCode.Trim());
        if (booking == null)
        {
            return ApiResponse<BookingResponseDto>.Fail("Không tìm thấy mã đặt sân", 404);
        }

        booking.Status = "Upcoming";

        var existingHolding = booking.Transactions.FirstOrDefault(t => t.Status == "Holding" || t.Status == "Settled");
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
            VenueId = booking.SubVenue?.VenueId ?? 0,
            VenueName = booking.SubVenue?.Venue?.Name ?? string.Empty,
            SubVenueName = booking.SubVenue?.Name ?? string.Empty,
            SportName = booking.SubVenue?.Venue?.Sport?.Name ?? string.Empty,
            Address = booking.SubVenue?.Venue?.Address ?? string.Empty,
            PlayDate = booking.PlayDate,
            TimeSlots = booking.BookingDetails
                .OrderBy(bd => bd.SlotId)
                .Select(bd => $"{bd.TimeSlot?.StartTime}-{bd.TimeSlot?.EndTime}")
                .ToList(),
            UserRoleInMatch = "Host",
            CourtPrice = booking.CourtPrice,
            ServicesPrice = booking.ServicesPrice,
            TotalPrice = booking.TotalPrice,
            DepositAmount = booking.DepositAmount,
            RemainingBalance = booking.RemainingBalance,
            Status = booking.Status,
            EscrowStatus = existingHolding?.Status ?? "Holding",
            QrPayload = qrPayload,
            IsCheckedIn = booking.IsCheckedIn
        };

        return ApiResponse<BookingResponseDto>.Ok(
            dto,
            "Thanh toán giả lập (Mock Sandbox) thành công! Tiền cọc đang được giữ an toàn (Escrow Holding).");
    }

    public async Task<ApiResponse<WalletAndHistoryDto>> GetUserTransactionsAsync(int userId)
    {
        if (userId <= 0)
        {
            return ApiResponse<WalletAndHistoryDto>.Fail("Vui lòng đăng nhập để xem lịch sử giao dịch", 401);
        }

        var user = await _unitOfWork.Users.GetByIdAsync(userId);
        var transactions = await _unitOfWork.Transactions.GetByUserIdAsync(userId);

        var items = transactions.Select(t => new TransactionHistoryDto
        {
            Id = t.Id,
            TransactionCode = t.TransactionCode,
            BookingId = t.BookingId,
            BookingCode = t.Booking?.BookingCode ?? string.Empty,
            VenueName = t.Booking?.SubVenue?.Venue?.Name ?? "SportSpot Venue",
            Amount = t.Amount,
            PaymentGateway = t.PaymentGateway,
            Status = t.Status,
            CreatedAt = t.CreatedAt
        }).ToList();

        var escrowHoldingTotal = items
            .Where(t => t.Status == "Holding")
            .Sum(t => t.Amount);

        return ApiResponse<WalletAndHistoryDto>.Ok(new WalletAndHistoryDto
        {
            WalletBalance = user?.WalletBalance ?? 0,
            EscrowHoldingTotal = escrowHoldingTotal,
            Transactions = items
        }, "Lấy lịch sử giao dịch Escrow và số dư ví thành công");
    }
}
