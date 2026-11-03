using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class OwnerController : ControllerBase
{
    private readonly IOwnerService _ownerService;

    public OwnerController(IOwnerService ownerService)
    {
        _ownerService = ownerService;
    }

    /// <summary>
    /// GET /api/owner/dashboard?venueId={venueId}: Bảng thống kê doanh thu, tỷ lệ lấp đầy và quản lý sân cho chủ sân.
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<ApiResponse<OwnerDashboardDto>>> GetDashboard([FromQuery] int? venueId)
    {
        var targetVenueId = venueId.HasValue && venueId.Value > 0 ? venueId.Value : 1;
        var result = await _ownerService.GetOwnerDashboardAsync(targetVenueId);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// PUT /api/owner/subvenues/{subVenueId}/toggle-status: Bật/tắt trạng thái bảo trì hoặc hoạt động của sân con.
    /// </summary>
    [HttpPut("subvenues/{subVenueId}/toggle-status")]
    public async Task<ActionResult<ApiResponse<bool>>> ToggleSubVenueStatus(int subVenueId, [FromBody] ToggleSubVenueRequest? request)
    {
        var result = await _ownerService.ToggleSubVenueStatusAsync(subVenueId, request?.IsActive);
        return StatusCode(result.StatusCode, result);
    }
}
