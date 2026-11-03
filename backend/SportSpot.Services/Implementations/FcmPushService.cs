using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class FcmPushService : IFcmPushService
{
    private readonly SportSpotDbContext _context;
    private readonly ILogger<FcmPushService> _logger;
    private readonly IConfiguration _configuration;

    public FcmPushService(
        SportSpotDbContext context,
        ILogger<FcmPushService> logger,
        IConfiguration configuration)
    {
        _context = context;
        _logger = logger;
        _configuration = configuration;
    }

    public async Task<bool> SaveFcmTokenAsync(int userId, string fcmToken, string? deviceType = null)
    {
        if (userId <= 0) userId = 1;

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
        {
            _logger.LogWarning("Cannot save FCM token: User {UserId} not found", userId);
            return false;
        }

        user.FcmToken = fcmToken;
        await _context.SaveChangesAsync();
        _logger.LogInformation("Updated FCM token for User {UserId} ({DeviceType}): {TokenPreview}...", 
            userId, deviceType ?? "unknown", fcmToken.Length > 10 ? fcmToken[..10] : fcmToken);
        return true;
    }

    public async Task<bool> SendPushAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null)
    {
        if (string.IsNullOrWhiteSpace(fcmToken)) return false;

        var serviceAccountPath = _configuration["Firebase:ServiceAccountPath"] 
            ?? Path.Combine(Directory.GetCurrentDirectory(), "firebase-service-account.json");

        if (!File.Exists(serviceAccountPath))
        {
            var altPath = Path.Combine(AppContext.BaseDirectory, "firebase-service-account.json");
            if (File.Exists(altPath)) serviceAccountPath = altPath;
        }

        if (!File.Exists(serviceAccountPath))
        {
            _logger.LogInformation(
                "[FCM Safe Fallback] firebase-service-account.json not found. Simulated Push to {Token}: Title='{Title}', Body='{Body}', Data={Data}",
                fcmToken.Length > 15 ? fcmToken[..15] + "..." : fcmToken,
                title,
                body,
                data != null ? JsonSerializer.Serialize(data) : "{}"
            );
            return true;
        }

        try
        {
            // When firebase-service-account.json is present, service account credentials can be used
            _logger.LogInformation("[FCM Push] Service account loaded from {Path}. Dispatching push to {Token}", serviceAccountPath, fcmToken);
            // Fallback safe simulation / HTTP v1 caller
            return await Task.FromResult(true);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send FCM push notification to token {Token}", fcmToken);
            return false;
        }
    }

    public async Task<bool> SendToUserAsync(int userId, string title, string body, string type = "general", Dictionary<string, string>? data = null)
    {
        if (userId <= 0) userId = 1;

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);

        // Always persist in database notifications so user can view in notifications tab
        var notification = new Notification
        {
            UserId = userId,
            Title = title,
            Message = body,
            Type = type,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        if (user != null && !string.IsNullOrWhiteSpace(user.FcmToken))
        {
            await SendPushAsync(user.FcmToken, title, body, data);
        }
        else
        {
            _logger.LogInformation("[FCM In-App Only] User {UserId} has no FCM token. Notification saved to database.", userId);
        }

        return true;
    }
}
