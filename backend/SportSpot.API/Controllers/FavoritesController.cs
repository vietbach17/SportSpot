using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Services.DTOs;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FavoritesController : ControllerBase
{
    private readonly SportSpotDbContext _context;

    public FavoritesController(SportSpotDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<int>>>> GetFavoriteVenueIds([FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;

        var favoriteIds = await _context.FavoriteVenues
            .Where(f => f.UserId == uid)
            .Select(f => f.VenueId)
            .ToListAsync();

        return Ok(ApiResponse<List<int>>.Ok(favoriteIds));
    }

    [HttpPost("{venueId}/toggle")]
    public async Task<ActionResult<ApiResponse<FavoriteToggleResultDto>>> ToggleFavorite(int venueId, [FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;

        var existing = await _context.FavoriteVenues
            .FirstOrDefaultAsync(f => f.UserId == uid && f.VenueId == venueId);

        bool isFavorite;
        string message;

        if (existing != null)
        {
            _context.FavoriteVenues.Remove(existing);
            isFavorite = false;
            message = "Đã bỏ yêu thích cụm sân";
        }
        else
        {
            _context.FavoriteVenues.Add(new FavoriteVenue
            {
                UserId = uid,
                VenueId = venueId,
                CreatedAt = DateTime.UtcNow
            });
            isFavorite = true;
            message = "Đã thêm sân vào danh sách yêu thích";
        }

        await _context.SaveChangesAsync();

        return Ok(ApiResponse<FavoriteToggleResultDto>.Ok(new FavoriteToggleResultDto
        {
            VenueId = venueId,
            IsFavorite = isFavorite,
            Message = message
        }, message));
    }

    private int GetCurrentUserId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claimValue, out var id) ? id : 0;
    }
}
