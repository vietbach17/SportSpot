using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Services.Implementations;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class OwnerController : ControllerBase
{
    private readonly IOwnerService _ownerService;
    private readonly OwnerScheduleService _schedule;
    private readonly SportSpotDbContext _db;
    private int UserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    public OwnerController(IOwnerService ownerService, OwnerScheduleService schedule, SportSpotDbContext db)
    {
        _ownerService = ownerService;
        _schedule = schedule;
        _db = db;
    }

    /// <summary>
    /// GET /api/owner/dashboard?venueId={venueId}: Bảng thống kê doanh thu, tỷ lệ lấp đầy và quản lý sân cho chủ sân.
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<ApiResponse<OwnerDashboardDto>>> GetDashboard([FromQuery] int? venueId)
    {
        var venues = await _schedule.Venues(UserId);
        if (!venues.Success) return StatusCode(venues.StatusCode, ApiResponse<OwnerDashboardDto>.Fail(venues.Message, venues.StatusCode));
        var targetVenueId = venueId ?? venues.Data!.FirstOrDefault()?.Id ?? 0;
        if (targetVenueId == 0) return StatusCode(403, ApiResponse<OwnerDashboardDto>.Fail("Tài khoản chưa được phân công cụm sân. Nhờ quản trị viên gán sân để quản lý.", 403));
        if (!await _schedule.CanManage(UserId, targetVenueId)) return Forbid();
        var result = await _ownerService.GetOwnerDashboardAsync(targetVenueId);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// PUT /api/owner/subvenues/{subVenueId}/toggle-status: Bật/tắt trạng thái bảo trì hoặc hoạt động của sân con.
    /// </summary>
    [HttpPut("subvenues/{subVenueId}/toggle-status")]
    public async Task<ActionResult<ApiResponse<bool>>> ToggleSubVenueStatus(int subVenueId, [FromBody] ToggleSubVenueRequest? request)
    {
        var court = await _db.SubVenues.FindAsync(subVenueId);
        if (court == null) return NotFound(ApiResponse<bool>.Fail("Không tìm thấy sân", 404));
        if (!await _schedule.CanManage(UserId, court.VenueId, true)) return Forbid();
        var result = await _ownerService.ToggleSubVenueStatusAsync(subVenueId, request?.IsActive);
        return StatusCode(result.StatusCode, result);
    }

    [HttpGet("venues")]
    public async Task<IActionResult> Venues() => Respond(await _schedule.Venues(UserId));
    [HttpGet("schedule")]
    public async Task<IActionResult> Schedule([FromQuery] int venueId, [FromQuery] DateOnly from, [FromQuery] DateOnly to)
        => Respond(await _schedule.Schedule(UserId, venueId, from, to));
    [HttpPost("bookings")]
    public async Task<IActionResult> Create(CreateManagedBookingRequest request) => Respond(await _schedule.Create(UserId, request));
    [HttpPost("bookings/{id:int}/cancel")]
    public async Task<IActionResult> Cancel(int id, CancelManagedBookingRequest request) => Respond(await _schedule.Cancel(UserId, id, request.ConfirmCashRefund));
    [HttpPost("bookings/{id:int}/collect")]
    public async Task<IActionResult> Collect(int id, CollectCashRequest request) => Respond(await _schedule.Collect(UserId, id, request.Amount));
    [HttpPost("bookings/{id:int}/complete")]
    public async Task<IActionResult> Complete(int id) => Respond(await _schedule.Complete(UserId, id));
    [HttpPut("venues/{id:int}/prices")]
    public async Task<IActionResult> Prices(int id, UpdateVenuePricesRequest request) => Respond(await _schedule.Prices(UserId, id, request));
    [Authorize(Roles = "Admin"), HttpPut("venues/{venueId:int}/owner/{ownerId:int}")]
    public async Task<IActionResult> AssignOwner(int venueId, int ownerId)
    {
        var user = await _db.Users.FindAsync(ownerId);
        if (user?.Role != "Owner" || !await _db.Venues.AnyAsync(v => v.Id == venueId))
            return Respond(ApiResponse<bool>.Fail("Chọn tài khoản Owner và cụm sân hợp lệ"));
        user.StaffVenueId = venueId;
        var venue = await _db.Venues.FindAsync(venueId);
        venue!.OwnerUserId = ownerId;
        await _db.SaveChangesAsync();
        return Respond(ApiResponse<bool>.Ok(true));
    }
    private ObjectResult Respond<T>(ApiResponse<T> result) => StatusCode(result.StatusCode, result);
}
