namespace SportSpot.Services.DTOs;

public class NotificationDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = "System";
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class NotificationSummaryDto
{
    public int UnreadCount { get; set; }
    public List<NotificationDto> Notifications { get; set; } = new();
}

public class SaveFcmTokenRequest
{
    public int? UserId { get; set; }
    public string FcmToken { get; set; } = string.Empty;
    public string? DeviceType { get; set; }
}

public class SendPushRequest
{
    public int? UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? Type { get; set; } = "general";
    public Dictionary<string, string>? Data { get; set; }
}
