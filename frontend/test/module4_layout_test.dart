import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sportspot/core/network/api_client.dart';
import 'package:sportspot/data/repositories/mock_match_repository.dart';
import 'package:sportspot/providers/auth_provider.dart';
import 'package:sportspot/screens/matches/match_checkout_screen.dart';
import 'package:sportspot/screens/matches/match_feed_screen.dart';
import 'package:sportspot/widgets/recruitment_form.dart';
import 'package:sportspot/widgets/match_ui.dart';

const capture = bool.fromEnvironment('UPDATE_MODULE4_PREVIEWS');

Future<void> preview(GlobalKey key, String name) async {
  if (!capture) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final folder = Directory('build/module4_preview')
    ..createSync(recursive: true);
  await File('${folder.path}/$name.png')
      .writeAsBytes(bytes!.buffer.asUint8List());
  image.dispose();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  setUpAll(() async {
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    );
    final package = (config['packages'] as List).firstWhere(
      (p) => p['name'] == 'flutter',
    );
    final sdk = Directory.fromUri(Uri.parse(package['rootUri'])).parent.parent;
    final fonts = '${sdk.path}/bin/cache/artifacts/material_fonts';
    for (final family in ['Roboto', 'Ahem']) {
      final loader = FontLoader(family);
      for (final file in [
        'roboto-regular.ttf',
        'roboto-bold.ttf',
        'roboto-black.ttf',
      ]) {
        loader.addFont(
          Future.value(
            ByteData.sublistView(File('$fonts/$file').readAsBytesSync()),
          ),
        );
      }
      await loader.load();
    }
    await (FontLoader('MaterialIcons')..addFont(
          Future.value(
            ByteData.sublistView(
              File('$fonts/materialicons-regular.otf').readAsBytesSync(),
            ),
          ),
        ))
        .load();
  });
  for (final size in [
    const Size(320, 740),
    const Size(390, 1000),
    const Size(1100, 900),
  ]) {
    testWidgets('Match feed and detail fit ${size.width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final repo = MockMatchRepository();
      final scale = size.width == 320 ? 1.3 : 1.0;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: key,
              child: MatchFeedScreen(repository: repo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => preview(key, 'feed_${size.width.toInt()}'));
      await tester.scrollUntilVisible(
        find.text('Sân thể thao demo'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Sân thể thao demo'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết kèo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Tham gia kèo · Thanh toán mock'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      // Back to the feed to verify the sport filter still reaches the repository.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pickleball'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pickleball'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có kèo phù hợp'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Detail and staff desk previews', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: MatchDetailScreen(id: 1, repository: MockMatchRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => preview(key, 'detail'));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: MatchFeedScreen(
              repository: MockMatchRepository(actorId: 3, isStaff: true),
              staff: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => preview(key, 'staff'));
  });

  testWidgets('Recruitment form is usable with large text on narrow phones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: MatchTheme(
          child: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  child: RecruitmentForm(courtPrice: 600000, onChanged: (_) {}),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('60.000 đ'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => preview(key, 'recruitment'));
  });

  testWidgets('Checkout opens with a responsive pinned summary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: MatchCheckoutScreen(apiClient: _CheckoutClient()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tiền sân tạm tính'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => preview(key, 'checkout'));
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('SportSpot Arena').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sân 01').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('18:00'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('18:00'));
    await tester.pumpAndSettle();
    expect(find.text('300.000 đ'), findsWidgets);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => preview(key, 'checkout_slots'));
  });
}

class _CheckoutClient implements ApiClient {
  @override
  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    if (endpoint == '/api/venues') {
      return [
        {'id': 1, 'name': 'SportSpot Arena'},
      ];
    }
    if (endpoint == '/api/venues/1') {
      return {
        'subVenues': [
          {'id': 1, 'name': 'Sân 01', 'isActive': true},
        ],
      };
    }
    return [
      for (var hour = 17; hour < 22; hour++)
        {
          'slotId': hour,
          'startTime': '$hour:00',
          'endTime': '${hour + 1}:00',
          'price': 300000,
          'isBooked': hour == 19,
        },
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
