import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../models/booking_model.dart';
import 'booking_repository.dart';
import 'mock_booking_repository.dart';

class RemoteBookingRepository implements BookingRepository {
  final ApiClient _apiClient = ApiClient();
  final MockBookingRepository _mockFallback = MockBookingRepository();

  @override
  Future<List<TimeSlotModel>> getSlots(int venueId, int subVenueId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final endpoint = '/api/venues/$venueId/subvenues/$subVenueId/slots?date=$dateStr';
      final dynamic response = await _apiClient.get(endpoint, requiresAuth: false);

      if (response is List) {
        return response.map((item) => TimeSlotModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return await _mockFallback.getSlots(venueId, subVenueId, date);
    } catch (e) {
      debugPrint('[RemoteBookingRepository] getSlots error -> Fallback to Mock: $e');
      return await _mockFallback.getSlots(venueId, subVenueId, date);
    }
  }

  @override
  Future<List<ServiceItemModel>> getServices(int venueId) async {
    try {
      final endpoint = '/api/venues/$venueId';
      final dynamic response = await _apiClient.get(endpoint, requiresAuth: false);

      if (response is Map<String, dynamic> && response['services'] is List) {
        final List<dynamic> servicesJson = response['services'];
        return servicesJson.map((item) => ServiceItemModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return await _mockFallback.getServices(venueId);
    } catch (e) {
      debugPrint('[RemoteBookingRepository] getServices error -> Fallback to Mock: $e');
      return await _mockFallback.getServices(venueId);
    }
  }

  @override
  Future<BookingResponseModel> createBooking(BookingRequestModel request) async {
    try {
      final dynamic response = await _apiClient.post(
        '/api/bookings',
        request.toJson(),
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        return BookingResponseModel.fromJson(response);
      }
      return await _mockFallback.createBooking(request);
    } catch (e) {
      final msg = e.toString();
      // Nếu là lỗi 409 Conflict, ném tiếp ra ngoài để UI bắt được và cảnh báo
      if (msg.contains('409') || msg.toLowerCase().contains('vừa có người khác đặt')) {
        rethrow;
      }
      debugPrint('[RemoteBookingRepository] createBooking network error -> Fallback Mock: $e');
      return await _mockFallback.createBooking(request);
    }
  }
}
