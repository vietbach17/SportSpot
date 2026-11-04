namespace SportSpot.Services.Interfaces;

public interface IEmailService
{
    Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode, string purpose = "Đăng ký tài khoản");
    Task<bool> SendPasswordResetEmailAsync(string toEmail, string fullName, string otpCode);
}
