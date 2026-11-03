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

    private int GetCurrentUserId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claimValue, out var id) ? id : 0;
    }
}
