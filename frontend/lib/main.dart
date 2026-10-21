import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/services/token_service.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo locale tiếng Việt cho DateFormat
  try {
    await initializeDateFormatting('vi', null);
    await initializeDateFormatting('vi_VN', null);
  } catch (e) {
    debugPrint('[main] initializeDateFormatting error: $e');
  }

  // Kiểm tra cờ xem Onboarding
  final bool hasSeenOnboarding = await TokenService.isOnboardingSeen();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initializeAuth(),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(),
        ),
      ],
      child: SportSpotApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class SportSpotApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const SportSpotApp({
    super.key,
    required this.hasSeenOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportSpot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: hasSeenOnboarding ? const MainScreen() : const OnboardingScreen(),
    );
  }
}
