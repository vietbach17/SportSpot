using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IAuthService
{
    ApiResponse<object> SendOtp(RequestOtpDto request);
    Task<ApiResponse<AuthResponseDto>> VerifyOtpAsync(VerifyOtpDto request);
    Task<ApiResponse<AuthResponseDto>> LoginAsync(LoginDto request);

    // Mới: Đăng ký với Email OTP & Đổi mật khẩu
    Task<ApiResponse<object>> SendRegisterEmailOtpAsync(RequestRegisterOtpDto request);
    Task<ApiResponse<AuthResponseDto>> RegisterWithEmailOtpAsync(RegisterUserDto request);
    Task<ApiResponse<object>> SendChangePasswordOtpAsync(RequestPasswordOtpDto request);
    Task<ApiResponse<bool>> ChangePasswordWithOtpAsync(ChangePasswordWithOtpDto request);
}
