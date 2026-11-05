using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public PaymentsController(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    /// <summary>
    /// POST /api/payments/create-intent: Khởi tạo giao dịch thanh toán cọc qua cổng thanh toán (Escrow Holding).
    /// </summary>
    [HttpPost("create-intent")]
    public async Task<ActionResult<ApiResponse<PaymentIntentResponseDto>>> CreatePaymentIntent(
        [FromBody] CreatePaymentIntentRequest request)
    {
        if (request.UserId <= 0)
        {
            request.UserId = GetCurrentUserId();
        }
        var result = await _paymentService.CreatePaymentIntentAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// POST /api/payments/webhook-ipn: Nhận callback thanh toán và giữ tiền cọc ở trạng thái Holding.
    /// </summary>
    [HttpPost("webhook-ipn")]
    [HttpPost("webhook")]
    public async Task<ActionResult<ApiResponse<object>>> WebhookIpn([FromBody] PaymentWebhookRequest request)
    {
        var result = await _paymentService.ProcessWebhookAsync(request);
        return StatusCode(result.StatusCode, result);
    }


    /// <summary>
    /// POST /api/payments/payos-webhook: Nhận Webhook IPN trực tiếp từ PayOS khi khách chuyển khoản thành công.
    /// </summary>
    /// <summary>
    /// GET /api/payments/payos-webhook: Kiểm tra trạng thái hoạt động của webhook endpoint.
    /// </summary>
    [HttpGet("payos-webhook")]
    public ActionResult<ApiResponse<string>> PayOSWebhookHealth()
    {
        return Ok(ApiResponse<string>.Ok("SportSpot PayOS Webhook endpoint is active and healthy!"));
    }

    [HttpPost("payos-webhook")]
    public async Task<ActionResult<ApiResponse<object>>> PayOSWebhook([FromBody] PayOS.Models.Webhooks.Webhook webhook)
    {
        var result = await _paymentService.ProcessPayOSWebhookAsync(webhook);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// POST /api/payments/confirm-payos-webhook: Xác nhận Webhook URL với PayOS.
    /// </summary>
    [HttpPost("confirm-payos-webhook")]
    public async Task<ActionResult<ApiResponse<string>>> ConfirmPayOSWebhook([FromBody] ConfirmWebhookDto dto)
    {
        var result = await _paymentService.ConfirmPayOSWebhookUrlAsync(dto.WebhookUrl);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// POST /api/payments/mock-pay/{bookingCode}: Kích hoạt thanh toán giả lập thành công tức thì để cả nhóm test sinh vé QR.
    /// </summary>
    [HttpPost("mock-pay/{bookingCode}")]
    public async Task<ActionResult<ApiResponse<BookingResponseDto>>> MockInstantPayment(string bookingCode)
    {
        var result = await _paymentService.MockInstantPayAsync(bookingCode);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// GET /api/payments/history: Xem số dư ví hoàn tiền và lịch sử giao dịch Escrow của người dùng.
    /// </summary>
    [HttpGet("history")]
    public async Task<ActionResult<ApiResponse<WalletAndHistoryDto>>> GetPaymentHistory([FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        if (uid <= 0)
        {
            return Ok(ApiResponse<WalletAndHistoryDto>.Ok(new WalletAndHistoryDto
            {
                WalletBalance = 320000,
                EscrowHoldingTotal = 0,
                Transactions = new List<TransactionHistoryDto>()
            }, "Số dư ví khách vãng lai (Guest Wallet)."));
        }
        var result = await _paymentService.GetUserTransactionsAsync(uid);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// POST /api/payments/topup: Nạp tiền trực tiếp vào ví người dùng (Demo / VNPay / MoMo).
    /// </summary>
    [HttpPost("topup")]
    public async Task<ActionResult<ApiResponse<WalletAndHistoryDto>>> TopUpWallet([FromBody] TopUpWalletRequest request)
    {
        if (request.UserId <= 0)
        {
            request.UserId = GetCurrentUserId();
            if (request.UserId <= 0) request.UserId = 1;
        }
        var result = await _paymentService.TopUpWalletAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    
    /// <summary>
    /// POST /api/payments/withdraw: Rút tiền từ ví về tài khoản ngân hàng.
    /// </summary>
    [HttpPost("withdraw")]
    public async Task<ActionResult<ApiResponse<WalletAndHistoryDto>>> WithdrawWallet([FromBody] WithdrawWalletRequest request)
    {
        if (request.UserId <= 0)
        {
            request.UserId = GetCurrentUserId();
            if (request.UserId <= 0) request.UserId = 1;
        }
        var result = await _paymentService.WithdrawWalletAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    private int GetCurrentUserId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claimValue, out var id) ? id : 0;
    }

    /// <summary>
    /// GET /api/payments/status/{bookingId}: Kiểm tra trạng thái thanh toán đơn (để client polling).
    /// </summary>
    [HttpGet("status/{bookingId}")]
    public async Task<ActionResult<ApiResponse<object>>> GetPaymentStatus(int bookingId)
    {
        var result = await _paymentService.GetPaymentStatusAsync(bookingId);
        return StatusCode(result.StatusCode, result);
    }

}