import 'package:flutter_test/flutter_test.dart';
import 'package:sportspot/core/utils/maps_launcher.dart';
import 'package:sportspot/data/models/venue_model.dart';
import 'package:sportspot/screens/venues/venue_detail_screen.dart';
import 'package:flutter/material.dart';

void main() {
  group('MapsLauncher Directions Tests', () {
    test('MapsLauncher returns false when neither coordinates nor address provided', () async {
      final res = await MapsLauncher.openDirections();
      expect(res, isFalse);
    });

    test('MapsLauncher returns false when address is empty and coordinates are 0.0', () async {
      final res = await MapsLauncher.openDirections(
        latitude: 0.0,
        longitude: 0.0,
        address: '   ',
      );
      expect(res, isFalse);
    });

    testWidgets('VenueDetailScreen has working Chỉ đường button', (tester) async {
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
        amenities: 'Bãi đỗ ô tô, Căn tin',
        distanceKm: 2.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VenueDetailScreen(venue: sampleVenue),
        ),
      );
      await tester.pump();

      final directionBtn = find.text('Chỉ đường');
      expect(directionBtn, findsOneWidget);

      // Verify tapping does not throw exception
      await tester.tap(directionBtn);
      await tester.pump();
    });
  });
}
