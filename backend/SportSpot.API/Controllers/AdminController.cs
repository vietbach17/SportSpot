using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Implementations;

namespace SportSpot.API.Controllers;

[ApiController, Authorize(Roles = "Admin"), Route("api/admin")]
public class AdminController(AdminService service) : ControllerBase
{
    private int UserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    [HttpGet("overview")]
    public async Task<IActionResult> Overview() => Respond(await service.Overview(UserId));

    [HttpGet("venues")]
    public async Task<IActionResult> Venues() => Respond(await service.Venues(UserId));

    [HttpGet("accounts")]
    public async Task<IActionResult> Users() => Respond(await service.Users(UserId));

    [HttpGet("users")]
    public async Task<IActionResult> UsersAlias() => Respond(await service.Users(UserId));

    [HttpPost("venues/{id:int}/review")]
    public async Task<IActionResult> Review(int id, [FromBody] ReviewVenueRequest request) => Respond(await service.Review(UserId, id, request));

    [HttpPut("accounts/{id:int}/status")]
    public async Task<IActionResult> UserStatus(int id, [FromBody] SetActiveRequest request) => Respond(await service.SetUserActive(UserId, id, request.IsActive));

    [HttpPut("accounts/{id:int}/role-venue")]
    public async Task<IActionResult> AssignRoleVenue(int id, [FromBody] AssignRoleVenueRequest request) => Respond(await service.AssignRoleAndVenue(UserId, id, request));

    [HttpPut("venues/{id:int}/status")]
    public async Task<IActionResult> VenueStatus(int id, [FromBody] SetActiveRequest request) => Respond(await service.SetVenueActive(UserId, id, request.IsActive));

    private ObjectResult Respond<T>(ApiResponse<T> result) => StatusCode(result.StatusCode, result);
}
