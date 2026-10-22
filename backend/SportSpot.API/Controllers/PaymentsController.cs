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
        if (uid <= 0) uid = 1; // Fallback dev mode
        var result = await _paymentService.GetUserTransactionsAsync(uid);
        return StatusCode(result.StatusCode, result);
    }

    private int GetCurrentUserId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claimValue, out var id) ? id : 0;
    }
}
