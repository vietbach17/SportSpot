using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MatchesController(IMatchService matches, IWebHostEnvironment environment) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] int? sportId, [FromQuery] string? district)
    {
        var result = await matches.GetOpenMatchesAsync(sportId, district);
        return StatusCode(result.StatusCode, result);
    }

    [Authorize, HttpGet("staff")]
    public async Task<IActionResult> Staff()
    {
        var result = await matches.GetStaffMatchesAsync(UserId);
        return StatusCode(result.StatusCode, result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Detail(int id)
    {
        var result = await matches.GetMatchAsync(id);
        return StatusCode(result.StatusCode, result);
    }

    [Authorize, HttpPost]
    public async Task<IActionResult> Create(CreateMatchRequest request)
    {
        var result = await matches.CreateMatchAsync(UserId, request);
        return StatusCode(result.StatusCode, result);
    }

    [Authorize, HttpGet("{id:int}/my-ticket")]
    public async Task<IActionResult> MyTicket(int id)
    {
        var result = await matches.GetMyTicketAsync(id, UserId);
        return StatusCode(result.StatusCode, result);
    }

    [Authorize, HttpPost("{id:int}/join")]
    public async Task<IActionResult> Join(int id, JoinMatchRequest request)
    {
        if (!environment.IsDevelopment())
            return StatusCode(503, ApiResponse<object>.Fail("Thanh toán mock chỉ hỗ trợ môi trường Development; tích hợp xác nhận thanh toán Module 5 để sử dụng thực tế", 503));
        request.UserId = UserId;
        var result = await matches.JoinMatchAsync(id, request);
        return StatusCode(result.StatusCode, result);
    }

    [Authorize, HttpPost("{id:int}/assign-walk-in")]
    public async Task<IActionResult> Assign(int id)
    {
        var result = await matches.AssignWalkInAtDeskAsync(id, UserId);
        return StatusCode(result.StatusCode, result);
    }

    [Authorize, HttpPut("{id:int}/stop-recruiting")]
    public async Task<IActionResult> Stop(int id)
    {
        var result = await matches.StopRecruitingAsync(id, UserId);
        return StatusCode(result.StatusCode, result);
    }

    [Authorize, HttpPost("{id:int}/leave")]
    public async Task<IActionResult> Leave(int id)
    {
        var result = await matches.LeaveMatchAsync(id, UserId);
        return StatusCode(result.StatusCode, result);
    }

    private int UserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;
}
