import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportspot/data/models/user_model.dart';
import 'package:sportspot/providers/auth_provider.dart';
import 'package:sportspot/providers/ticket_provider.dart';
import 'package:sportspot/screens/profile/profile_screen.dart';

class TestAuthProvider extends AuthProvider {
  UserModel? _fakeUser;
  bool _fakeGuest = true;

  @override
  UserModel? get currentUser => _fakeUser;

  @override
  bool get isGuest => _fakeGuest;

  @override
  bool get isAuthenticated => !_fakeGuest && _fakeUser != null;

  void setTestGuest() {
    _fakeGuest = true;
    _fakeUser = null;
    notifyListeners();
  }

  void setTestUser(UserModel user) {
    _fakeGuest = false;
    _fakeUser = user;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileScreen - Guest vs Member Skill Ratings', () {
    testWidgets('Guest mode hides skill ratings breakdown completely', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = TestAuthProvider();
      auth.setTestGuest();
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

      // Guest banner check
      expect(find.text('Khách Vãng Lai (Guest)'), findsOneWidget);
      expect(find.text('Thông số thi đấu và ví điện tử (Chế độ khách vãng lai).'), findsOneWidget);

      // Verify that skill ratings breakdown is NOT rendered for guest
      expect(find.text('Bộ Môn & Đánh Giá Kỹ Năng'), findsNothing);
      expect(find.text('Nâng cao 4.0'), findsNothing);
      expect(find.textContaining('Xác thực bởi Host'), findsNothing);
      expect(find.text('Trung cấp 3.5 • DUPR Rating'), findsNothing);
      expect(find.text('Hạng B+ • Tốc độ & Thể lực'), findsNothing);
    });

    testWidgets('Logged-in member shows skill ratings breakdown', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = TestAuthProvider();
      auth.setTestUser(UserModel(
        userId: 1,
        fullName: 'Nguyễn Văn A',
        phoneNumber: '0987654321',
        role: 'Player',
        walletBalance: 200000,
      ));
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

      // Member name check
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('Thông số thi đấu, chỉ số kỹ năng và ví điện tử.'), findsOneWidget);

      // Verify that skill ratings breakdown IS rendered for logged-in user
      expect(find.text('Bộ Môn & Đánh Giá Kỹ Năng'), findsOneWidget);
      expect(find.text('Nâng cao 4.0'), findsOneWidget);
      expect(find.textContaining('Xác thực bởi Host'), findsNothing);
      expect(find.text('Trung cấp 3.5 • DUPR Rating'), findsOneWidget);
      expect(find.text('Hạng B+ • Tốc độ & Thể lực'), findsOneWidget);
    });
  });
}
