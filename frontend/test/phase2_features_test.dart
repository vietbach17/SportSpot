import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportspot/data/repositories/booking_repository.dart';
import 'package:sportspot/data/repositories/owner_repository.dart';
import 'package:sportspot/data/repositories/review_repository.dart';
import 'package:sportspot/screens/owner/owner_dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:sportspot/providers/ticket_provider.dart';
import 'package:sportspot/data/repositories/notification_repository.dart';
import 'package:sportspot/data/repositories/favorite_repository.dart';
import 'package:sportspot/data/repositories/match_comment_repository.dart';
import 'package:sportspot/data/services/floating_notification_service.dart';
import 'package:sportspot/data/services/fcm_push_service.dart';
import 'package:sportspot/screens/notifications/notifications_screen.dart';
import 'package:sportspot/screens/matches/match_discussion_sheet.dart';
import 'package:sportspot/screens/payment/wallet_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Giai đoạn 2 - Reviews & Ratings Tests', () {
    test('MockReviewRepository computes average rating and star breakdown', () async {
      final repo = MockReviewRepository();
      final summary = await repo.getVenueReviews(1);

      expect(summary.venueId, equals(1));
      expect(summary.totalReviews, greaterThanOrEqualTo(3));
      expect(summary.averageRating, greaterThanOrEqualTo(4.0));
      expect(summary.ratingBreakdown.containsKey(5), isTrue);
      expect(summary.reviews.isNotEmpty, isTrue);
    });

    test('MockReviewRepository submits new review and prepends to list', () async {
      final repo = MockReviewRepository();
      final newReview = await repo.submitReview(1, 5, 'Sân quá đỉnh, trải nghiệm tuyệt vời!');

      expect(newReview.rating, equals(5));
      expect(newReview.comment, contains('Sân quá đỉnh'));

      final summary = await repo.getVenueReviews(1);
      expect(summary.reviews.first.comment, equals('Sân quá đỉnh, trải nghiệm tuyệt vời!'));
    });
  });

  group('Giai đoạn 2 - Owner Dashboard Tests', () {
    test('MockOwnerRepository returns accurate financial metrics and 7-day revenue', () async {
      final repo = MockOwnerRepository();
      final data = await repo.getDashboard(venueId: 1);

      expect(data.venueId, equals(1));
      expect(data.totalBookings, greaterThan(0));
      expect(data.totalRevenue, greaterThan(0));
      expect(data.escrowHoldingAmount, greaterThan(0));
      expect(data.dailyRevenues.length, equals(7));
      expect(data.subVenues.length, greaterThanOrEqualTo(3));
    });

    test('MockOwnerRepository toggles subvenue maintenance status', () async {
      final repo = MockOwnerRepository();
      final initialState = (await repo.getDashboard()).subVenues.first.isActive;

      final newState = await repo.toggleSubVenueStatus(1);
      expect(newState, equals(!initialState));

      final restoredState = await repo.toggleSubVenueStatus(1);
      expect(restoredState, equals(initialState));
    });

    testWidgets('OwnerDashboardScreen renders metrics, charts, and subvenue switches', (tester) async {
      final mockRepo = MockOwnerRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: OwnerDashboardScreen(repository: mockRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bảng Điều Khiển Chủ Sân'), findsOneWidget);
      expect(find.text('Doanh thu thực tế'), findsOneWidget);
      expect(find.text('Tổng lượt đặt sân'), findsOneWidget);
      expect(find.text('DOANH THU 7 NGÀY GẦN NHẤT'), findsOneWidget);
      expect(find.textContaining('QUẢN LÝ SÂN CON'), findsOneWidget);
      expect(find.text('Sân Thảm 1 (Chính)'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    });
  });

  group('Giai đoạn 2 - Cancel Booking & Refund Tests', () {
    test('MockBookingRepository cancels booking with refund information', () async {
      final repo = MockBookingRepository();
      final res = await repo.cancelBooking(101);

      expect(res.bookingId, equals(101));
      expect(res.refundPercentage, equals(100));
      expect(res.refundAmount, equals(150000));
    });
  });

  group('Giai đoạn 2 - Notifications Tests', () {
    test('MockNotificationRepository marks single and all notifications as read', () async {
      final repo = MockNotificationRepository();
      final initial = await repo.getNotifications();
      expect(initial.unreadCount, greaterThan(0));

      final markOne = await repo.markAsRead(1);
      expect(markOne, isTrue);

      final markAll = await repo.markAllAsRead();
      expect(markAll, isTrue);

      final after = await repo.getNotifications();
      expect(after.unreadCount, equals(0));
    });

    testWidgets('NotificationsScreen renders reminder and booking notifications', (tester) async {
      final mockRepo = MockNotificationRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(repository: mockRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông Báo & Nhắc Lịch'), findsOneWidget);
      expect(find.textContaining('Nhắc lịch thi đấu'), findsOneWidget);
      expect(find.textContaining('Xác nhận cọc Escrow'), findsOneWidget);
    });
  });

  group('Giai đoạn 2 - Favorite Venues Tests', () {
    test('MockFavoriteRepository checks and toggles favorite status', () async {
      final repo = MockFavoriteRepository();
      var favs = await repo.getFavoriteVenueIds();
      expect(favs.contains(1), isTrue);
      expect(favs.contains(99), isFalse);

      final toggledOff = await repo.toggleFavorite(1);
      expect(toggledOff, isFalse);
      favs = await repo.getFavoriteVenueIds();
      expect(favs.contains(1), isFalse);

      final toggledOn = await repo.toggleFavorite(1);
      expect(toggledOn, isTrue);
      favs = await repo.getFavoriteVenueIds();
      expect(favs.contains(1), isTrue);
    });
  });

  group('Giai đoạn 2 - Match Discussion & Comments Tests', () {
    test('MockMatchCommentRepository retrieves comments and posts new comment', () async {
      final repo = MockMatchCommentRepository();
      final comments = await repo.getComments(1);

      expect(comments.length, greaterThanOrEqualTo(2));
      expect(comments.first.content, contains('giày đế kếp'));

      final added = await repo.addComment(1, 'Hẹn anh em 17:45 khởi động nhé!');
      expect(added.content, contains('Hẹn anh em 17:45'));

      final updatedComments = await repo.getComments(1);
      expect(updatedComments.last.content, contains('Hẹn anh em 17:45'));
    });

    testWidgets('MatchDiscussionSheet renders header and comment input', (tester) async {
      final mockRepo = MockMatchCommentRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchDiscussionSheet(
              matchId: 1,
              matchTitle: 'Cầu lông • CLB Kỳ Hòa',
              repository: mockRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thảo Luận Kèo Đấu'), findsOneWidget);
      expect(find.text('Cầu lông • CLB Kỳ Hòa'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Giai đoạn 2 - Wallet & History Tests', () {
    testWidgets('WalletHistoryScreen renders balance and quick topup buttons', (tester) async {
      final provider = TicketProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: WalletHistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ví SportSpot & Lịch Sử Giao Dịch'), findsOneWidget);
      expect(find.text('SỐ DƯ KHẢ DỤNG'), findsOneWidget);
      expect(find.textContaining('NẠP TIỀN VÀO VÍ'), findsOneWidget);
      expect(find.text('+50k'), findsOneWidget);
      expect(find.text('+100k'), findsOneWidget);
      expect(find.text('+200k'), findsOneWidget);
      expect(find.text('+500k'), findsOneWidget);
    });
  });

  group('Floating Notification & FCM Push Tests', () {
    testWidgets('FloatingNotificationService displays top banner and dismisses cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: FloatingNotificationService.navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Home Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      FloatingNotificationService.show(
        title: 'Nhắc lịch trận đấu',
        message: 'Trận cầu lông sắp diễn ra tại CLB Kỳ Hòa',
        type: 'Reminder',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Nhắc lịch trận đấu'), findsOneWidget);
      expect(find.text('Trận cầu lông sắp diễn ra tại CLB Kỳ Hòa'), findsOneWidget);
      expect(find.text('SportSpot'), findsOneWidget);

      FloatingNotificationService.dismiss();
      await tester.pumpAndSettle();
      expect(find.text('Nhắc lịch trận đấu'), findsNothing);
    });

    test('FcmPushService initializes token and streams incoming notifications', () async {
      final fcm = FcmPushService.instance;
      await fcm.initialize(userId: 1);

      expect(fcm.fcmToken, isNotNull);
      expect(fcm.fcmToken!.isNotEmpty, isTrue);

      bool received = false;
      final sub = fcm.onMessage.listen((notif) {
        if (notif.title == 'Kèo mới') received = true;
      });

      fcm.simulateIncomingPush(
        title: 'Kèo mới',
        message: 'Có 1 kèo bóng đá mini tại Cầu Giấy',
        type: 'Match',
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, isTrue);
      await sub.cancel();
      fcm.dispose();
    });
  });
}
