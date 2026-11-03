using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface INotificationService
{
    Task<ApiResponse<NotificationSummaryDto>> GetNotificationsAsync(int userId);
    Task<ApiResponse<bool>> MarkAsReadAsync(int notificationId, int userId);
    Task<ApiResponse<bool>> MarkAllAsReadAsync(int userId);
}
