import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sportspot/main.dart';
import 'package:sportspot/providers/auth_provider.dart';
import 'package:sportspot/providers/booking_provider.dart';
import 'package:sportspot/providers/venue_provider.dart';
import 'test_http_client.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('SportSpotApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => BookingProvider()),
          ChangeNotifierProvider(create: (_) => VenueProvider()),
        ],
        child: const SportSpotApp(hasSeenOnboarding: true),
      ),
    );

    expect(find.byType(SportSpotApp), findsOneWidget);
  });
}
