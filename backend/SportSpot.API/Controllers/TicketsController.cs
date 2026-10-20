using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TicketsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public TicketsController(ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    /// <summary>
    /// GET /api/tickets/my-tickets: Lấy danh sách vé đã đặt kèm chuỗi QR Payload có chữ ký SHA-256 Checksum.
    /// </summary>
    [HttpGet("my-tickets")]
    public async Task<ActionResult<ApiResponse<List<BookingResponseDto>>>> GetMyTickets([FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        var result = await _ticketService.GetMyTicketsAsync(uid);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// POST /api/tickets/verify-qr: Nhân viên lễ tân quét mã QR check-in -> Giải ngân tiền cọc Escrow (Holding -> Settled).
    /// </summary>
    [HttpPost("verify-qr")]
    public async Task<ActionResult<ApiResponse<object>>> VerifyQr([FromBody] CheckInRequest request)
    {
        var result = await _ticketService.VerifyQrAndSettleEscrowAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// POST /api/tickets/{bookingId}/cancel: Hủy vé với chính sách hoàn cọc / phạt bậc thang (>=4h: 100%, 2-4h: 50%, <2h: 0%).
    /// </summary>
    [HttpPost("{bookingId}/cancel")]
    public async Task<ActionResult<ApiResponse<CancelRefundResultDto>>> CancelTicket(int bookingId, [FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        var result = await _ticketService.CancelTicketWithTieredRefundAsync(bookingId, uid);
        return StatusCode(result.StatusCode, result);
    }

    private int GetCurrentUserId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claimValue, out var id) ? id : 0;
    }
}
