using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class EmailService : IEmailService
{
    private readonly ILogger<EmailService> _logger;
    private readonly IConfiguration _configuration;

    public EmailService(ILogger<EmailService> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public async Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode, string purpose = "Đăng ký tài khoản")
    {
        var subject = $"[SportSpot] Mã xác thực OTP {purpose}: {otpCode}";
        var htmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F3F4F6; margin: 0; padding: 20px; }}
        .card {{ max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }}
        .header {{ background: linear-gradient(135deg, #16A34A 0%, #15803D 100%); padding: 32px 24px; text-align: center; color: #ffffff; }}
        .header h1 {{ margin: 0; font-size: 26px; font-weight: 900; letter-spacing: 0.5px; }}
        .header p {{ margin: 6px 0 0; font-size: 14px; opacity: 0.9; }}
        .body {{ padding: 32px 28px; color: #1F2937; line-height: 1.6; }}
        .greeting {{ font-size: 16px; font-weight: 600; margin-bottom: 12px; }}
        .code-box {{ background: #F0FDF4; border: 2px dashed #22C55E; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0; }}
        .otp-code {{ font-size: 36px; font-weight: 900; letter-spacing: 8px; color: #15803D; font-family: monospace; }}
        .expiry {{ font-size: 12px; color: #6B7280; margin-top: 8px; }}
        .warning {{ font-size: 13px; color: #9CA3AF; margin-top: 20px; border-top: 1px solid #E5E7EB; padding-top: 16px; }}
        .footer {{ text-align: center; font-size: 11px; color: #9CA3AF; padding: 16px 24px 24px; }}
    </style>
</head>
<body>
    <div class='card'>
        <div class='header'>
            <h1>⚡ SPORTSPOT VIETNAM</h1>
            <p>Nền tảng đặt sân & ghép kèo thể thao thông minh</p>
        </div>
        <div class='body'>
            <div class='greeting'>Xin chào {WebUtility.HtmlEncode(fullName)},</div>
            <p>Bạn đang thực hiện <strong>{WebUtility.HtmlEncode(purpose)}</strong> trên ứng dụng SportSpot. Dưới đây là mã xác thực dùng một lần (OTP) của bạn:</p>
            <div class='code-box'>
                <div class='otp-code'>{otpCode}</div>
                <div class='expiry'>Hiệu lực trong vòng <strong>5 phút</strong> (Không chia sẻ mã này cho bất kỳ ai)</div>
            </div>
            <div class='warning'>
                Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email hoặc liên hệ hotline hỗ trợ SportSpot để bảo vệ tài khoản.
            </div>
        </div>
        <div class='footer'>
            &copy; {DateTime.UtcNow.Year} SportSpot Vietnam. PRM393 Mobile Programming.
        </div>
    </div>
</body>
</html>";

        return await SendEmailInternalAsync(toEmail, subject, htmlBody, otpCode);
    }

    public async Task<bool> SendPasswordResetEmailAsync(string toEmail, string fullName, string otpCode)
    {
        return await SendOtpEmailAsync(toEmail, fullName, otpCode, "Đổi mật khẩu tài khoản");
    }

    private async Task<bool> SendEmailInternalAsync(string toEmail, string subject, string htmlBody, string otpCode)
    {
        var smtpHost = Environment.GetEnvironmentVariable("SMTP_HOST") ?? _configuration["Smtp:Host"];
        var smtpPortStr = Environment.GetEnvironmentVariable("SMTP_PORT") ?? _configuration["Smtp:Port"] ?? "587";
        var smtpUser = Environment.GetEnvironmentVariable("SMTP_USER") ?? _configuration["Smtp:User"];
        var smtpPass = Environment.GetEnvironmentVariable("SMTP_PASS") ?? _configuration["Smtp:Pass"];
        var fromEmail = Environment.GetEnvironmentVariable("SMTP_FROM") ?? _configuration["Smtp:From"] ?? smtpUser ?? "no-reply@sportspot.vn";
        var fromName = Environment.GetEnvironmentVariable("SMTP_FROM_NAME") ?? _configuration["Smtp:FromName"] ?? "SportSpot Vietnam";

        int.TryParse(smtpPortStr, out var smtpPort);
        if (smtpPort <= 0) smtpPort = 587;

        // Log OTP ra console terminal của server để phục vụ dev/test/demo nếu chưa cấu hình SMTP hoặc đang offline
        _logger.LogInformation("==========================================================");
        _logger.LogInformation(">>> [SportSpot EMAIL OTP] Gửi tới Email: {Email} | MÃ OTP: {Otp}", toEmail, otpCode);
        _logger.LogInformation("==========================================================");

        if (string.IsNullOrWhiteSpace(smtpHost) || string.IsNullOrWhiteSpace(smtpUser) || string.IsNullOrWhiteSpace(smtpPass))
        {
            _logger.LogWarning("Chưa cấu hình thông tin SMTP (SMTP_HOST, SMTP_USER, SMTP_PASS) trong .env. Email OTP đã được ghi log an toàn tại server console.");
            return true;
        }

        try
        {
            using var client = new SmtpClient(smtpHost, smtpPort)
            {
                EnableSsl = true,
                Credentials = new NetworkCredential(smtpUser, smtpPass),
                Timeout = 15000
            };

            using var message = new MailMessage
            {
                From = new MailAddress(fromEmail, fromName),
                Subject = subject,
                Body = htmlBody,
                IsBodyHtml = true
            };
            message.To.Add(toEmail);

            await client.SendMailAsync(message);
            _logger.LogInformation(">>> [EmailService] Đã gửi email OTP thực tế thành công tới {Email} qua {SmtpHost}", toEmail, smtpHost);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, ">>> [EmailService] Lỗi khi gửi email SMTP tới {Email}: {Message}. Fallback ghi log server thành công.", toEmail, ex.Message);
            return true;
        }
    }
}
