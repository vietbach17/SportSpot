import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sportspot/data/models/venue_model.dart';
import 'package:sportspot/data/repositories/venue_repository.dart';
import 'package:sportspot/providers/auth_provider.dart';
import 'package:sportspot/providers/booking_provider.dart';
import 'package:sportspot/providers/venue_provider.dart';
import 'package:sportspot/screens/home/home_screen.dart';
import 'package:sportspot/screens/venues/venue_detail_screen.dart';
import 'test_http_client.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  group('Module 2 - Venue Discovery Unit & Widget Tests', () {
    late VenueRepository repo;

    setUp(() {
      repo = VenueRepository();
    });

    test('VenueRepository fetches 5 HCMC venues with mock fallback', () async {
      final venues = await repo.getVenues(
        userLat: 10.8498,
        userLng: 106.7720,
        radiusKm: 20.0,
      );
      expect(venues.isNotEmpty, isTrue);
      expect(venues.length, greaterThanOrEqualTo(5));

      final sports = await repo.getSports();
      expect(sports.length, greaterThanOrEqualTo(4));
    });

    test('VenueRepository filters by sportId correctly', () async {
      final badmintonVenues = await repo.getVenues(sportId: 1);
      for (final v in badmintonVenues) {
        expect(v.sportId, equals(1));
      }
    });

    test('VenueRepository filters by radius correctly', () async {
      final nearbyVenues = await repo.getVenues(
        userLat: 10.8498,
        userLng: 106.7720,
        radiusKm: 5.0,
      );
      for (final v in nearbyVenues) {
        if (v.distanceKm != null) {
          expect(v.distanceKm!, lessThanOrEqualTo(5.0));
        }
      }
    });

    testWidgets('VenueDetailScreen renders venue details, hotline, directions and booking button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleVenue = VenueItemModel(
        id: 1,
        sportId: 1,
        sportName: 'Cầu lông',
        name: 'CLB Cầu Lông Kỳ Hòa',
        address: 'Số 238 đường 3/2, Phường 12',
        district: 'Quận 10',
        latitude: 10.7725,
        longitude: 106.6710,
        hotline: '0903123456',
        basePrice: 100000,
        peakPrice: 140000,
        rating: 4.9,
        amenities: 'Bãi đỗ ô tô, Căn tin, Phòng tắm nóng lạnh',
        description: 'Cụm 8 sân thảm tiêu chuẩn Yonex quốc tế.',
        distanceKm: 2.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VenueDetailScreen(venue: sampleVenue),
        ),
      );
      await tester.pump();

      expect(find.text('CLB Cầu Lông Kỳ Hòa'), findsWidgets);
      expect(find.text('Hotline'), findsOneWidget);
      expect(find.text('Chỉ đường'), findsOneWidget);
      expect(find.text('Đặt Sân Ngay'), findsOneWidget);
    });

    testWidgets('HomeScreen renders search bar, 4 sport chips and radius slider',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => BookingProvider()),
            ChangeNotifierProvider(create: (_) => VenueProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Bán kính quét khoảng cách'), findsOneWidget);
    });
  });
}
