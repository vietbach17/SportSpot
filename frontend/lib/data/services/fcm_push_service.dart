import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import 'floating_notification_service.dart';

/// Dịch vụ quản lý Push Notification (Firebase Cloud Messaging - FCM)
/// Sẵn sàng khung gắn google-services.json và fallback an toàn khi chạy offline/test/dev.
class FcmPushService {
  static final FcmPushService _instance = FcmPushService._internal();
  static FcmPushService get instance => _instance;

  FcmPushService._internal();

  final INotificationRepository _notificationRepo = ApiNotificationRepository();
  final _messageStreamController = StreamController<NotificationModel>.broadcast();

  String? _fcmToken;
  Timer? _pollingTimer;
  int _lastKnownNotificationId = 0;

  Stream<NotificationModel> get onMessage => _messageStreamController.stream;
  String? get fcmToken => _fcmToken;

  /// Khởi tạo Push Service: Đăng ký token với backend và lắng nghe thông báo mới
  Future<void> initialize({int? userId}) async {
    try {
      try {
        final prefs = await SharedPreferences.getInstance();
        _fcmToken = prefs.getString('fcm_device_token');
        if (_fcmToken == null || _fcmToken!.isEmpty) {
          final randomSuffix = DateTime.now().millisecondsSinceEpoch.toString();
          _fcmToken = 'fcm_dev_sportspot_$randomSuffix';
          await prefs.setString('fcm_device_token', _fcmToken!);
        }
      } catch (_) {
        // Fallback in-memory token for headless tests or missing native shared_preferences plugins
        _fcmToken ??= 'fcm_dev_sportspot_mock_test_token';
      }

      debugPrint('[FcmPushService] Device token ready: $_fcmToken');

      // 2. Gửi FCM Token lên Backend SportSpot để nhận push
      await _notificationRepo.saveFcmToken(
        _fcmToken!,
        userId: userId,
        deviceType: defaultTargetPlatform.name.toLowerCase(),
      );

      // 3. Khởi tạo Firebase Native Hook (sẽ chạy nếu dự án gắn google-services.json)
      _setupNativeFirebaseHook();

      // 4. Lắng nghe và tự động hiển thị Floating Banner khi có thông báo
      startPeriodicSync(userId: userId);
    } catch (e) {
      debugPrint('[FcmPushService] Error during initialization: $e');
    }
  }

  /// Hook tích hợp Firebase Messaging native khi đã bổ sung google-services.json & package
  void _setupNativeFirebaseHook() {
    /* 
      --- HƯỚNG DẪN KÍCH HOẠT GOOGLE-SERVICES.JSON NATIVE ---
      1. Tải file google-services.json từ Firebase Console đặt vào: frontend/android/app/google-services.json
      2. Thêm plugin trong android/settings.gradle & android/app/build.gradle
      3. Thêm dependency firebase_core & firebase_messaging vào pubspec.yaml
      4. Bỏ comment khối code sau:
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch,
          title: message.notification?.title ?? 'SportSpot',
          message: message.notification?.body ?? '',
          type: message.data['type'] ?? 'Reminder',
          isRead: false,
          createdAt: DateTime.now(),
        );
        handleIncomingNotification(notification);
      });
    */
    debugPrint('[FcmPushService] Native FCM hook configured and awaiting google-services.json config.');
  }

  /// Xử lý khi có thông báo đẩy đến: bắn vào stream và hiện Floating Top Banner
  void handleIncomingNotification(NotificationModel notification) {
    _messageStreamController.add(notification);

    FloatingNotificationService.show(
      title: notification.title,
      message: notification.message,
      type: notification.type,
      onTap: () {
        debugPrint('[FcmPushService] Notification banner tapped: ${notification.title}');
      },
    );
  }

  /// Giả lập push notification đến thiết bị (phục vụ test và demo giao diện tức thì)
  void simulateIncomingPush({
    required String title,
    required String message,
    String type = 'Reminder',
  }) {
    final notif = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      message: message,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    handleIncomingNotification(notif);
  }

  /// Đồng bộ định kỳ với server để phát hiện thông báo mới và tự động bung Banner nổi
  void startPeriodicSync({int? userId, Duration interval = const Duration(seconds: 20)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      await checkForNewNotifications(userId: userId);
    });
  }

  /// Kiểm tra thông báo mới từ API Backend
  Future<void> checkForNewNotifications({int? userId}) async {
    try {
      final summary = await _notificationRepo.getNotifications(userId: userId);
      if (summary.notifications.isEmpty) return;

      final newest = summary.notifications.first;
      if (_lastKnownNotificationId == 0) {
        _lastKnownNotificationId = newest.id;
        return;
      }

      if (newest.id > _lastKnownNotificationId && !newest.isRead) {
        _lastKnownNotificationId = newest.id;
        handleIncomingNotification(newest);
      }
    } catch (_) {
      // Ignored in offline fallback
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}
