import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportspot/data/models/user_model.dart';
import 'package:sportspot/data/models/user_skill_model.dart';
import 'package:sportspot/providers/auth_provider.dart';
import 'package:sportspot/providers/ticket_provider.dart';
import 'package:sportspot/screens/profile/profile_screen.dart';

class MockSkillsAuthProvider extends AuthProvider {
  UserModel? _fakeUser;
  List<UserSkillModel> _mockSkills = [];
  List<Map<String, dynamic>> savedPayload = [];

  @override
  UserModel? get currentUser => _fakeUser;

  @override
  bool get isGuest => false;

  @override
  bool get isAuthenticated => true;

  @override
  List<UserSkillModel> get userSkills => _mockSkills;

  void setUser(UserModel user, List<UserSkillModel> skills) {
    _fakeUser = user;
    _mockSkills = skills;
    notifyListeners();
  }

  @override
  Future<void> fetchUserSkills() async {}

  @override
  Future<bool> saveUserSkills(List<Map<String, dynamic>> skills) async {
    savedPayload = List.from(skills);
    _mockSkills = skills.map((s) => UserSkillModel(
      id: 1,
      userId: 1,
      sportId: 1,
      sportName: s['sportName'],
      skillLevel: s['skillLevel'],
      ratingScore: (s['ratingScore'] as num).toDouble(),
      isVerified: false,
    )).toList();
    notifyListeners();
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserSkills Model and UI Setup Tests', () {
    test('UserSkillModel serializes and deserializes correctly', () {
      final json = {
        'id': 10,
        'userId': 2,
        'sportId': 1,
        'sportName': 'Cầu lông',
        'skillLevel': 'Khá',
        'ratingScore': 4.0,
        'isVerified': true,
        'verifiedBy': 'Host Kỳ Hòa',
      };

      final model = UserSkillModel.fromJson(json);
      expect(model.id, 10);
      expect(model.sportName, 'Cầu lông');
      expect(model.skillLevel, 'Khá');
      expect(model.ratingScore, 4.0);
      expect(model.isVerified, true);
      expect(model.verifiedBy, 'Host Kỳ Hòa');

      final output = model.toJson();
      expect(output['sportName'], 'Cầu lông');
      expect(output['skillLevel'], 'Khá');
      expect(output['ratingScore'], 4.0);
    });

    testWidgets('Profile screen displays dynamic skills from auth.userSkills', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = MockSkillsAuthProvider();
      auth.setUser(
        UserModel(
          userId: 1,
          fullName: 'Trần Văn B',
          phoneNumber: '0912345678',
          role: 'Player',
          favoriteSports: 'Cầu lông,Pickleball',
        ),
        [
          UserSkillModel(
            id: 1,
            userId: 1,
            sportId: 1,
            sportName: 'Cầu lông',
            skillLevel: 'Khá',
            ratingScore: 4.0,
            isVerified: true,
            verifiedBy: 'CLB Kỳ Hòa Host',
          ),
          UserSkillModel(
            id: 2,
            userId: 1,
            sportId: 2,
            sportName: 'Pickleball',
            skillLevel: 'Bán chuyên',
            ratingScore: 4.5,
            isVerified: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<TicketProvider>.value(value: TicketProvider()),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bộ Môn & Đánh Giá Kỹ Năng'), findsOneWidget);
      expect(find.text('Cầu lông'), findsWidgets);
      expect(find.text('Pickleball'), findsWidgets);
      expect(find.text('Khá 4.0 • Xác thực bởi CLB Kỳ Hòa Host'), findsOneWidget);
      expect(find.text('Bán chuyên 4.5 • Tự đánh giá'), findsOneWidget);
    });

    testWidgets('Dialog allows choosing sport and skill level then saves', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = MockSkillsAuthProvider();
      auth.setUser(
        UserModel(
          userId: 1,
          fullName: 'Trần Văn B',
          phoneNumber: '0912345678',
          role: 'Player',
          favoriteSports: 'Cầu lông',
        ),
        [
          UserSkillModel(
            id: 1,
            userId: 1,
            sportId: 1,
            sportName: 'Cầu lông',
            skillLevel: 'Khá',
            ratingScore: 4.0,
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<TicketProvider>.value(value: TicketProvider()),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Tùy chỉnh' to open sheet
      await tester.tap(find.text('Tùy chỉnh'));
      await tester.pumpAndSettle();

      // Check dialog title and sections
      expect(find.text('Thiết Lập Bộ Môn & Cấp Độ Kỹ Năng'), findsOneWidget);
      expect(find.text('CẤP ĐỘ KỸ NĂNG CHO TỪNG BỘ MÔN'), findsOneWidget);

      // Verify level choices exist
      expect(find.text('Cơ bản (3.0)'), findsWidgets);
      expect(find.text('Phong trào (3.5)'), findsWidgets);
      expect(find.text('Khá (4.0)'), findsWidgets);
      expect(find.text('Bán chuyên (4.5)'), findsWidgets);
      expect(find.text('Chuyên nghiệp (5.0)'), findsWidgets);

      // Tap 'Bán chuyên (4.5)' chip for Cầu lông
      await tester.tap(find.text('Bán chuyên (4.5)'));
      await tester.pumpAndSettle();

      // Tap 'Lưu Thiết Lập Kỹ Năng'
      await tester.tap(find.text('Lưu Thiết Lập Kỹ Năng'));
      await tester.pumpAndSettle();

      // Verify saved payload sent to auth provider
      expect(auth.savedPayload.isNotEmpty, true);
      final badminton = auth.savedPayload.firstWhere((s) => s['sportName'] == 'Cầu lông');
      expect(badminton['skillLevel'], 'Bán chuyên');
      expect(badminton['ratingScore'], 4.5);
    });
  });
}
