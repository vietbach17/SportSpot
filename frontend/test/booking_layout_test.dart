import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sportspot/data/models/booking_model.dart';
import 'package:sportspot/data/repositories/booking_repository.dart';
import 'package:sportspot/providers/booking_provider.dart';
import 'package:sportspot/screens/booking/booking_checkout_screen.dart';
import 'package:sportspot/screens/booking/court_slots_screen.dart';
import 'package:sportspot/widgets/date_selector_widget.dart';
import 'package:sportspot/widgets/time_slot_grid_widget.dart';

class ImmediateBookingRepository implements IBookingRepository {
  @override
  Future<VenueDetailModel> getVenueDetail(int venueId) async {
    return VenueDetailModel(
      id: venueId,
      sportId: 1,
      sportName: 'Cầu lông',
      name: 'CLB Cầu Lông Cầu Giấy',
      address: 'Số 35 Trần Quý Kiên, Dịch Vọng',
      district: 'Cầu Giấy',
      basePrice: 90000,
      peakPrice: 120000,
      rating: 4.9,
      amenities: 'Bãi đỗ ô tô, Căn tin',
      imageUrl: '',
      subVenues: [
        SubVenueModel(id: 1, name: 'Sân Thảm 1'),
        SubVenueModel(id: 2, name: 'Sân Thảm 2'),
      ],
      services: [
        VenueServiceModel(id: 1, name: 'Nước Revive', type: 'Sale', price: 15000, stockQuantity: 100),
      ],
    );
  }

  @override
  Future<List<VenueSlotModel>> getSlots(int venueId, int subVenueId, DateTime date) async {
    return [
      VenueSlotModel(
        slotId: 1,
        startTime: '06:00',
        endTime: '07:00',
        price: 90000,
        isPeak: false,
        isBooked: false,
        status: 'Available',
      ),
      VenueSlotModel(
        slotId: 2,
        startTime: '07:00',
        endTime: '08:00',
        price: 90000,
        isPeak: false,
        isBooked: false,
        status: 'Available',
      ),
    ];
  }

  @override
  Future<BookingResultModel> createBooking(BookingRequestModel request) async {
    return BookingResultModel(
      bookingId: 1,
      bookingCode: 'BK-TEST-1234',
      venueName: 'CLB Cầu Lông Cầu Giấy',
      subVenueName: 'Sân Thảm 1',
      sportName: 'Cầu lông',
      address: '35 Trần Quý Kiên',
      playDate: '2026-10-22',
      timeSlots: ['06:00-07:00'],
      courtPrice: 90000,
      servicesPrice: 0,
      totalPrice: 90000,
      depositAmount: 90000,
      remainingBalance: 0,
      status: 'Confirmed',
      qrPayload: 'SPORTSPOT-BK-TEST-1234',
      isCheckedIn: false,
    );
  }
}

void main() {
  testWidgets('CourtSlotsScreen renders with MatchTheme on 390px', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = ImmediateBookingRepository();
    final provider = BookingProvider(repository: repo);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: CourtSlotsScreen(venueId: 1),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('CLB Cầu Lông Cầu Giấy'), findsWidgets);
    expect(find.text('Chọn sân đấu'), findsOneWidget);
    expect(find.text('Thời gian & Khung giờ'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TimeSlotGridWidget and DateSelectorWidget render with Module 4 styling', (tester) async {
    final now = DateTime.now();
    final dates = List.generate(7, (i) => now.add(Duration(days: i)));
    DateTime selected = dates.first;

    final slots = <VenueSlotModel>[
      VenueSlotModel(
        slotId: 1,
        startTime: '06:00',
        endTime: '07:00',
        price: 90000,
        isPeak: false,
        isBooked: false,
        status: 'Available',
      ),
      VenueSlotModel(
        slotId: 2,
        startTime: '07:00',
        endTime: '08:00',
        price: 90000,
        isPeak: false,
        isBooked: false,
        status: 'Available',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                DateSelectorWidget(
                  dateRange: dates,
                  selectedDate: selected,
                  onDateSelected: (d) => selected = d,
                ),
                TimeSlotGridWidget(
                  slots: slots,
                  selectedSlots: [slots.first],
                  onSlotToggled: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('06:00 - 07:00'), findsOneWidget);
    expect(find.text('07:00 - 08:00'), findsOneWidget);
  });

  testWidgets('BookingCheckoutScreen renders with steps and hold timer', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = ImmediateBookingRepository();
    final provider = BookingProvider(repository: repo);
    await provider.loadVenue(1);
    provider.toggleSlot(provider.slots.first);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: BookingCheckoutScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Tóm tắt & Đặt sân'), findsOneWidget);
    expect(find.text('Thông tin đặt sân'), findsOneWidget);
    expect(find.text('Bảng kê chi phí'), findsOneWidget);
    expect(find.textContaining('Xác nhận đặt sân'), findsOneWidget);

    provider.cancelHoldTimer();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
