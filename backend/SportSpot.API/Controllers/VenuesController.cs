using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VenuesController : ControllerBase
{
    private readonly IVenueService _venueService;

    public VenuesController(IVenueService venueService)
    {
        _venueService = venueService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<VenueListDto>>>> GetVenues(
        [FromQuery] int? sportId,
        [FromQuery] string? search,
        [FromQuery] double? userLat,
        [FromQuery] double? userLng,
        [FromQuery] double? radiusKm)
    {
        var result = await _venueService.GetVenuesAsync(sportId, search, userLat, userLng, radiusKm);
        return StatusCode(result.StatusCode, result);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<VenueDetailDto>>> GetVenueDetail(int id)
    {
        var result = await _venueService.GetVenueDetailAsync(id);
        return StatusCode(result.StatusCode, result);
    }

    [HttpGet("{id}/slots")]
    [HttpGet("{id}/subvenues/{subVenueId}/slots")]
    public async Task<ActionResult<ApiResponse<List<TimeSlotStatusDto>>>> GetVenueTimeSlots(
        int id,
        [FromQuery] int subVenueId,
        [FromQuery] DateOnly playDate)
    {
        var result = await _venueService.GetVenueTimeSlotsAsync(id, subVenueId, playDate);
        return StatusCode(result.StatusCode, result);
    }
}
