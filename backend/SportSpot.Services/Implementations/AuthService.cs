using System.Collections.Concurrent;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMemoryCache _cache;
    private readonly IJwtService _jwtService;
    private readonly ILogger<AuthService> _logger;

    private class OtpCacheItem
    {
        public string Code { get; set; } = string.Empty;
        public int AttemptCount { get; set; } = 0;
        public DateTime ExpiryUtc { get; set; } = DateTime.UtcNow.AddMinutes(5);
    }

    // Static dictionary đảm bảo OTP không bị mất giữa các request hoặc khi MemoryCache bị trôi
    private static readonly ConcurrentDictionary<string, OtpCacheItem> _persistentOtpStore = new();

    private static string NormalizePhone(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return string.Empty;
        var digits = new string(raw.Where(char.IsDigit).ToArray());
        if (digits.StartsWith("84") && digits.Length >= 10)
        {
            digits = "0" + digits[2..];
        }
        return digits;
    }

    public AuthService(
        IUnitOfWork unitOfWork,
        IMemoryCache cache,
        IJwtService jwtService,
        ILogger<AuthService> logger)
    {
        _unitOfWork = unitOfWork;
        _cache = cache;
        _jwtService = jwtService;
        _logger = logger;
    }

    public ApiResponse<object> SendOtp(RequestOtpDto request)
    {
        if (string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            return ApiResponse<object>.Fail("Số điện thoại không được để trống");
        }

        var phone = NormalizePhone(request.PhoneNumber);
        if (string.IsNullOrWhiteSpace(phone))
        {
            return ApiResponse<object>.Fail("Số điện thoại không hợp lệ");
        }

        // Sinh OTP 6 chữ số ngẫu nhiên (hoặc cố định 123456 cho số test đặc biệt)
        var otpCode = Random.Shared.Next(100000, 999999).ToString();
        if (phone.EndsWith("8888") || phone.EndsWith("9999"))
        {
            otpCode = "123456";
        }

        var cacheKey = $"OTP_{phone}";
        var cacheItem = new OtpCacheItem
        {
            Code = otpCode,
            AttemptCount = 0,
            ExpiryUtc = DateTime.UtcNow.AddSeconds(300)
        };

        // Lưu vào MemoryCache & PersistentStore với TTL 300 giây (5 phút)
        _cache.Set(cacheKey, cacheItem, TimeSpan.FromSeconds(300));
        _persistentOtpStore[phone] = cacheItem;

        // In OTP trực tiếp ra Console Terminal để nhóm test dễ dàng
        _logger.LogInformation("==================================================");
        _logger.LogInformation(">>> [SportSpot OTP] SĐT: {Phone} | MÃ OTP: {Code} (Hiệu lực: 300s)", phone, otpCode);
        _logger.LogInformation("==================================================");

        return ApiResponse<object>.Ok(new
        {
            phoneNumber = phone,
            expiresInSeconds = 300,
            debugOtp = otpCode // Giúp đồng đội xem nhanh trên Swagger/Postman/SnackBar
        }, "Mã OTP đã được gửi thành công. Vui lòng kiểm tra SMS hoặc Console Terminal.");
    }

    public async Task<ApiResponse<AuthResponseDto>> VerifyOtpAsync(VerifyOtpDto request)
    {
        if (string.IsNullOrWhiteSpace(request.PhoneNumber) || string.IsNullOrWhiteSpace(request.OtpCode))
        {
            return ApiResponse<AuthResponseDto>.Fail("Thiếu số điện thoại hoặc mã OTP");
        }

        var phone = NormalizePhone(request.PhoneNumber);
        var inputOtp = request.OtpCode.Trim();
        var cacheKey = $"OTP_{phone}";

        // Mã test tiện lợi cho dev/demo (BR-AUTH-05)
        var isMockDevOtp = inputOtp == "123456";

        if (!isMockDevOtp)
        {
            // Kiểm tra IMemoryCache trước, sau đó fallback sang _persistentOtpStore
            if (!_cache.TryGetValue<OtpCacheItem>(cacheKey, out var cacheItem))
            {
                _persistentOtpStore.TryGetValue(phone, out cacheItem);
            }

            if (cacheItem == null || cacheItem.ExpiryUtc < DateTime.UtcNow)
            {
                _logger.LogWarning(">>> [VerifyOtp] OTP không tồn tại hoặc đã hết hạn cho SĐT: {Phone}", phone);
                return ApiResponse<AuthResponseDto>.Fail("Mã OTP đã hết hạn hoặc chưa được gửi. Vui lòng yêu cầu mã mới.");
            }

            if (cacheItem.Code != inputOtp)
            {
                cacheItem.AttemptCount++;
                if (cacheItem.AttemptCount >= 3)
                {
                    _cache.Remove(cacheKey);
                    _persistentOtpStore.TryRemove(phone, out _);
                    return ApiResponse<AuthResponseDto>.Fail("Bạn đã nhập sai OTP quá 3 lần. Mã đã bị hủy, vui lòng yêu cầu mã mới.");
                }
                return ApiResponse<AuthResponseDto>.Fail($"Mã OTP không chính xác. Bạn còn {3 - cacheItem.AttemptCount} lần thử.");
            }

            // Đúng OTP -> xóa khỏi cache
            _cache.Remove(cacheKey);
            _persistentOtpStore.TryRemove(phone, out _);
        }

        _logger.LogInformation(">>> [VerifyOtp] Xác thực OTP thành công cho SĐT: {Phone}", phone);

        // Tự động tạo tài khoản mới nếu là Guest lần đầu đăng nhập (BR-AUTH-04)
        var user = await _unitOfWork.Users.GetByPhoneNumberAsync(phone);
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
            await _unitOfWork.Users.AddAsync(user);
            await _unitOfWork.SaveChangesAsync();
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

        return ApiResponse<AuthResponseDto>.Ok(response, "Xác thực OTP thành công. Chào mừng bạn đến với SportSpot!");
    }

    public async Task<ApiResponse<AuthResponseDto>> LoginAsync(LoginDto request)
    {
        var phone = NormalizePhone(request.PhoneNumber);
        var user = await _unitOfWork.Users.GetByPhoneNumberAsync(phone);
        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            return ApiResponse<AuthResponseDto>.Fail("Số điện thoại hoặc mật khẩu không chính xác", 401);
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

        return ApiResponse<AuthResponseDto>.Ok(response, "Đăng nhập thành công");
    }
}
