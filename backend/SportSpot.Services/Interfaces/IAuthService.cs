using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IAuthService
{
    ApiResponse<object> SendOtp(RequestOtpDto request);
    Task<ApiResponse<AuthResponseDto>> VerifyOtpAsync(VerifyOtpDto request);
    Task<ApiResponse<AuthResponseDto>> LoginAsync(LoginDto request);
}
