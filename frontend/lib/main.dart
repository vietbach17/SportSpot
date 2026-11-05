import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/api_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/services/fcm_push_service.dart';
import 'data/services/floating_notification_service.dart';
import 'data/services/token_service.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/venue_provider.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/responsive_phone_frame.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo cấu hình địa chỉ Server API
  await ApiConstants.init();

  // Kiểm tra cờ xem Onboarding
  final bool hasSeenOnboarding = await TokenService.isOnboardingSeen();

  // Khởi tạo dịch vụ Push notification (FCM) với background handler
  await FcmPushService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initializeAuth(),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => VenueProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TicketProvider()..loadTickets(),
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
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'SportSpot',
      debugShowCheckedModeBanner: false,
      navigatorKey: FloatingNotificationService.navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) => ResponsivePhoneFrame(child: child ?? const SizedBox.shrink()),
      home: hasSeenOnboarding ? const MainScreen() : const OnboardingScreen(),
    );
  }
}
