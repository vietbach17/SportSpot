import 'dart:math';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../models/booking_model.dart';

abstract class IBookingRepository {
  Future<VenueDetailModel> getVenueDetail(int venueId);
  Future<List<VenueSlotModel>> getSlots(int venueId, int subVenueId, DateTime date);
  Future<BookingResultModel> createBooking(BookingRequestModel request);
}

class RemoteBookingRepository implements IBookingRepository {
  final ApiClient _api = ApiClient();

  @override
  Future<VenueDetailModel> getVenueDetail(int venueId) async {
    final response = await _api.get('/api/venues/$venueId', requiresAuth: false);
    return VenueDetailModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<VenueSlotModel>> getSlots(int venueId, int subVenueId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final response = await _api.get(
      '/api/venues/$venueId/subvenues/$subVenueId/slots?date=$dateStr',
      requiresAuth: false,
    );
    final list = response as List<dynamic>;
    return list.map((e) => VenueSlotModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<BookingResultModel> createBooking(BookingRequestModel request) async {
    final response = await _api.post('/api/bookings', request.toJson());
    return BookingResultModel.fromJson(response as Map<String, dynamic>);
  }
}

class MockBookingRepository implements IBookingRepository {
  final Random _rnd = Random();

  @override
  Future<VenueDetailModel> getVenueDetail(int venueId) async {
    await Future.delayed(const Duration(milliseconds: 300));
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
      amenities: 'Bãi đỗ ô tô, Căn tin, Phòng tắm, Cho thuê vợt, Wifi',
      imageUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      subVenues: [
        SubVenueModel(id: 1, name: 'Sân Thảm 1'),
        SubVenueModel(id: 2, name: 'Sân Thảm 2'),
        SubVenueModel(id: 3, name: 'Sân Thảm 3'),
      ],
      services: [
        VenueServiceModel(id: 1, name: 'Nước điện giải Revive', type: 'Sale', price: 15000, stockQuantity: 100),
        VenueServiceModel(id: 2, name: 'Nước suối Aquafina 500ml', type: 'Sale', price: 10000, stockQuantity: 200),
        VenueServiceModel(id: 3, name: 'Thuê vợt thi đấu cao cấp', type: 'Rental', price: 30000, stockQuantity: 20),
        VenueServiceModel(id: 4, name: 'Ống cầu lông / Bóng tập', type: 'Rental', price: 25000, stockQuantity: 30),
      ],
    );
  }

  @override
  Future<List<VenueSlotModel>> getSlots(int venueId, int subVenueId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    final baseSlots = [
      {'id': 1, 'start': '06:00', 'end': '07:00', 'peak': false},
      {'id': 2, 'start': '07:00', 'end': '08:00', 'peak': false},
      {'id': 3, 'start': '08:00', 'end': '09:00', 'peak': false},
      {'id': 4, 'start': '09:00', 'end': '10:00', 'peak': false},
      {'id': 5, 'start': '10:00', 'end': '11:00', 'peak': false},
      {'id': 6, 'start': '14:00', 'end': '15:00', 'peak': false},
      {'id': 7, 'start': '15:00', 'end': '16:00', 'peak': false},
      {'id': 8, 'start': '16:00', 'end': '17:00', 'peak': false},
      {'id': 9, 'start': '17:00', 'end': '18:00', 'peak': true},
      {'id': 10, 'start': '18:00', 'end': '19:00', 'peak': true},
      {'id': 11, 'start': '19:00', 'end': '20:00', 'peak': true},
      {'id': 12, 'start': '20:00', 'end': '21:00', 'peak': true},
      {'id': 13, 'start': '21:00', 'end': '22:00', 'peak': true},
    ];

    // Seed predictable booked slot for testing: slot 10 (18:00-19:00) on Sân Thảm 2
    return baseSlots.map((s) {
      final slotId = s['id'] as int;
      final start = s['start'] as String;
      final end = s['end'] as String;
      final isPeak = s['peak'] as bool;

      bool isPast = false;
      if (isToday) {
        final endHour = int.tryParse(end.split(':')[0]) ?? 0;
        if (now.hour >= endHour) {
          isPast = true;
        }
      }

      // Giả lập slot 9 & 10 trên sân 1 bị đặt vào ngày mai
      bool isBooked = isPast;
      if (!isPast && subVenueId == 1 && (slotId == 9 || slotId == 10) && date.day % 2 == 0) {
        isBooked = true;
      }

      final status = isBooked ? (isPast ? 'Past' : 'Booked') : 'Available';

      return VenueSlotModel(
        slotId: slotId,
        startTime: start,
        endTime: end,
        isPeak: isPeak,
        price: isPeak ? 120000 : 90000,
        isBooked: isBooked,
        status: status,
      );
    }).toList();
  }

  @override
  Future<BookingResultModel> createBooking(BookingRequestModel request) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Simulated conflict test if slot 13 is selected on odd subVenue
    if (request.slotIds.contains(999)) {
      throw ApiException(409, 'Rất tiếc! Khung giờ vừa có người khác đặt trước. Vui lòng chọn khung giờ khác.');
    }

    final code = 'SP-${_rnd.nextInt(900000) + 100000}';
    final courtPrice = request.slotIds.length * 100000;
    int servicesPrice = 0;
    for (var s in request.services) {
      servicesPrice += s.quantity * 15000;
    }
    final total = courtPrice + servicesPrice;
    final deposit = request.depositPercentage >= 100 ? total : (total * 0.3).round();

    return BookingResultModel(
      bookingId: _rnd.nextInt(1000) + 1,
      bookingCode: code,
      venueName: 'CLB Cầu Lông Cầu Giấy',
      subVenueName: 'Sân Thảm ${request.subVenueId}',
      sportName: 'Cầu lông',
      address: 'Số 35 Trần Quý Kiên, Dịch Vọng',
      playDate: request.playDate,
      timeSlots: request.slotIds.map((id) => 'Slot $id').toList(),
      courtPrice: courtPrice,
      servicesPrice: servicesPrice,
      totalPrice: total,
      depositAmount: deposit,
      remainingBalance: total - deposit,
      status: 'Upcoming',
      qrPayload: 'SPORTSPOT|$code|1|Host|MOCK_MD5_HASH',
      isCheckedIn: false,
    );
  }
}
