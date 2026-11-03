import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

abstract class INotificationRepository {
  Future<NotificationSummaryModel> getNotifications({int? userId});
  Future<bool> markAsRead(int id, {int? userId});
  Future<bool> markAllAsRead({int? userId});
  Future<bool> saveFcmToken(String token, {int? userId, String? deviceType});
}

class MockNotificationRepository implements INotificationRepository {
  final List<NotificationModel> _items = [
    NotificationModel(
      id: 1,
      title: 'Nhắc lịch thi đấu (còn 2 tiếng)',
      message: 'Trận Cầu lông tại CLB Kỳ Hòa sẽ diễn ra lúc 18:00 hôm nay. Vui lòng có mặt trước 15 phút!',
      type: 'Reminder',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 2,
      title: 'Xác nhận cọc Escrow thành công',
      message: 'Tiền cọc của đơn đặt sân SP-782194 đang được SportSpot giữ an toàn ở trạng thái Holding.',
      type: 'Booking',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: 3,
      title: 'Có kèo ghép mới gần bạn',
      message: 'CLB Cầu Lông Kỳ Hòa vừa có 1 kèo mới trình độ Trung bình đang cần tìm thêm 1 người.',
      type: 'Match',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<NotificationSummaryModel> getNotifications({int? userId}) async {
    final unread = _items.where((n) => !n.isRead).length;
    return NotificationSummaryModel(
      unreadCount: unread,
      notifications: List.from(_items),
    );
  }

  @override
  Future<bool> markAsRead(int id, {int? userId}) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(isRead: true);
      return true;
    }
    return false;
  }

  @override
  Future<bool> markAllAsRead({int? userId}) async {
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    return true;
  }

  @override
  Future<bool> saveFcmToken(String token, {int? userId, String? deviceType}) async {
    return true;
  }
}

class ApiNotificationRepository implements INotificationRepository {
  final ApiClient _client;
  final MockNotificationRepository _fallback = MockNotificationRepository();

  ApiNotificationRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<NotificationSummaryModel> getNotifications({int? userId}) async {
    try {
      final query = userId != null ? '?userId=$userId' : '';
      final response = await _client.get('/api/notifications$query', requiresAuth: false);
      if (response is Map<String, dynamic>) {
        return NotificationSummaryModel.fromJson(response);
      }
      return await _fallback.getNotifications(userId: userId);
    } catch (_) {
      return await _fallback.getNotifications(userId: userId);
    }
  }

  @override
  Future<bool> markAsRead(int id, {int? userId}) async {
    try {
      final query = userId != null ? '?userId=$userId' : '';
      final response = await _client.put('/api/notifications/$id/read$query', {});
      if (response is bool) return response;
      return true;
    } catch (_) {
      return await _fallback.markAsRead(id, userId: userId);
    }
  }

  @override
  Future<bool> markAllAsRead({int? userId}) async {
    try {
      final query = userId != null ? '?userId=$userId' : '';
      final response = await _client.put('/api/notifications/read-all$query', {});
      if (response is bool) return response;
      return true;
    } catch (_) {
      return await _fallback.markAllAsRead(userId: userId);
    }
  }

  @override
  Future<bool> saveFcmToken(String token, {int? userId, String? deviceType}) async {
    try {
      final body = <String, dynamic>{
        'fcmToken': token,
        'deviceType': deviceType ?? 'flutter_mobile',
      };
      if (userId != null) {
        body['userId'] = userId;
      }
      final response = await _client.post('/api/notifications/fcm-token', body, requiresAuth: false);
      return response != null;
    } catch (_) {
      return await _fallback.saveFcmToken(token, userId: userId, deviceType: deviceType);
    }
  }
}
