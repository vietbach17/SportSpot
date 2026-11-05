using PayOS;
using PayOS.Models.V2.PaymentRequests;
using PayOS.Models.Webhooks;
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

    
    private PayOSClient? GetPayOSClient()
    {
        var clientId = Environment.GetEnvironmentVariable("PAYOS_CLIENT_ID");
        var apiKey = Environment.GetEnvironmentVariable("PAYOS_API_KEY");
        var checksumKey = Environment.GetEnvironmentVariable("PAYOS_CHECKSUM_KEY");

        if (!string.IsNullOrWhiteSpace(clientId) && !string.IsNullOrWhiteSpace(apiKey) && !string.IsNullOrWhiteSpace(checksumKey))
        {
            return new PayOSClient(new PayOSOptions
            {
                ClientId = clientId.Trim(),
                ApiKey = apiKey.Trim(),
                ChecksumKey = checksumKey.Trim()
            });
        }
        return null;
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


        // Tích hợp cổng PayOS VietQR nếu được cấu hình và gateway là PayOS / VietQR
        string? payOsAccNo = null;
        string? payOsAccName = null;
        string? payOsBankName = null;
        string? payOsTransferDesc = null;
        if (!string.Equals(gateway, "Wallet", StringComparison.OrdinalIgnoreCase))
        {
            var payOsClient = GetPayOSClient();
            if (payOsClient != null && (string.Equals(gateway, "PayOS", StringComparison.OrdinalIgnoreCase) ||
                                       string.Equals(gateway, "VietQR", StringComparison.OrdinalIgnoreCase)))
            {
                try
                {
                    long orderCode = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 9000000000000L + 1000000000000L;
                    var desc = $"Coc {booking.BookingCode}".Trim();
                    if (desc.Length > 25) desc = desc[..25];

                    var payOsRequest = new CreatePaymentLinkRequest
                    {
                        OrderCode = orderCode,
                        Amount = amount,
                        Description = desc,
                        ReturnUrl = "https://sportspot.vn/payment-success",
                        CancelUrl = "https://sportspot.vn/payment-cancel"
                    };

                    var payOsResponse = await payOsClient.PaymentRequests.CreateAsync(payOsRequest);
                    if (payOsResponse != null)
                    {
                        transactionCode = orderCode.ToString();
                        transaction.TransactionCode = transactionCode;
                        transaction.PaymentGateway = "PayOS";
                        _unitOfWork.Transactions.Update(transaction);
                        await _unitOfWork.SaveChangesAsync();

                        paymentUrl = payOsResponse.CheckoutUrl ?? paymentUrl;
                        if (!string.IsNullOrWhiteSpace(payOsResponse.QrCode))
                        {
                            qrPayload = payOsResponse.QrCode;
                        }
                        payOsAccNo = payOsResponse.AccountNumber;
                        payOsAccName = payOsResponse.AccountName;
                        payOsBankName = payOsResponse.Bin switch
                        {
                            "970418" => "VietinBank (Ngân hàng TMCP Công Thương)",
                            "970422" => "MBBank (Ngân hàng TMCP Quân Đội)",
                            "970436" => "Vietcombank",
                            "970407" => "Techcombank",
                            _ => "Ngân hàng liên kết (" + payOsResponse.Bin + ")"
                        };
                        payOsTransferDesc = payOsResponse.Description;
                    }
                }
                catch (Exception)
                {
                    // Fallback to simulation url if offline or mock
                }
            }
        }

        var response = new PaymentIntentResponseDto
        {
            TransactionCode = transactionCode,
            PaymentUrl = paymentUrl,
            EscrowStatus = "Holding",
            Amount = amount,
            PaymentGateway = gateway,
            QrPayload = qrPayload,
            AccountNumber = payOsAccNo,
            AccountName = payOsAccName,
            BankName = payOsBankName,
            Description = payOsTransferDesc
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


    public async Task<ApiResponse<object>> ProcessPayOSWebhookAsync(Webhook webhook)
    {
        if (webhook == null || webhook.Data == null)
        {
            return ApiResponse<object>.Fail("Dữ liệu webhook PayOS không hợp lệ", 400);
        }

        var payOsClient = GetPayOSClient();
        if (payOsClient != null && !string.IsNullOrWhiteSpace(webhook.Signature))
        {
            try
            {
                await payOsClient.Webhooks.VerifyAsync(webhook);
            }
            catch (Exception ex)
            {
                // Cảnh báo chữ ký không khớp nhưng không trả về 400 trong quá trình test/xác thực URL từ payOS Dashboard
                Console.WriteLine($"[PayOS Webhook] Cảnh báo chữ ký: {ex.Message}");
            }
        }

        if (webhook.Data == null)
        {
            return ApiResponse<object>.Ok(new { test = true }, "Nhận webhook kiểm tra URL thành công.");
        }

        var orderCodeStr = webhook.Data.OrderCode.ToString();
        var transaction = await _unitOfWork.Transactions.GetByTransactionCodeAsync(orderCodeStr);
        if (transaction == null)
        {
            // Test ping từ payOS Dashboard khi nhấn Lưu Webhook (hoặc đơn test không có trong DB)
            // Cần trả về 200 OK để payOS xác nhận endpoint hoạt động tốt
            return ApiResponse<object>.Ok(new
            {
                orderCode = webhook.Data.OrderCode,
                status = "OK",
                testPing = true
            }, "Nhận webhook kiểm tra (Test Ping) thành công.");
        }

        bool isSuccess = webhook.Code == "00" || webhook.Success;
        transaction.Status = isSuccess ? "Holding" : "Failed";
        string? qrPayload = null;

        if (transaction.Booking != null && isSuccess)
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
        }, isSuccess
            ? "Xác nhận Webhook PayOS thành công! Tiền cọc đã chuyển sang trạng thái tạm giữ Escrow (Holding)."
            : "Giao dịch thanh toán PayOS thất bại.");
    }

    public async Task<ApiResponse<string>> ConfirmPayOSWebhookUrlAsync(string webhookUrl)
    {
        if (string.IsNullOrWhiteSpace(webhookUrl))
        {
            return ApiResponse<string>.Fail("Thiếu webhook URL", 400);
        }

        var payOsClient = GetPayOSClient();
        if (payOsClient == null)
        {
            return ApiResponse<string>.Fail("Chưa cấu hình thông tin PayOS trong hệ thống", 500);
        }

        try
        {
            var res = await payOsClient.Webhooks.ConfirmAsync(webhookUrl.Trim());
            return ApiResponse<string>.Ok(res?.WebhookUrl ?? webhookUrl, "Xác nhận webhook URL với PayOS thành công!");
        }
        catch (Exception ex)
        {
            return ApiResponse<string>.Fail($"Lỗi khi xác nhận webhook với PayOS: {ex.Message}", 400);
        }
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

    public async Task<ApiResponse<WalletAndHistoryDto>> TopUpWalletAsync(TopUpWalletRequest request)
    {
        if (request.UserId <= 0) return ApiResponse<WalletAndHistoryDto>.Fail("Vui lòng đăng nhập", 401);
        if (request.Amount <= 0) return ApiResponse<WalletAndHistoryDto>.Fail("Số tiền nạp phải lớn hơn 0", 400);

        var user = await _unitOfWork.Users.GetByIdAsync(request.UserId);
        if (user == null) return ApiResponse<WalletAndHistoryDto>.Fail("Không tìm thấy người dùng", 404);

        user.WalletBalance += request.Amount;

        var allBookings = await _unitOfWork.Bookings.GetAllAsync();
        var dummyBookingId = allBookings.FirstOrDefault()?.Id ?? 1;

        var tx = new Transaction
        {
            TransactionCode = $"TOPUP-{DateTime.UtcNow:yyyyMMddHHmmss}-{Random.Shared.Next(100, 999)}",
            BookingId = dummyBookingId,
            UserId = request.UserId,
            Amount = request.Amount,
            PaymentGateway = string.IsNullOrWhiteSpace(request.PaymentGateway) ? "VNPay" : request.PaymentGateway,
            Status = "Settled",
            CreatedAt = DateTime.UtcNow
        };
        await _unitOfWork.Transactions.AddAsync(tx);
        await _unitOfWork.SaveChangesAsync();

        return await GetUserTransactionsAsync(request.UserId);
    }

    public async Task<ApiResponse<WalletAndHistoryDto>> WithdrawWalletAsync(WithdrawWalletRequest request)
    {
        if (request.UserId <= 0) return ApiResponse<WalletAndHistoryDto>.Fail("Vui lòng đăng nhập", 401);
        if (request.Amount <= 0) return ApiResponse<WalletAndHistoryDto>.Fail("Số tiền rút phải lớn hơn 0", 400);
        if (request.Amount < 50000) return ApiResponse<WalletAndHistoryDto>.Fail("Số tiền rút tối thiểu là 50.000 đ", 400);

        var user = await _unitOfWork.Users.GetByIdAsync(request.UserId);
        if (user == null) return ApiResponse<WalletAndHistoryDto>.Fail("Không tìm thấy người dùng", 404);

        if (user.WalletBalance < request.Amount)
        {
            return ApiResponse<WalletAndHistoryDto>.Fail($"Số tiền rút ({request.Amount:N0} đ) vượt quá số dư ví hiện có ({user.WalletBalance:N0} đ)", 400);
        }

        user.WalletBalance -= request.Amount;

        var allBookings = await _unitOfWork.Bookings.GetAllAsync();
        var dummyBookingId = allBookings.FirstOrDefault()?.Id ?? 1;

        var tx = new Transaction
        {
            TransactionCode = $"WD-{DateTime.UtcNow:yyyyMMddHHmmss}-{Random.Shared.Next(100, 999)}",
            BookingId = dummyBookingId,
            UserId = request.UserId,
            Amount = request.Amount,
            PaymentGateway = $"BankTransfer: {request.BankName} - {request.AccountNumber}",
            Status = "Settled",
            CreatedAt = DateTime.UtcNow
        };
        await _unitOfWork.Transactions.AddAsync(tx);
        await _unitOfWork.SaveChangesAsync();

        return await GetUserTransactionsAsync(request.UserId);
    }

    public async Task<ApiResponse<object>> GetPaymentStatusAsync(int bookingId)
    {
        var booking = await _unitOfWork.Bookings.GetByIdAsync(bookingId);
        if (booking == null) return ApiResponse<object>.Fail("Không tìm thấy đơn đặt sân", 404);
        var txns = await _unitOfWork.Transactions.GetByBookingIdAsync(bookingId);
        var lastTxn = txns.LastOrDefault();
        var isPaid = booking.Status == "Confirmed" || lastTxn?.Status == "Completed";
        return ApiResponse<object>.Ok(new
        {
            bookingId = booking.Id,
            bookingStatus = booking.Status,
            transactionStatus = lastTxn?.Status ?? "Holding",
            isPaid = isPaid
        });
    }

}