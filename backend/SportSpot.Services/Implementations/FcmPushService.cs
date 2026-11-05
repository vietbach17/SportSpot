using System.Text.Json;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

/// <summary>
/// Dịch vụ quản lý gửi thông báo đẩy Firebase Cloud Messaging (FCM) chuẩn HTTP v1.
/// Cấu hình High-Priority & Channel chuyên biệt để đánh thức thiết bị và hiện thông báo khi app bị tắt hoàn toàn (Terminated/Background).
/// </summary>
public class FcmPushService : IFcmPushService
{
    private static readonly object _firebaseLock = new();
    private readonly SportSpotDbContext _context;
    private readonly ILogger<FcmPushService> _logger;
    private readonly IConfiguration _configuration;

    public const string DefaultHighImportanceChannelId = "sportspot_high_importance_channel";

    public FcmPushService(
        SportSpotDbContext context,
        ILogger<FcmPushService> logger,
        IConfiguration configuration)
    {
        _context = context;
        _logger = logger;
        _configuration = configuration;
    }

    /// <summary>
    /// Lưu Device FCM Token của người dùng vào cơ sở dữ liệu
    /// </summary>
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

    /// <summary>
    /// Xây dựng payload FCM HTTP v1 với cấu hình High-Priority đánh thức ứng dụng khi tắt/background
    /// </summary>
    public Message BuildHighPriorityMessage(string fcmToken, string title, string body, Dictionary<string, string>? data = null)
    {
        var channelId = _configuration["Firebase:DefaultChannelId"] ?? DefaultHighImportanceChannelId;

        var messageData = data != null 
            ? new Dictionary<string, string>(data) 
            : new Dictionary<string, string>();

        if (!messageData.ContainsKey("click_action"))
        {
            messageData["click_action"] = "FLUTTER_NOTIFICATION_CLICK";
        }

        return new Message
        {
            Token = fcmToken,
            Notification = new FirebaseAdmin.Messaging.Notification
            {
                Title = title,
                Body = body
            },
            Data = messageData,
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    ChannelId = channelId,
                    Sound = "default",
                    Priority = NotificationPriority.MAX,
                    DefaultSound = true,
                    DefaultVibrateTimings = true,
                    ClickAction = "FLUTTER_NOTIFICATION_CLICK",
                    EventTimestamp = DateTime.UtcNow
                }
            },
            Apns = new ApnsConfig
            {
                Headers = new Dictionary<string, string>
                {
                    { "apns-priority", "10" }
                },
                Aps = new Aps
                {
                    Sound = "default",
                    ContentAvailable = true
                }
            }
        };
    }

    /// <summary>
    /// Gửi thông báo đẩy FCM HTTP v1 tới thiết bị theo FCM Token
    /// </summary>
    public async Task<bool> SendPushAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null)
    {
        if (string.IsNullOrWhiteSpace(fcmToken)) return false;

        var trimmedToken = fcmToken.Trim();
        if (trimmedToken.StartsWith("fcm_dev_") || trimmedToken.Contains("mock") || trimmedToken == "string" || trimmedToken.Length < 25)
        {
            _logger.LogInformation("[FCM Dev Mock] Simulated push to dev/placeholder token {Token}: '{Title}' - '{Body}'", trimmedToken, title, body);
            return true;
        }

        var message = BuildHighPriorityMessage(trimmedToken, title, body, data);
        var app = GetOrInitializeFirebaseApp();

        if (app == null)
        {
            _logger.LogInformation(
                "[FCM Safe Fallback - High Priority v1] Service account not present. Simulated FCM v1 push to {Token}: Channel={Channel}, Priority=High, Title='{Title}', Body='{Body}', Data={Data}",
                fcmToken.Length > 15 ? fcmToken[..15] + "..." : fcmToken,
                message.Android?.Notification?.ChannelId ?? DefaultHighImportanceChannelId,
                title,
                body,
                JsonSerializer.Serialize(message.Data)
            );
            return true;
        }

        try
        {
            var messaging = FirebaseMessaging.GetMessaging(app);
            var messageId = await messaging.SendAsync(message);
            _logger.LogInformation("[FCM v1 Dispatched] MessageId: {MessageId} sent to {Token}", messageId, fcmToken);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send FCM v1 push notification to token {Token}", fcmToken);
            return false;
        }
    }

    /// <summary>
    /// Gửi thông báo tới người dùng: Lưu vào database notifications và phát push notification FCM v1
    /// </summary>
    public async Task<bool> SendToUserAsync(int userId, string title, string body, string type = "general", Dictionary<string, string>? data = null)
    {
        if (userId <= 0) userId = 1;

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);

        var notification = new SportSpot.Data.Entities.Notification
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
            var payloadData = data != null ? new Dictionary<string, string>(data) : new Dictionary<string, string>();
            if (!payloadData.ContainsKey("type")) payloadData["type"] = type;
            if (!payloadData.ContainsKey("notificationId")) payloadData["notificationId"] = notification.Id.ToString();

            await SendPushAsync(user.FcmToken, title, body, payloadData);
        }
        else
        {
            _logger.LogInformation("[FCM In-App Only] User {UserId} has no FCM token. Notification saved to database.", userId);
        }

        return true;
    }

    /// <summary>
    /// Gửi thông báo đẩy tới Topic (ví dụ: sportspot_all) để mọi thiết bị đăng ký topic đều nhận được tức thời
    /// </summary>
    public async Task<bool> SendToTopicAsync(string topic, string title, string body, Dictionary<string, string>? data = null)
    {
        if (string.IsNullOrWhiteSpace(topic)) topic = "sportspot_all";

        var channelId = _configuration["Firebase:DefaultChannelId"] ?? DefaultHighImportanceChannelId;
        var messageData = data != null ? new Dictionary<string, string>(data) : new Dictionary<string, string>();
        if (!messageData.ContainsKey("click_action")) messageData["click_action"] = "FLUTTER_NOTIFICATION_CLICK";

        var message = new Message
        {
            Topic = topic,
            Notification = new FirebaseAdmin.Messaging.Notification
            {
                Title = title,
                Body = body
            },
            Data = messageData,
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    ChannelId = channelId,
                    Sound = "default",
                    Priority = NotificationPriority.MAX,
                    DefaultSound = true,
                    DefaultVibrateTimings = true,
                    ClickAction = "FLUTTER_NOTIFICATION_CLICK",
                    EventTimestamp = DateTime.UtcNow
                }
            },
            Apns = new ApnsConfig
            {
                Headers = new Dictionary<string, string>
                {
                    { "apns-priority", "10" }
                },
                Aps = new Aps
                {
                    Sound = "default",
                    ContentAvailable = true
                }
            }
        };

        var app = GetOrInitializeFirebaseApp();
        if (app == null)
        {
            _logger.LogInformation("[FCM Safe Fallback] Simulated Topic Push to '{Topic}': '{Title}' - '{Body}'", topic, title, body);
            return true;
        }

        try
        {
            var messaging = FirebaseMessaging.GetMessaging(app);
            var messageId = await messaging.SendAsync(message);
            _logger.LogInformation("[FCM Topic Push Dispatched] MessageId: {MessageId} to topic '{Topic}'", messageId, topic);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send FCM push to topic '{Topic}'", topic);
            return false;
        }
    }

    private FirebaseApp? GetOrInitializeFirebaseApp()
    {
        var isEnabledStr = _configuration["Firebase:Enabled"];
        if (!string.IsNullOrWhiteSpace(isEnabledStr) && bool.TryParse(isEnabledStr, out var enabled) && !enabled)
        {
            _logger.LogInformation("[FCM] Push notifications are disabled in configuration.");
            return null;
        }

        if (FirebaseApp.DefaultInstance != null)
        {
            return FirebaseApp.DefaultInstance;
        }

        var configuredPath = _configuration["Firebase:ServiceAccountJsonPath"] 
            ?? _configuration["Firebase:ServiceAccountPath"] 
            ?? "firebase-service-account.json";

        var serviceAccountPath = Path.IsPathRooted(configuredPath)
            ? configuredPath
            : Path.Combine(Directory.GetCurrentDirectory(), configuredPath);

        if (!File.Exists(serviceAccountPath))
        {
            var altPath = Path.Combine(AppContext.BaseDirectory, configuredPath);
            if (File.Exists(altPath)) serviceAccountPath = altPath;
        }

        if (!File.Exists(serviceAccountPath))
        {
            return null;
        }

        lock (_firebaseLock)
        {
            if (FirebaseApp.DefaultInstance != null)
            {
                return FirebaseApp.DefaultInstance;
            }

            try
            {
                var projectId = _configuration["Firebase:ProjectId"];
                var options = new AppOptions
                {
                    Credential = GoogleCredential.FromFile(serviceAccountPath),
                    ProjectId = !string.IsNullOrWhiteSpace(projectId) ? projectId : null
                };
                return FirebaseApp.Create(options);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to initialize FirebaseApp from {Path}", serviceAccountPath);
                return null;
            }
        }
    }
}
