import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sportspot/main.dart';
import 'package:sportspot/providers/auth_provider.dart';

void main() {
  testWidgets('SportSpotApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const SportSpotApp(hasSeenOnboarding: true),
      ),
    );

    expect(find.byType(SportSpotApp), findsOneWidget);
  });
}
