using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using SportSpot.API.Data;
using SportSpot.API.DTOs;
using SportSpot.API.Models;
using SportSpot.API.Services;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly SportSpotDbContext _context;
    private readonly IMemoryCache _cache;
    private readonly IJwtService _jwtService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        SportSpotDbContext context,
        IMemoryCache cache,
        IJwtService jwtService,
        ILogger<AuthController> logger)
    {
        _context = context;
        _cache = cache;
        _jwtService = jwtService;
        _logger = logger;
    }

    private class OtpCacheItem
    {
        public string Code { get; set; } = string.Empty;
        public int AttemptCount { get; set; } = 0;
    }

    /// <summary>
    /// POST /api/auth/send-otp: Nhận SĐT, sinh OTP 6 số ngẫu nhiên, lưu Cache 120s, in ra console.
    /// </summary>
    [HttpPost("send-otp")]
    [HttpPost("otp/request")] // Alias tương thích
    public ActionResult<ApiResponse<object>> SendOtp([FromBody] RequestOtpDto request)
    {
        if (string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            return BadRequest(ApiResponse<object>.Fail("Số điện thoại không được để trống"));
        }

        var phone = request.PhoneNumber.Trim();

        // Sinh OTP 6 chữ số ngẫu nhiên (hoặc cố định 123456 cho số test đặc biệt)
        var otpCode = Random.Shared.Next(100000, 999999).ToString();
        if (phone.EndsWith("8888") || phone.EndsWith("9999"))
        {
            otpCode = "123456"; // Mã cố định cho số máy test
        }

        var cacheKey = $"OTP_{phone}";
        var cacheItem = new OtpCacheItem
        {
            Code = otpCode,
            AttemptCount = 0
        };

        // Lưu vào MemoryCache với TTL 120 giây
        _cache.Set(cacheKey, cacheItem, TimeSpan.FromSeconds(120));

        // In OTP trực tiếp ra Console Terminal để nhóm test dễ dàng
        _logger.LogInformation("==================================================");
        _logger.LogInformation(">>> [SportSpot OTP] SĐT: {Phone} | MÃ OTP: {Code} (Hiệu lực: 120s)", phone, otpCode);
        _logger.LogInformation("==================================================");

        return Ok(ApiResponse<object>.Ok(new
        {
            phoneNumber = phone,
            expiresInSeconds = 120,
            debugOtp = otpCode // Giúp đồng đội xem nhanh trên Swagger/Postman
        }, "Mã OTP đã được gửi thành công. Vui lòng kiểm tra SMS hoặc Console Terminal."));
    }

    /// <summary>
    /// POST /api/auth/verify-otp: Kiểm tra OTP, đếm số lần sai (quá 3 lần thì hủy), cấp JWT Token thật.
    /// </summary>
    [HttpPost("verify-otp")]
    [HttpPost("otp/verify")] // Alias tương thích
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> VerifyOtp([FromBody] VerifyOtpDto request)
    {
        if (string.IsNullOrWhiteSpace(request.PhoneNumber) || string.IsNullOrWhiteSpace(request.OtpCode))
        {
            return BadRequest(ApiResponse<AuthResponseDto>.Fail("Thiếu số điện thoại hoặc mã OTP"));
        }

        var phone = request.PhoneNumber.Trim();
        var cacheKey = $"OTP_{phone}";

        // Kiểm tra OTP trong Cache (hoặc backdoor 123456 cho môi trường dev/demo theo BR-AUTH-05)
        var isMockDevOtp = request.OtpCode == "123456";
        
        if (!_cache.TryGetValue<OtpCacheItem>(cacheKey, out var cacheItem) && !isMockDevOtp)
        {
            return BadRequest(ApiResponse<AuthResponseDto>.Fail("Mã OTP đã hết hạn hoặc chưa được gửi. Vui lòng yêu cầu mã mới."));
        }

        if (!isMockDevOtp && cacheItem != null)
        {
            if (cacheItem.Code != request.OtpCode)
            {
                cacheItem.AttemptCount++;
                if (cacheItem.AttemptCount >= 3)
                {
                    _cache.Remove(cacheKey);
                    return BadRequest(ApiResponse<AuthResponseDto>.Fail("Bạn đã nhập sai OTP quá 3 lần. Mã đã bị hủy, vui lòng yêu cầu mã mới."));
                }
                return BadRequest(ApiResponse<AuthResponseDto>.Fail($"Mã OTP không chính xác. Bạn còn {3 - cacheItem.AttemptCount} lần thử."));
            }

            // Đúng OTP -> xóa khỏi cache
            _cache.Remove(cacheKey);
        }

        // Tự động tạo tài khoản mới nếu là Guest lần đầu đăng nhập (BR-AUTH-04)
        var user = await _context.Users.FirstOrDefaultAsync(u => u.PhoneNumber == phone);
        if (user == null)
        {
            user = new User
            {
                PhoneNumber = phone,
                FullName = !string.IsNullOrWhiteSpace(request.FullName) 
                    ? request.FullName.Trim() 
                    : $"Khách {phone[^Math.Min(4, phone.Length)..]}",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("SportSpot@123"),
                Role = "Player",
                WalletBalance = 0,
                IsFindMatchEnabled = false,
                FavoriteSports = "Cầu lông,Bóng đá mini",
                CreatedAt = DateTime.UtcNow
            };
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
        }

        // Sinh JWT Token thật
        var token = _jwtService.GenerateToken(user);

        var response = new AuthResponseDto
        {
            UserId = user.Id,
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            Email = user.Email,
            Role = user.Role,
            WalletBalance = user.WalletBalance,
            AccessToken = token
        };

        return Ok(ApiResponse<AuthResponseDto>.Ok(response, "Xác thực OTP thành công. Chào mừng bạn đến với SportSpot!"));
    }

    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Login([FromBody] LoginDto request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.PhoneNumber == request.PhoneNumber);
        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            return BadRequest(ApiResponse<AuthResponseDto>.Fail("Số điện thoại hoặc mật khẩu không chính xác", 401));
        }

        var token = _jwtService.GenerateToken(user);

        var response = new AuthResponseDto
        {
            UserId = user.Id,
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            Email = user.Email,
            Role = user.Role,
            WalletBalance = user.WalletBalance,
            AccessToken = token
        };

        return Ok(ApiResponse<AuthResponseDto>.Ok(response, "Đăng nhập thành công"));
    }
}
