using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;
    private readonly IFcmPushService _fcmPushService;

    public NotificationsController(
        INotificationService notificationService,
        IFcmPushService fcmPushService)
    {
        _notificationService = notificationService;
        _fcmPushService = fcmPushService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<NotificationSummaryDto>>> GetNotifications([FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;
        var result = await _notificationService.GetNotificationsAsync(uid);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPut("{id}/read")]
    public async Task<ActionResult<ApiResponse<bool>>> MarkAsRead(int id, [FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;
        var result = await _notificationService.MarkAsReadAsync(id, uid);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPut("read-all")]
    public async Task<ActionResult<ApiResponse<bool>>> MarkAllAsRead([FromQuery] int? userId)
    {
        var uid = userId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;
        var result = await _notificationService.MarkAllAsReadAsync(uid);
        return StatusCode(result.StatusCode, result);
    }

    [HttpPost("fcm-token")]
    public async Task<ActionResult<ApiResponse<bool>>> SaveFcmToken([FromBody] SaveFcmTokenRequest request)
    {
        var uid = request.UserId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;
        var success = await _fcmPushService.SaveFcmTokenAsync(uid, request.FcmToken, request.DeviceType);
        return Ok(ApiResponse<bool>.Ok(success, "Lưu FCM Token thành công"));
    }

    [HttpPost("push")]
    public async Task<ActionResult<ApiResponse<bool>>> SendPush([FromBody] SendPushRequest request)
    {
        var uid = request.UserId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;
        var success = await _fcmPushService.SendToUserAsync(uid, request.Title, request.Body, request.Type ?? "general", request.Data);
        return Ok(ApiResponse<bool>.Ok(success, "Gửi thông báo thành công"));
    }

    /// <summary>
    /// Bắn thông báo đẩy thử nghiệm (Test Push) trực tiếp từ Swagger mà không cần cấu hình token phức tạp.
    /// Tự động gửi tới User theo Id và broadcast tới toàn bộ thiết bị đang lắng nghe Topic 'sportspot_all'.
    /// </summary>
    [HttpPost("test-push")]
    public async Task<ActionResult<ApiResponse<object>>> TestPush([FromBody] TestPushRequest? request)
    {
        var title = !string.IsNullOrWhiteSpace(request?.Title) 
            ? request.Title 
            : "🔥 Kèo mới tại SportSpot!";
            
        var body = !string.IsNullOrWhiteSpace(request?.Body) 
            ? request.Body 
            : "CLB Cầu lông Kỳ Hòa vừa có 1 suất trống lúc 19:00. Đặt ngay!";

        var uid = request?.UserId ?? GetCurrentUserId();
        if (uid <= 0) uid = 1;

        var data = new Dictionary<string, string>
        {
            { "click_action", "FLUTTER_NOTIFICATION_CLICK" },
            { "type", "Reminder" },
            { "timestamp", DateTime.UtcNow.ToString("o") }
        };

        var topic = !string.IsNullOrWhiteSpace(request?.Topic) ? request.Topic : "sportspot_all";

        if (!string.IsNullOrWhiteSpace(request?.FcmToken))
        {
            await _fcmPushService.SendPushAsync(request.FcmToken, title, body, data);
        }
        else
        {
            var userPushTask = _fcmPushService.SendToUserAsync(uid, title, body, "Reminder", data);
            var topicPushTask = _fcmPushService.SendToTopicAsync(topic, title, body, data);
            await Task.WhenAll(userPushTask, topicPushTask);
        }

        return Ok(ApiResponse<object>.Ok(new
        {
            Success = true,
            Title = title,
            Body = body,
            TargetUserId = uid,
            BroadcastTopic = topic,
            SpecificFcmToken = request?.FcmToken,
            DispatchedAt = DateTime.UtcNow
        }, "Bắn thông báo thử nghiệm thành công! Kiểm tra thông báo trên máy / Android Emulator ngay."));
    }

    private int GetCurrentUserId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claimValue, out var id) ? id : 0;
    }
}
