import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportspot/data/models/user_model.dart';
import 'package:sportspot/data/repositories/favorite_repository.dart';
import 'package:sportspot/providers/auth_provider.dart';
import 'package:sportspot/providers/ticket_provider.dart';
import 'package:sportspot/screens/profile/profile_screen.dart';

class FavoriteTestAuthProvider extends AuthProvider {
  final UserModel _user = UserModel(
    userId: 1,
    fullName: 'Test Player',
    phoneNumber: '0901234567',
    role: 'Player',
    favoriteSports: 'Cầu lông, Pickleball',
  );

  @override
  UserModel? get currentUser => _user;

  @override
  bool get isAuthenticated => true;

  @override
  bool get isGuest => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MockFavoriteRepository.reset(); // starts with {1}
  });

  group('Favorite Venues Auto-Update & Sync Tests', () {
    testWidgets('ProfileScreen automatically displays favorite venues from repository', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = FavoriteTestAuthProvider();
      final ticket = TicketProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<TicketProvider>.value(value: ticket),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sân Yêu Thích (1)'), findsOneWidget);
      expect(find.text('CLB Cầu Lông Kỳ Hòa'), findsOneWidget);
      expect(find.textContaining('Xác thực bởi Host'), findsNothing);
    });

    testWidgets('Tapping heart icon in ProfileScreen removes venue and auto-updates list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = FavoriteTestAuthProvider();
      final ticket = TicketProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<TicketProvider>.value(value: ticket),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sân Yêu Thích (1)'), findsOneWidget);
      expect(find.text('CLB Cầu Lông Kỳ Hòa'), findsOneWidget);

      final unFavBtn = find.byTooltip('Bỏ yêu thích');
      expect(unFavBtn, findsOneWidget);
      await tester.ensureVisible(unFavBtn);
      await tester.tap(unFavBtn);
      await tester.pumpAndSettle();

      expect(find.text('Sân Yêu Thích (0)'), findsOneWidget);
      expect(find.text('Chưa có sân yêu thích nào'), findsOneWidget);
      expect(find.text('CLB Cầu Lông Kỳ Hòa'), findsNothing);
    });

    testWidgets('Toggling favorite in external repository automatically synchronizes ProfileScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = FavoriteTestAuthProvider();
      final ticket = TicketProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<TicketProvider>.value(value: ticket),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sân Yêu Thích (1)'), findsOneWidget);

      final venueRepo = MockFavoriteRepository();
      await venueRepo.toggleFavorite(2);
      await tester.pumpAndSettle();

      expect(find.text('Sân Yêu Thích (2)'), findsOneWidget);
      expect(find.text('Sân Bóng Đá Mini Chảo Lửa'), findsOneWidget);

      await venueRepo.toggleFavorite(1);
      await tester.pumpAndSettle();

      expect(find.text('Sân Yêu Thích (1)'), findsOneWidget);
      expect(find.text('CLB Cầu Lông Kỳ Hòa'), findsNothing);
      expect(find.text('Sân Bóng Đá Mini Chảo Lửa'), findsOneWidget);
    });
  });
}
