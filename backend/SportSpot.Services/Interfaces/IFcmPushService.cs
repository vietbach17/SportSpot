using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IFcmPushService
{
    Task<bool> SaveFcmTokenAsync(int userId, string fcmToken, string? deviceType = null);
    Task<bool> SendPushAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null);
    Task<bool> SendToUserAsync(int userId, string title, string body, string type = "general", Dictionary<string, string>? data = null);
    Task<bool> SendToTopicAsync(string topic, string title, string body, Dictionary<string, string>? data = null);
}
