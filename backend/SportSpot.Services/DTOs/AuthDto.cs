namespace SportSpot.Services.DTOs;

public class RequestOtpDto
{
    public string PhoneNumber { get; set; } = string.Empty;
}

public class VerifyOtpDto
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string OtpCode { get; set; } = string.Empty;
    public string? FullName { get; set; }
}

public class LoginDto
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class AuthResponseDto
{
    public int UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Role { get; set; } = string.Empty;
    public int WalletBalance { get; set; }
    public string AccessToken { get; set; } = string.Empty;
}
