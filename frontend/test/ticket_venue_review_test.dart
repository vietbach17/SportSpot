import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportspot/data/models/review_model.dart';
import 'package:sportspot/data/models/ticket_model.dart';
import 'package:sportspot/data/models/venue_model.dart';
import 'package:sportspot/data/repositories/mock_ticket_repository.dart';
import 'package:sportspot/data/repositories/review_repository.dart';
import 'package:sportspot/data/repositories/ticket_repository.dart';
import 'package:sportspot/data/repositories/venue_repository.dart';
import 'package:sportspot/screens/tickets/my_tickets_screen.dart';
import 'package:sportspot/screens/venues/venue_detail_screen.dart';
import 'package:sportspot/widgets/venue_review_sheet.dart';

import 'test_http_client.dart';

TicketModel ticket(int id, String status) => TicketModel(
  bookingId: id,
  bookingCode: 'TEST$id',
  venueId: 42,
  venueName: 'Sân đã đặt',
  subVenueName: 'Sân 2',
  sportName: 'Cầu lông',
  address: 'Thủ Đức',
  playDate: '2026-11-06',
  timeSlots: ['18:00-19:00'],
  courtPrice: 100000,
  totalPrice: 100000,
  depositAmount: 50000,
  remainingBalance: 50000,
  status: status,
  qrPayload: '',
);

class Tickets extends MockTicketRepository {
  @override
  Future<TicketSyncResult> getMyTickets({bool forceOffline = false}) async =>
      TicketSyncResult(
        tickets: [
          ticket(1, 'Completed'),
          ticket(2, 'Upcoming'),
          ticket(3, 'Cancelled'),
        ],
        isFromSqliteOffline: false,
      );
}

class Venues extends VenueRepository {
  int? requestedId;
  @override
  Future<VenueItemModel> getVenueDetail(
    int id, {
    bool allowMockFallback = true,
  }) async {
    requestedId = id;
    return VenueItemModel(
      id: id,
      sportId: 1,
      sportName: 'Cầu lông',
      name: 'Sân đã đặt',
      address: 'Thủ Đức',
      district: '',
      latitude: 0,
      longitude: 0,
      hotline: '',
      basePrice: 100000,
      peakPrice: 100000,
    );
  }
}

class Reviews extends MockReviewRepository {
  bool fail = false;
  int calls = 0;
  int? venueId;
  int? rating;
  String? comment;
  Completer<void>? pending;
  @override
  Future<ReviewModel> submitReview(
    int venueId,
    int rating,
    String comment,
  ) async {
    calls++;
    this.venueId = venueId;
    this.rating = rating;
    this.comment = comment;
    if (pending != null) await pending!.future;
    if (fail) throw Exception('offline');
    return super.submitReview(venueId, rating, comment);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = MockHttpOverrides();
  });
  tearDown(() => HttpOverrides.global = null);

  testWidgets(
    'Tickets open the booked venue and only used tickets offer reviews',
    (tester) async {
    tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final venues = Venues();
      await tester.pumpWidget(
        MaterialApp(
          home: MyTicketsScreen(
            repository: Tickets(),
            venueRepository: venues,
            reviewRepository: Reviews(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final id in [1, 2, 3]) {
        expect(find.byKey(Key('view_venue_$id')), findsOneWidget);
      }
      expect(find.byKey(const Key('review_venue_1')), findsOneWidget);
      expect(find.byKey(const Key('review_venue_2')), findsNothing);
      expect(find.byKey(const Key('review_venue_3')), findsNothing);
      await tester.tap(find.byKey(const Key('view_venue_1')));
      await tester.pumpAndSettle();
      expect(venues.requestedId, 42);
      expect(
        tester
            .widget<VenueDetailScreen>(find.byType(VenueDetailScreen))
            .venue
            .id,
        42,
      );
      expect(find.text('Sân đã đặt'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('review_venue_1')));
      await tester.pumpAndSettle();
      expect(find.byType(VenueReviewSheet), findsOneWidget);
      expect(
        tester.widget<VenueReviewSheet>(find.byType(VenueReviewSheet)).venueId,
        42,
      );
    },
  );

  testWidgets(
    'Review validates, retains failed input, and submits selected rating once',
    (tester) async {
      final reviews = Reviews()..fail = true;
      bool? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  submitted = await VenueReviewSheet.show(
                    context,
                    venueId: 42,
                    venueName: 'Sân đã đặt',
                    repository: reviews,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submit_venue_review')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập nội dung nhận xét'), findsOneWidget);
      expect(reviews.calls, 0);
      await tester.tap(find.byKey(const Key('review_star_3')));
      await tester.enterText(
        find.byKey(const Key('review_comment')),
        '  Sân sạch, đèn sáng  ',
      );
      await tester.tap(find.byKey(const Key('submit_venue_review')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa gửi được đánh giá'), findsOneWidget);
      expect(find.text('  Sân sạch, đèn sáng  '), findsOneWidget);
      expect(submitted, isNull);
      reviews.fail = false;
      reviews.pending = Completer<void>();
      await tester.tap(find.byKey(const Key('submit_venue_review')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('submit_venue_review')))
            .onPressed,
        isNull,
      );
      reviews.pending!.complete();
      await tester.pumpAndSettle();
      expect(submitted, isTrue);
      expect(reviews.calls, 2);
      expect(reviews.venueId, 42);
      expect(reviews.rating, 3);
      expect(reviews.comment, 'Sân sạch, đèn sáng');
    },
  );
}
