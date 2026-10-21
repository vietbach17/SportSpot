using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BookingsController : ControllerBase
{
    private readonly IBookingService _bookingService;

    public BookingsController(IBookingService bookingService)
    {
        _bookingService = bookingService;
    }

    [Microsoft.AspNetCore.Authorization.Authorize]
    [HttpPost]
    public async Task<ActionResult<ApiResponse<BookingResponseDto>>> CreateBooking([FromBody] CreateBookingRequest request)
    {
        request.UserId = int.TryParse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value, out var userId) ? userId : 0;
        var result = await _bookingService.CreateBookingAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    [HttpGet("my-bookings/{userId}")]
    public async Task<ActionResult<ApiResponse<List<BookingResponseDto>>>> GetMyBookings(int userId)
    {
        var result = await _bookingService.GetMyBookingsAsync(userId);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPost("check-in")]
    public async Task<ActionResult<ApiResponse<object>>> CheckIn([FromBody] CheckInRequest request)
    {
        var result = await _bookingService.CheckInAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPost("{id}/cancel")]
    public async Task<ActionResult<ApiResponse<CancelRefundResultDto>>> CancelBooking(int id, [FromQuery] int userId)
    {
        var result = await _bookingService.CancelBookingAsync(id, userId);
        return StatusCode(result.StatusCode, result);
    }
}
