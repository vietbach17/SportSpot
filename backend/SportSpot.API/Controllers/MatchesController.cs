using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MatchesController : ControllerBase
{
    private readonly IMatchService _matchService;

    public MatchesController(IMatchService matchService)
    {
        _matchService = matchService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<OpenMatchDto>>>> GetOpenMatches(
        [FromQuery] int? sportId,
        [FromQuery] string? district)
    {
        var result = await _matchService.GetOpenMatchesAsync(sportId, district);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPost("{id}/join")]
    public async Task<ActionResult<ApiResponse<object>>> JoinMatch(int id, [FromBody] JoinMatchRequest request)
    {
        if (request.UserId <= 0)
        {
            request.UserId = GetCurrentUserId();
        }
        var result = await _matchService.JoinMatchAsync(id, request);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPost("{id}/assign-walk-in")]
    public async Task<ActionResult<ApiResponse<object>>> AssignWalkIn(int id)
    {
        var result = await _matchService.AssignWalkInAtDeskAsync(id);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPut("{id}/stop-recruiting")]
    public async Task<ActionResult<ApiResponse<object>>> StopRecruiting(int id, [FromQuery] int? hostUserId)
    {
        var uid = hostUserId ?? GetCurrentUserId();
        var result = await _matchService.StopRecruitingAsync(id, uid);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPost("{id}/leave")]
    public async Task<ActionResult<ApiResponse<object>>> LeaveMatch(int id, [FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        var result = await _matchService.LeaveMatchAsync(id, uid);
        return StatusCode(result.StatusCode, result);
    }

    private int GetCurrentUserId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claimValue, out var id) ? id : 0;
    }
}
