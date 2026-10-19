using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportSpot.API.Data;
using SportSpot.API.DTOs;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SportsController : ControllerBase
{
    private readonly SportSpotDbContext _context;

    public SportsController(SportSpotDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<SportDto>>>> GetSports()
    {
        var sports = await _context.Sports
            .Select(s => new SportDto
            {
                Id = s.Id,
                Name = s.Name,
                IconUrl = s.IconUrl,
                VenueCount = s.Venues.Count(v => v.IsActive)
            })
            .ToListAsync();

        return Ok(ApiResponse<List<SportDto>>.Ok(sports, "Lấy danh sách môn thể thao thành công"));
    }
}
