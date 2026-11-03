using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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

    [HttpGet("{id:int}/comments")]
    public async Task<IActionResult> GetComments(int id, [FromServices] SportSpot.Data.Context.SportSpotDbContext db)
    {
        var comments = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.ToListAsync(
            db.MatchComments
                .Include(c => c.User)
                .Where(c => c.MatchId == id)
                .OrderBy(c => c.CreatedAt)
                .Select(c => new MatchCommentDto
                {
                    Id = c.Id,
                    MatchId = c.MatchId,
                    UserId = c.UserId,
                    UserName = c.User != null ? c.User.FullName : "Thành viên",
                    UserAvatarUrl = c.User != null ? c.User.AvatarUrl : null,
                    Content = c.Content,
                    CreatedAt = c.CreatedAt
                })
        );
        return Ok(ApiResponse<List<MatchCommentDto>>.Ok(comments));
    }

    [HttpPost("{id:int}/comments")]
    public async Task<IActionResult> AddComment(int id, [FromBody] CreateMatchCommentRequest request, [FromServices] SportSpot.Data.Context.SportSpotDbContext db)
    {
        var uid = UserId > 0 ? UserId : 1;
        var user = await db.Users.FindAsync(uid);
        var match = await db.OpenMatches.FindAsync(id);
        if (match == null) return NotFound(ApiResponse<object>.Fail("Không tìm thấy trận đấu", 404));
        if (string.IsNullOrWhiteSpace(request.Content)) return BadRequest(ApiResponse<object>.Fail("Nội dung không được để trống", 400));

        var comment = new SportSpot.Data.Entities.MatchComment
        {
            MatchId = id,
            UserId = uid,
            Content = request.Content.Trim(),
            CreatedAt = DateTime.UtcNow
        };
        db.MatchComments.Add(comment);
        await db.SaveChangesAsync();

        var dto = new MatchCommentDto
        {
            Id = comment.Id,
            MatchId = comment.MatchId,
            UserId = comment.UserId,
            UserName = user?.FullName ?? "Thành viên",
            UserAvatarUrl = user?.AvatarUrl,
            Content = comment.Content,
            CreatedAt = comment.CreatedAt
        };
        return Ok(ApiResponse<MatchCommentDto>.Ok(dto, "Gửi bình luận thành công"));
    }

    private int UserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;
}
