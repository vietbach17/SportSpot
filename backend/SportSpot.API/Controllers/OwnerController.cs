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
    private readonly OwnerConfigService _config;
    private readonly SportSpotDbContext _db;
    private int UserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    public OwnerController(
        IOwnerService ownerService,
        OwnerScheduleService schedule,
        OwnerConfigService config,
        SportSpotDbContext db)
    {
        _ownerService = ownerService;
        _schedule = schedule;
        _config = config;
        _db = db;
    }

    /// <summary>
    /// GET /api/owner/dashboard?venueId={venueId}: Bảng thống kê doanh thu, tỷ lệ lấp đầy và quản lý sân cho chủ sân.
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<ApiResponse<OwnerDashboardDto>>> GetDashboard([FromQuery] int? venueId)
    {
        var result = await _ownerService.GetOwnerDashboardForUserAsync(UserId, venueId);
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

    // ==========================================
    // OWNER CONFIGURATION DASHBOARD ENDPOINTS
    // ==========================================
    [HttpGet("venues/{venueId:int}/config")]
    public async Task<IActionResult> GetVenueConfig(int venueId) => Respond(await _config.GetConfig(UserId, venueId));

    [HttpPut("venues/{venueId:int}/info")]
    public async Task<IActionResult> UpdateVenueInfo(int venueId, UpdateOwnerVenueInfoRequest request)
        => Respond(await _config.UpdateVenueInfo(UserId, venueId, request));

    [HttpPut("venues/{venueId:int}/slots")]
    public async Task<IActionResult> UpdateVenueSlots(int venueId, UpdateOwnerSlotConfigRequest request)
        => Respond(await _config.UpdateSlotConfig(UserId, venueId, request));

    [HttpPost("venues/{venueId:int}/subvenues")]
    public async Task<IActionResult> AddSubVenue(int venueId, UpsertSubVenueRequest request)
        => Respond(await _config.AddSubVenue(UserId, venueId, request));

    [HttpPut("subvenues/{subVenueId:int}")]
    public async Task<IActionResult> UpdateSubVenue(int subVenueId, UpsertSubVenueRequest request)
        => Respond(await _config.UpdateSubVenue(UserId, subVenueId, request));

    [HttpDelete("subvenues/{subVenueId:int}")]
    public async Task<IActionResult> DeleteSubVenue(int subVenueId)
        => Respond(await _config.DeleteSubVenue(UserId, subVenueId));

    [HttpPost("venues/{venueId:int}/services")]
    public async Task<IActionResult> AddService(int venueId, UpsertVenueServiceRequest request)
        => Respond(await _config.AddService(UserId, venueId, request));

    [HttpPut("services/{serviceId:int}")]
    public async Task<IActionResult> UpdateService(int serviceId, UpsertVenueServiceRequest request)
        => Respond(await _config.UpdateService(UserId, serviceId, request));

    [HttpDelete("services/{serviceId:int}")]
    public async Task<IActionResult> DeleteService(int serviceId)
        => Respond(await _config.DeleteService(UserId, serviceId));

    [HttpPost("venues/{venueId:int}/staff")]
    public async Task<IActionResult> AssignStaff(int venueId, AssignVenueStaffRequest request)
        => Respond(await _config.AssignStaff(UserId, venueId, request));

    [HttpDelete("venues/{venueId:int}/staff/{staffUserId:int}")]
    public async Task<IActionResult> RemoveStaff(int venueId, int staffUserId)
        => Respond(await _config.RemoveStaff(UserId, venueId, staffUserId));

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
