using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IFcmPushService _fcmPushService;

    public UsersController(
        IUserService userService,
        IFcmPushService fcmPushService)
    {
        _userService = userService;
        _fcmPushService = fcmPushService;
    }

    [HttpGet("me")]
    public async Task<ActionResult<ApiResponse<UserProfileDto>>> GetMyProfile()
    {
        var result = await _userService.GetMyProfileAsync(GetCurrentUserId());
        return StatusCode(result.StatusCode, result);
    }

    [HttpPut("profile")]
    public async Task<ActionResult<ApiResponse<UserProfileDto>>> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        var result = await _userService.UpdateProfileAsync(GetCurrentUserId(), request);
        return StatusCode(result.StatusCode, result);
    }

    [HttpGet("skills")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<List<UserSkillDto>>>> GetUserSkills([FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;
        var result = await _userService.GetUserSkillsAsync(uid);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPost("skills")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<List<UserSkillDto>>>> SaveUserSkills([FromBody] UpdateUserSkillsRequest request, [FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;
        var result = await _userService.SaveUserSkillsAsync(uid, request);
        return StatusCode(result.StatusCode, result);
    }

    [HttpGet("/api/admin/users")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ApiResponse<List<object>>>> GetAllUsers([FromServices] SportSpotDbContext db)
    {
        var users = await db.Users
            .OrderBy(u => u.Id)
            .Select(u => new
            {
                id = u.Id,
                name = u.FullName,
                email = u.Email ?? "",
                phone = u.PhoneNumber,
                role = u.Role,
                isActive = u.IsActive,
                joinDate = u.CreatedAt.ToString("dd/MM/yyyy"),
                walletBalance = u.WalletBalance,
                avatarUrl = u.AvatarUrl,
            })
            .ToListAsync();

        return Ok(ApiResponse<List<object>>.Ok(users.Cast<object>().ToList(), "Lấy danh sách người dùng thành công"));
    }

    [HttpPost("fcm-token")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<bool>>> SaveFcmToken([FromBody] SaveFcmTokenRequest request)
    {
        var uid = request.UserId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;
        var success = await _fcmPushService.SaveFcmTokenAsync(uid, request.FcmToken, request.DeviceType);
        return Ok(ApiResponse<bool>.Ok(success, "Lưu FCM Token thành công"));
    }

    private int GetCurrentUserId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claimValue, out var id) ? id : 0;
    }
}
