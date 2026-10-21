import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sportspot/data/repositories/mock_match_repository.dart';
import 'package:sportspot/providers/auth_provider.dart';
import 'package:sportspot/screens/matches/match_feed_screen.dart';
import 'package:sportspot/widgets/recruitment_form.dart';

void main() {
  testWidgets('Recruitment preview and invalid headcounts', (tester) async {
    final key = GlobalKey<FormState>();
    RecruitmentValue value = const RecruitmentValue();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(
              key: key,
              child: RecruitmentForm(
                courtPrice: 600000,
                onChanged: (v) => value = v,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('60.000 đ'), findsOneWidget);
    expect(value.enabled, isTrue);
    await tester.enterText(find.byType(TextFormField).first, '4');
    await tester.pump();
    expect(value.valid, isFalse);
    expect(key.currentState!.validate(), isFalse);
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.pump();
    expect(key.currentState!.validate(), isTrue);
    expect(value.toJson()['neededPlayers'], 4);
  });

  testWidgets('Guest can view feed and match details', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          home: MatchFeedScreen(repository: MockMatchRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sân thể thao demo'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sân thể thao demo'), findsOneWidget);
    expect(find.textContaining('Thiếu 4 người'), findsOneWidget);
    await tester.tap(find.text('Sân thể thao demo'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết kèo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tham gia kèo · Thanh toán mock'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tham gia kèo · Thanh toán mock'), findsOneWidget);
  });

  test(
    'Mock joins preserve cost, prevent duplicates, enforce staff permissions',
    () async {
      final repo = MockMatchRepository();
      await repo.join(1);
      expect((await repo.detail(1)).balance, 360000);
      expect((await repo.detail(1)).members.single.userId, 2);
      await expectLater(repo.join(1), throwsStateError);
      await expectLater(repo.assign(1), throwsStateError);
      await repo.leave(1);
      expect((await repo.detail(1)).balance, 420000);
    },
  );
}
