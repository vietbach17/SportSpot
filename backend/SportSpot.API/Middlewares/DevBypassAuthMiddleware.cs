using System.Security.Claims;

namespace SportSpot.API.Middlewares;

/// <summary>
/// Middleware hỗ trợ test nội bộ:
/// Cho phép client gửi header "X-Mock-User-Id: <id>" để giả lập user đăng nhập
/// mà không bắt buộc phải lấy JWT thật trong quá trình phát triển/kiểm thử.
/// </summary>
public class DevBypassAuthMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<DevBypassAuthMiddleware> _logger;

    public DevBypassAuthMiddleware(RequestDelegate next, ILogger<DevBypassAuthMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Headers.TryGetValue("X-Mock-User-Id", out var mockUserIdHeader))
        {
            var userIdStr = mockUserIdHeader.ToString();
            if (int.TryParse(userIdStr, out var userId))
            {
                var claims = new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
                    new Claim(ClaimTypes.Role, "Player"),
                    new Claim(ClaimTypes.Name, $"DevUser_{userId}")
                };

                var identity = new ClaimsIdentity(claims, "DevBypass");
                context.User = new ClaimsPrincipal(identity);
                _logger.LogInformation(">>> [DevBypassAuth] Giả lập đăng nhập thành công với UserId: {UserId}", userId);
            }
        }

        await _next(context);
    }
}
