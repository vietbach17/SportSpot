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

    [HttpPost("send-otp")]
    [HttpPost("otp/request")]
    public ActionResult<ApiResponse<object>> SendOtp([FromBody] RequestOtpDto request)
    {
        var result = _authService.SendOtp(request);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPost("verify-otp")]
    [HttpPost("otp/verify")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> VerifyOtp([FromBody] VerifyOtpDto request)
    {
        var result = await _authService.VerifyOtpAsync(request);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Login([FromBody] LoginDto request)
    {
        var result = await _authService.LoginAsync(request);
        return StatusCode(result.StatusCode, result);
    }
}
