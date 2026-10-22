using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CourtsController : ControllerBase
{
    private readonly IVenueService _venueService;

    public CourtsController(IVenueService venueService)
    {
        _venueService = venueService;
    }

    [HttpGet("{subVenueId}/slots")]
    public async Task<ActionResult<ApiResponse<List<TimeSlotStatusDto>>>> GetCourtSlots(
        int subVenueId,
        [FromQuery] int? venueId,
        [FromQuery] DateOnly? date,
        [FromQuery] DateOnly? playDate)
    {
        var targetDate = date ?? playDate ?? DateOnly.FromDateTime(DateTime.Now);
        var targetVenueId = venueId ?? 1;
        var result = await _venueService.GetVenueTimeSlotsAsync(targetVenueId, subVenueId, targetDate);
        return StatusCode(result.StatusCode, result);
    }
}
