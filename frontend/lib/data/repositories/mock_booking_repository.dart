import 'dart:math';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import 'booking_repository.dart';

class MockBookingRepository implements BookingRepository {
  @override
  Future<List<TimeSlotModel>> getSlots(int venueId, int subVenueId, DateTime date) async {
    // Giả lập độ trễ mạng nhẹ
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isPastDate = date.isBefore(DateTime(now.year, now.month, now.day));

    final isSoccer = venueId == 2;
    final basePrice = isSoccer ? 350000 : 90000;
    final peakPrice = isSoccer ? 600000 : 120000;

    final baseSlots = [
      {'id': 1, 'start': '06:00', 'end': '07:00', 'isPeak': false, 'price': basePrice},
      {'id': 2, 'start': '07:00', 'end': '08:00', 'isPeak': false, 'price': basePrice},
      {'id': 3, 'start': '08:00', 'end': '09:00', 'isPeak': false, 'price': basePrice},
      {'id': 4, 'start': '09:00', 'end': '10:00', 'isPeak': false, 'price': basePrice},
      {'id': 5, 'start': '10:00', 'end': '11:00', 'isPeak': false, 'price': basePrice},
      {'id': 6, 'start': '14:00', 'end': '15:00', 'isPeak': false, 'price': basePrice},
      {'id': 7, 'start': '15:00', 'end': '16:00', 'isPeak': false, 'price': basePrice},
      {'id': 8, 'start': '16:00', 'end': '17:00', 'isPeak': false, 'price': basePrice},
      {'id': 9, 'start': '17:00', 'end': '18:00', 'isPeak': true, 'price': peakPrice},
      {'id': 10, 'start': '18:00', 'end': '19:00', 'isPeak': true, 'price': peakPrice},
      {'id': 11, 'start': '19:00', 'end': '20:00', 'isPeak': true, 'price': peakPrice},
      {'id': 12, 'start': '20:00', 'end': '21:00', 'isPeak': true, 'price': peakPrice},
      {'id': 13, 'start': '21:00', 'end': '22:00', 'isPeak': true, 'price': peakPrice},
    ];

    // Một số slot mặc định đã kín người đặt để test
    final bookedSlotIds = subVenueId % 2 == 0 ? [9, 10] : [10, 11];

    return baseSlots.map((s) {
      final slotId = s['id'] as int;
      final start = s['start'] as String;
      final end = s['end'] as String;
      final isPeak = s['isPeak'] as bool;
      final price = s['price'] as int;

      String status = 'Available';
      if (isPastDate) {
        status = 'Past';
      } else if (isToday) {
        final endHour = int.parse(end.split(':')[0]);
        if (now.hour >= endHour) {
          status = 'Past';
        } else if (bookedSlotIds.contains(slotId)) {
          status = 'Booked';
        }
      } else if (bookedSlotIds.contains(slotId)) {
        status = 'Booked';
      }

      return TimeSlotModel(
        slotId: slotId,
        startTime: start,
        endTime: end,
        price: price,
        isPeak: isPeak,
        status: status,
      );
    }).toList();
  }

  @override
  Future<List<ServiceItemModel>> getServices(int venueId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (venueId == 2) {
      return [
        ServiceItemModel(
          serviceId: 4,
          name: 'Nước khoáng bù điện giải Revive',
          type: 'Sale',
          price: 15000,
          quantity: 0,
        ),
        ServiceItemModel(
          serviceId: 5,
          name: 'Thuê bộ áo pitch tập luyện (10 áo)',
          type: 'Rental',
          price: 40000,
          quantity: 0,
        ),
        ServiceItemModel(
          serviceId: 6,
          name: 'Thuê bóng thi đấu Động Lực số 5',
          type: 'Rental',
          price: 30000,
          quantity: 0,
        ),
      ];
    }

    return [
      ServiceItemModel(
        serviceId: 1,
        name: 'Nước suối Aquafina 500ml',
        type: 'Sale',
        price: 10000,
        quantity: 0,
      ),
      ServiceItemModel(
        serviceId: 2,
        name: 'Thuê vợt Yonex chính hãng',
        type: 'Rental',
        price: 30000,
        quantity: 0,
      ),
      ServiceItemModel(
        serviceId: 3,
        name: 'Ống cầu lông Hải Yến (12 quả)',
        type: 'Sale',
        price: 60000,
        quantity: 0,
      ),
    ];
  }

  @override
  Future<BookingResponseModel> createBooking(BookingRequestModel request) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Mô phỏng 409 Conflict nếu chọn slotId = 99 (để test Concurrency UI)
    if (request.slotIds.contains(99)) {
      throw Exception('Rất tiếc! Khung giờ này vừa có người khác đặt trước (409 Conflict). Vui lòng chọn khung giờ khác.');
    }

    final rand = Random();
    final randomCode = 'SP-${100000 + rand.nextInt(899999)}';

    int courtPrice = request.slotIds.length * (request.subVenueId >= 4 ? 400000 : 100000);
    int servicesPrice = 0;
    for (var s in request.services) {
      servicesPrice += s.itemTotalPrice;
    }
    int totalPrice = courtPrice + servicesPrice;
    int depositAmount = request.depositPercentage >= 100 ? totalPrice : (totalPrice * 0.3).round();
    int remaining = totalPrice - depositAmount;

    final isSoccer = request.subVenueId >= 4;
    final venueName = isSoccer ? 'Sân Bóng Đá Mini PVV' : 'CLB Cầu Lông Cầu Giấy';
    final subVenueName = isSoccer ? 'Sân Cỏ ${request.subVenueId == 4 ? '7A' : '7B'}' : 'Sân Thảm ${request.subVenueId}';
    final sportName = isSoccer ? 'Bóng đá mini' : 'Cầu lông';

    return BookingResponseModel(
      bookingId: rand.nextInt(1000) + 1,
      bookingCode: randomCode,
      venueName: venueName,
      subVenueName: subVenueName,
      sportName: sportName,
      address: isSoccer
          ? 'Số 72 Trần Thái Tông, Dịch Vọng Hậu, Cầu Giấy, Hà Nội'
          : 'Số 35 Trần Quý Kiên, Dịch Vọng, Cầu Giấy, Hà Nội',
      playDate: DateFormat('yyyy-MM-dd').format(request.playDate),
      timeSlots: request.slotIds.map((id) => 'Slot #$id').toList(),
      courtPrice: courtPrice,
      servicesPrice: servicesPrice,
      totalPrice: totalPrice,
      depositAmount: depositAmount,
      remainingBalance: remaining,
      status: 'Upcoming',
      qrPayload: 'SPORTSPOT|$randomCode|10|Host|${rand.nextInt(999999)}',
      isCheckedIn: false,
    );
  }
}
