using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FavoritesController : ControllerBase
{
    private readonly IVenueService _venueService;

    public FavoritesController(IVenueService venueService)
    {
        _venueService = venueService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<int>>>> GetFavoriteVenueIds([FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        var result = await _venueService.GetFavoriteVenueIdsAsync(uid);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPost("{venueId}/toggle")]
    public async Task<ActionResult<ApiResponse<FavoriteToggleResultDto>>> ToggleFavorite(int venueId, [FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        var result = await _venueService.ToggleFavoriteAsync(venueId, uid);
        return StatusCode(result.StatusCode, result);
    }

    private int GetCurrentUserId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claimValue, out var id) ? id : 0;
    }
}
