import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportspot/widgets/venue_image_carousel.dart';
import 'package:sportspot/widgets/venue_booking_sheet.dart';
import 'package:sportspot/screens/venues/venue_detail_screen.dart';
import 'package:sportspot/data/models/venue_model.dart';
import 'package:sportspot/data/sportspot_models.dart';
import 'test_http_client.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  group('VenueImageCarousel Widget Tests', () {
    final testImages = [
      'https://example.com/court1.jpg',
      'https://example.com/court2.jpg',
      'https://example.com/court3.jpg',
      'https://example.com/court4.jpg',
    ];

    testWidgets('renders PageView and correct number of pagination dots matching images count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueImageCarousel(
              images: testImages,
              openUntil: '22:30',
            ),
          ),
        ),
      );
      await tester.pump();

      // PageView is present
      expect(find.byKey(const Key('venue_image_pageview')), findsOneWidget);

      // Pagination dots container is present
      expect(find.byKey(const Key('venue_carousel_pagination')), findsOneWidget);

      // All 4 dots are rendered (báo số lượng ảnh)
      for (int i = 0; i < testImages.length; i++) {
        expect(find.byKey(Key('carousel_dot_$i')), findsOneWidget);
      }

      // Initial counter shows 1/4
      expect(find.byKey(const Key('carousel_counter')), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);

      // Sân xác thực and opening hours badges are shown
      expect(find.text('SÂN XÁC THỰC'), findsOneWidget);
      expect(find.text('06:00 - 22:30'), findsOneWidget);

      // Prev and Next navigation buttons are present
      expect(find.byKey(const Key('carousel_btn_prev')), findsOneWidget);
      expect(find.byKey(const Key('carousel_btn_next')), findsOneWidget);
    });

    testWidgets('transitions to next image when tapping next button',
        (WidgetTester tester) async {
      int? reportedPage;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueImageCarousel(
              images: testImages,
              onPageChanged: (page) => reportedPage = page,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap next button
      await tester.tap(find.byKey(const Key('carousel_btn_next')));
      await tester.pumpAndSettle();

      expect(reportedPage, 1);
      expect(find.text('2/4'), findsOneWidget);

      // Tap next button again
      await tester.tap(find.byKey(const Key('carousel_btn_next')));
      await tester.pumpAndSettle();

      expect(reportedPage, 2);
      expect(find.text('3/4'), findsOneWidget);
    });

    testWidgets('transitions to previous image when tapping prev button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueImageCarousel(
              images: testImages,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap prev from first image wraps to last image (page 3)
      await tester.tap(find.byKey(const Key('carousel_btn_prev')));
      await tester.pumpAndSettle();

      expect(find.text('4/4'), findsOneWidget);

      // Tap prev again goes to page 2
      await tester.tap(find.byKey(const Key('carousel_btn_prev')));
      await tester.pumpAndSettle();

      expect(find.text('3/4'), findsOneWidget);
    });

    testWidgets('transitions to corresponding image when tapping a pagination dot',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueImageCarousel(
              images: testImages,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap dot index 2 (third image)
      await tester.tap(find.byKey(const Key('carousel_dot_2')));
      await tester.pumpAndSettle();

      expect(find.text('3/4'), findsOneWidget);

      // Tap dot index 0 (first image)
      await tester.tap(find.byKey(const Key('carousel_dot_0')));
      await tester.pumpAndSettle();

      expect(find.text('1/4'), findsOneWidget);
    });

    testWidgets('swiping/scrolling gestures navigate carousel images',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueImageCarousel(
              images: testImages,
            ),
          ),
        ),
      );
      await tester.pump();

      // Swipe left on PageView (scroll forward)
      await tester.fling(find.byKey(const Key('venue_image_pageview')), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('2/4'), findsOneWidget);
    });

    testWidgets('tapping image opens fullscreen lightbox with InteractiveViewer, pagination, and close button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueImageCarousel(
              images: testImages,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap on image 0 to open lightbox
      await tester.tap(find.byKey(const Key('carousel_image_tap_0')));
      await tester.pumpAndSettle();

      // Lightbox is opened
      expect(find.byType(VenueImageLightbox), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsWidgets);
      expect(find.text('Xem Chi Tiết Sân (1/4)'), findsOneWidget);
      expect(find.byKey(const Key('lightbox_pagination')), findsOneWidget);
      expect(find.byKey(const Key('lightbox_btn_close')), findsOneWidget);

      // Lightbox navigation to next image
      await tester.tap(find.byKey(const Key('lightbox_btn_next')));
      await tester.pumpAndSettle();
      expect(find.text('Xem Chi Tiết Sân (2/4)'), findsOneWidget);

      // Close lightbox
      await tester.tap(find.byKey(const Key('lightbox_btn_close')));
      await tester.pumpAndSettle();

      // Lightbox is closed and carousel index is synchronized
      expect(find.byType(VenueImageLightbox), findsNothing);
      expect(find.text('2/4'), findsOneWidget);
    });
  });

  group('VenueDetailScreen & Booking Modal Carousel Integration Tests', () {
    testWidgets('VenueDetailScreen displays VenueImageCarousel with pagination dots on venue booking page',
        (WidgetTester tester) async {
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
        galleryImages: [
          'https://example.com/kyhoa1.jpg',
          'https://example.com/kyhoa2.jpg',
          'https://example.com/kyhoa3.jpg',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VenueDetailScreen(venue: sampleVenue),
        ),
      );
      await tester.pumpAndSettle();

      // Venue title is present
      expect(find.text('CLB Cầu Lông Kỳ Hòa'), findsWidgets);

      // VenueImageCarousel is rendered
      expect(find.byType(VenueImageCarousel), findsOneWidget);
      expect(find.byKey(const Key('venue_carousel_pagination')), findsOneWidget);

      // 3 pagination dots are visible
      expect(find.byKey(const Key('carousel_dot_0')), findsOneWidget);
      expect(find.byKey(const Key('carousel_dot_1')), findsOneWidget);
      expect(find.byKey(const Key('carousel_dot_2')), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);

      // Interactive switch via next button works in VenueDetailScreen
      await tester.tap(find.byKey(const Key('carousel_btn_next')));
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      // Đặt Sân Ngay button is present on the page
      expect(find.text('Đặt Sân Ngay'), findsOneWidget);
    });

    testWidgets('VenueBookingModal opens and displays VenueImageCarousel with pagination dots',
        (WidgetTester tester) async {
      final venue = SportSpotVenue(
        id: '1',
        name: 'Sân Cầu Lông Hoàng Hoa Thám',
        address: 'Tân Bình, TP.HCM',
        distance: '1.8 km',
        rating: 4.8,
        reviewCount: 50,
        priceFrom: 80000,
        openUntil: '22:00',
        totalCourts: 4,
        isVerified: true,
        image: 'https://example.com/hht1.jpg',
        images: [
          'https://example.com/hht1.jpg',
          'https://example.com/hht2.jpg',
          'https://example.com/hht3.jpg',
        ],
        disciplines: const ['Cầu lông'],
        amenities: const [],
        slotsAvailableToday: 6,
        courts: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => VenueBookingModal.show(ctx, venue: venue),
                child: const Text('Mở Modal Đặt Sân'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap button to open modal
      await tester.tap(find.text('Mở Modal Đặt Sân'));
      await tester.pumpAndSettle();

      // Modal title and carousel are displayed
      expect(find.text('Thông Tin Đặt Sân'), findsOneWidget);
      expect(find.byType(VenueImageCarousel), findsOneWidget);
      expect(find.byKey(const Key('venue_carousel_pagination')), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);

      // Modal has Đặt Sân Ngay CTA
      expect(find.text('Đặt Sân Ngay'), findsOneWidget);
    });
  });
}
