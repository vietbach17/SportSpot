using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    /// <summary>
    /// Đăng nhập bằng Email hoặc Số điện thoại + Mật khẩu (Không gửi OTP)
    /// </summary>
    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Login([FromBody] LoginDto request)
    {
        var result = await _authService.LoginAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// Gửi mã xác thực OTP qua Email thật khi Đăng ký tài khoản
    /// </summary>
    [HttpPost("register-otp")]
    [HttpPost("otp/register-email")]
    public async Task<ActionResult<ApiResponse<object>>> SendRegisterEmailOtp([FromBody] RequestRegisterOtpDto request)
    {
        var result = await _authService.SendRegisterEmailOtpAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// Xác thực OTP Email và hoàn tất Đăng ký tài khoản người dùng
    /// </summary>
    [HttpPost("register-verify")]
    [HttpPost("register")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> RegisterWithEmailOtp([FromBody] RegisterUserDto request)
    {
        var result = await _authService.RegisterWithEmailOtpAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// Gửi mã OTP qua Email để yêu cầu Đổi mật khẩu
    /// </summary>
    [HttpPost("change-password-otp")]
    [HttpPost("forgot-password-otp")]
    public async Task<ActionResult<ApiResponse<object>>> SendChangePasswordOtp([FromBody] RequestPasswordOtpDto request)
    {
        var result = await _authService.SendChangePasswordOtpAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// Xác thực mã OTP và cập nhật Mật khẩu mới
    /// </summary>
    [HttpPost("change-password")]
    [HttpPost("reset-password")]
    public async Task<ActionResult<ApiResponse<bool>>> ChangePasswordWithOtp([FromBody] ChangePasswordWithOtpDto request)
    {
        var result = await _authService.ChangePasswordWithOtpAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// [Legacy] Gửi OTP qua SĐT (Tương thích ngược)
    /// </summary>
    [HttpPost("send-otp")]
    [HttpPost("otp/request")]
    public ActionResult<ApiResponse<object>> SendOtp([FromBody] RequestOtpDto request)
    {
        var result = _authService.SendOtp(request);
        return StatusCode(result.StatusCode, result);
    }

    /// <summary>
    /// [Legacy] Xác thực OTP qua SĐT (Tương thích ngược)
    /// </summary>
    [HttpPost("verify-otp")]
    [HttpPost("otp/verify")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> VerifyOtp([FromBody] VerifyOtpDto request)
    {
        var result = await _authService.VerifyOtpAsync(request);
        return StatusCode(result.StatusCode, result);
    }
}
