import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import 'floating_notification_service.dart';

/// Handler nhận tin ngầm khi ứng dụng ở Background hoặc bị Tắt hoàn toàn (Terminated).
/// Bắt buộc là hàm top-level và gắn annotation @pragma('vm:entry-point') để VM không loại bỏ khi compile AOT.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (_) {}
  debugPrint('[FCM Background Handler] Nhận push khi tắt app: id=${message.messageId}, title=${message.notification?.title}, body=${message.notification?.body}, data=${message.data}');
}

/// Kênh thông báo Android Notification Channel ưu tiên cao (High Importance)
const AndroidNotificationChannel sportspotHighImportanceChannel = AndroidNotificationChannel(
  'sportspot_high_importance_channel',
  'SportSpot High Priority Notifications',
  description: 'Kênh thông báo ưu tiên cao nhận tin nhắn nhắc lịch đặt sân, kèo đấu khi tắt app hoặc chạy nền.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

const AndroidNotificationDetails sportspotNotificationDetails = AndroidNotificationDetails(
  'sportspot_high_importance_channel',
  'SportSpot High Priority Notifications',
  channelDescription: 'Kênh thông báo ưu tiên cao nhận tin nhắn nhắc lịch đặt sân, kèo đấu khi tắt app hoặc chạy nền.',
  importance: Importance.max,
  priority: Priority.high,
  playSound: true,
  enableVibration: true,
  icon: '@mipmap/ic_launcher',
);

/// Dịch vụ quản lý Push Notification (Firebase Cloud Messaging - FCM)
/// Hỗ trợ đầy đủ: Background handler khi tắt app, High-importance channel, và Safe Fallback.
class FcmPushService {
  static final FcmPushService _instance = FcmPushService._internal();
  static FcmPushService get instance => _instance;

  FcmPushService._internal();

  final INotificationRepository _notificationRepo = ApiNotificationRepository();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _messageStreamController = StreamController<NotificationModel>.broadcast();

  String? _fcmToken;
  Timer? _pollingTimer;
  int _lastKnownNotificationId = 0;

  Stream<NotificationModel> get onMessage => _messageStreamController.stream;
  String? get fcmToken => _fcmToken;

  /// Khởi tạo Push Service: Cài đặt kênh thông báo, kết nối FCM Native và fallback an toàn
  Future<void> initialize({int? userId}) async {
    try {
      // 1. Cài đặt Android Notification Channel & Local Notifications
      await _setupNotificationChannel();

      // 2. Kích hoạt Firebase Native Hook & Background Handler
      await _setupNativeFirebase();

      // 3. Fallback token cho môi trường dev/test hoặc khi chưa có google-services native
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        await _setupFallbackToken();
      }

      debugPrint('[FcmPushService] Device token ready: $_fcmToken');

      // 4. Gửi FCM Token lên Backend SportSpot để nhận push
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await _notificationRepo.saveFcmToken(
          _fcmToken!,
          userId: userId,
          deviceType: defaultTargetPlatform.name.toLowerCase(),
        );
      }

      // 5. Lắng nghe và tự động hiển thị Floating Banner / In-App Notification
      startPeriodicSync(userId: userId);
    } catch (e) {
      debugPrint('[FcmPushService] Error during initialization: $e');
    }
  }

  /// Khởi tạo Android Notification Channel ưu tiên cao
  Future<void> _setupNotificationChannel() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit, macOS: darwinInit);

      await _localNotificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[FcmPushService] Notification action tapped: ${response.payload}');
        },
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(sportspotHighImportanceChannel);
    } catch (e) {
      debugPrint('[FcmPushService] Local notification channel setup skipped: $e');
    }
  }

  /// Hook tích hợp Firebase Messaging native với background handler
  Future<void> _setupNativeFirebase() async {
    try {
      await Firebase.initializeApp();

      final messaging = FirebaseMessaging.instance;

      // Yêu cầu quyền thông báo (bắt buộc cho Android 13+ và iOS)
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[FcmPushService] FCM Permission status: ${settings.authorizationStatus}');

      // Bật hiển thị heads-up banner khi app đang ở foreground
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Đăng ký Background Handler nhận push khi tắt app
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Lấy Device Token từ FCM native
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        _fcmToken = token;
        debugPrint('================================================================');
        debugPrint('[FCM] ACTIVE DEVICE TOKEN: $_fcmToken');
        debugPrint('================================================================');
      }

      // Đăng ký nhận thông báo toàn hệ thống qua Topic sportspot_all
      try {
        await messaging.subscribeToTopic('sportspot_all');
        debugPrint('[FcmPushService] Subscribed to topic: sportspot_all');
      } catch (e) {
        debugPrint('[FcmPushService] Topic subscription error: $e');
      }

      // Lắng nghe khi token FCM thay đổi
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('[FCM] Token refreshed: $_fcmToken');
        _notificationRepo.saveFcmToken(
          newToken,
          deviceType: defaultTargetPlatform.name.toLowerCase(),
        );
      });

      // Lắng nghe thông báo khi ứng dụng đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Nhận tin nhắn khi app đang mở: ${message.notification?.title} - ${message.notification?.body}');
        final title = message.notification?.title ?? message.data['title'] ?? 'SportSpot';
        final body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';

        final notification = NotificationModel(
          id: message.messageId.hashCode != 0 ? message.messageId.hashCode : DateTime.now().millisecondsSinceEpoch,
          title: title,
          message: body,
          type: message.data['type'] ?? 'Reminder',
          isRead: false,
          createdAt: DateTime.now(),
        );
        handleIncomingNotification(notification);

        // Đồng thời bắn native heads-up notification qua channel ưu tiên cao với mốc thời gian hiện tại
        _localNotificationsPlugin.show(
          id: notification.id,
          title: notification.title,
          body: notification.message,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'sportspot_high_importance_channel',
              'SportSpot High Priority Notifications',
              channelDescription: 'Kênh thông báo ưu tiên cao nhận tin nhắn nhắc lịch đặt sân, kèo đấu khi tắt app hoặc chạy nền.',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              icon: '@mipmap/ic_launcher',
              showWhen: true,
              when: DateTime.now().millisecondsSinceEpoch,
            ),
          ),
          payload: message.data.toString(),
        );
      });

      // Lắng nghe khi người dùng bấm vào thông báo từ background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FcmPushService] App opened from background notification: ${message.notification?.title}');
      });

      // Kiểm tra xem ứng dụng có được mở từ trạng thái Tắt hoàn toàn (Terminated) qua push hay không
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FcmPushService] App launched from terminated state via notification: ${initialMessage.notification?.title}');
      }
    } catch (e) {
      debugPrint('[FcmPushService] Native FCM hook awaiting native google-services configuration: $e');
    }
  }

  /// Cấu hình fallback token an toàn cho môi trường test/dev
  Future<void> _setupFallbackToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fcmToken = prefs.getString('fcm_device_token');
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        final randomSuffix = DateTime.now().millisecondsSinceEpoch.toString();
        _fcmToken = 'fcm_dev_sportspot_$randomSuffix';
        await prefs.setString('fcm_device_token', _fcmToken!);
      }
    } catch (_) {
      _fcmToken ??= 'fcm_dev_sportspot_mock_test_token';
    }
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
