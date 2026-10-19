using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportSpot.API.Data;
using SportSpot.API.DTOs;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Bắt buộc đăng nhập JWT (hoặc qua DevBypassAuthMiddleware với header X-Mock-User-Id)
public class UsersController : ControllerBase
{
    private readonly SportSpotDbContext _context;

    public UsersController(SportSpotDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// GET /api/users/me: Trả về thông tin cá nhân của user đang đăng nhập từ JWT Claims.
    /// </summary>
    [HttpGet("me")]
    public async Task<ActionResult<ApiResponse<UserProfileDto>>> GetMyProfile()
    {
        var userId = GetCurrentUserId();
        if (userId <= 0)
        {
            return Unauthorized(ApiResponse<UserProfileDto>.Fail("Không xác định được danh tính người dùng", 401));
        }

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound(ApiResponse<UserProfileDto>.Fail("Không tìm thấy thông tin người dùng", 404));
        }

        var profile = new UserProfileDto
        {
            UserId = user.Id,
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            Email = user.Email,
            Role = user.Role,
            WalletBalance = user.WalletBalance,
            AvatarUrl = user.AvatarUrl,
            IsFindMatchEnabled = user.IsFindMatchEnabled,
            FavoriteSports = user.FavoriteSports
        };

        return Ok(ApiResponse<UserProfileDto>.Ok(profile, "Lấy thông tin người dùng thành công"));
    }

    /// <summary>
    /// PUT /api/users/profile: Cập nhật Họ tên, Email, cài đặt is_find_match_enabled và favorite_sports.
    /// </summary>
    [HttpPut("profile")]
    public async Task<ActionResult<ApiResponse<UserProfileDto>>> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        var userId = GetCurrentUserId();
        if (userId <= 0)
        {
            return Unauthorized(ApiResponse<UserProfileDto>.Fail("Không xác định được danh tính người dùng", 401));
        }

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound(ApiResponse<UserProfileDto>.Fail("Không tìm thấy thông tin người dùng", 404));
        }

        // Cập nhật các trường được gửi lên
        if (!string.IsNullOrWhiteSpace(request.FullName))
        {
            user.FullName = request.FullName.Trim();
        }

        if (request.Email != null)
        {
            user.Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim();
        }

        if (request.IsFindMatchEnabled.HasValue)
        {
            user.IsFindMatchEnabled = request.IsFindMatchEnabled.Value;
        }

        if (request.FavoriteSports != null)
        {
            user.FavoriteSports = request.FavoriteSports.Trim();
        }

        if (request.AvatarUrl != null)
        {
            user.AvatarUrl = request.AvatarUrl.Trim();
        }

        await _context.SaveChangesAsync();

        var updatedProfile = new UserProfileDto
        {
            UserId = user.Id,
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            Email = user.Email,
            Role = user.Role,
            WalletBalance = user.WalletBalance,
            AvatarUrl = user.AvatarUrl,
            IsFindMatchEnabled = user.IsFindMatchEnabled,
            FavoriteSports = user.FavoriteSports
        };

        return Ok(ApiResponse<UserProfileDto>.Ok(updatedProfile, "Cập nhật hồ sơ cá nhân thành công"));
    }

    private int GetCurrentUserId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claimValue, out var id) ? id : 0;
    }
}
