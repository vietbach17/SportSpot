using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class NotificationService : INotificationService
{
    private readonly SportSpotDbContext _context;

    public NotificationService(SportSpotDbContext context)
    {
        _context = context;
    }

    public async Task<ApiResponse<NotificationSummaryDto>> GetNotificationsAsync(int userId)
    {
        if (userId <= 0) userId = 1;

        var notifications = await _context.Notifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();

        var dtos = notifications.Select(n => new NotificationDto
        {
            Id = n.Id,
            Title = n.Title,
            Message = n.Message,
            Type = n.Type,
            IsRead = n.IsRead,
            CreatedAt = n.CreatedAt
        }).ToList();

        var unreadCount = dtos.Count(n => !n.IsRead);

        return ApiResponse<NotificationSummaryDto>.Ok(new NotificationSummaryDto
        {
            UnreadCount = unreadCount,
            Notifications = dtos
        });
    }

    public async Task<ApiResponse<bool>> MarkAsReadAsync(int notificationId, int userId)
    {
        if (userId <= 0) userId = 1;

        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

        if (notification == null)
        {
            return ApiResponse<bool>.Fail("Không tìm thấy thông báo", 404);
        }

        notification.IsRead = true;
        await _context.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Đã đánh dấu thông báo là đã đọc");
    }

    public async Task<ApiResponse<bool>> MarkAllAsReadAsync(int userId)
    {
        if (userId <= 0) userId = 1;

        var unread = await _context.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ToListAsync();

        foreach (var n in unread)
        {
            n.IsRead = true;
        }

        await _context.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Đã đánh dấu toàn bộ thông báo là đã đọc");
    }
}
