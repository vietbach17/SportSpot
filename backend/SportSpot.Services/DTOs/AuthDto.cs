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
    /// <summary>
    /// Chấp nhận Email HOẶC Số điện thoại
    /// </summary>
    public string Identifier { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string Password { get; set; } = string.Empty;
}

public class RequestRegisterOtpDto
{
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
}

public class RegisterUserDto
{
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string OtpCode { get; set; } = string.Empty;
    public DateOnly? DateOfBirth { get; set; }
}

public class RequestPasswordOtpDto
{
    public string Email { get; set; } = string.Empty;
}

public class ChangePasswordWithOtpDto
{
    public string Email { get; set; } = string.Empty;
    public string OtpCode { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}

public class AuthResponseDto
{
    public int UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Role { get; set; } = string.Empty;
    public int WalletBalance { get; set; }
    public string? AvatarUrl { get; set; }
    public DateOnly? DateOfBirth { get; set; }
    public string AccessToken { get; set; } = string.Empty;
}
