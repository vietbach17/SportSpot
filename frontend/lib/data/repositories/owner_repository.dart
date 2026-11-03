import '../../core/network/api_client.dart';
import '../models/owner_dashboard_model.dart';

abstract class IOwnerRepository {
  Future<OwnerDashboardModel> getDashboard({int? venueId});
  Future<bool> toggleSubVenueStatus(int subVenueId, {bool? isActive});
}

class MockOwnerRepository implements IOwnerRepository {
  final Map<int, bool> _subVenueStates = {1: true, 2: true, 3: false};

  @override
  Future<OwnerDashboardModel> getDashboard({int? venueId}) async {
    
    final subVenues = [
      SubVenueManagementModel(
        id: 1,
        name: 'Sân Thảm 1 (Chính)',
        isActive: _subVenueStates[1] ?? true,
        totalSlotsToday: 13,
        bookedSlotsToday: 9,
      ),
      SubVenueManagementModel(
        id: 2,
        name: 'Sân Thảm 2 (VIP)',
        isActive: _subVenueStates[2] ?? true,
        totalSlotsToday: 13,
        bookedSlotsToday: 7,
      ),
      SubVenueManagementModel(
        id: 3,
        name: 'Sân Thảm 3 (Bảo trì)',
        isActive: _subVenueStates[3] ?? false,
        totalSlotsToday: 13,
        bookedSlotsToday: 0,
      ),
    ];

    return OwnerDashboardModel(
      venueId: venueId ?? 1,
      venueName: 'CLB Cầu Lông Kỳ Hòa',
      venueAddress: '238 đường 3 Tháng 2, Phường 12, Quận 10',
      sportName: 'Cầu lông',
      totalBookings: 42,
      totalRevenue: 6850000,
      escrowHoldingAmount: 1250000,
      occupancyRatePercentage: 62,
      activeSubVenuesCount: subVenues.where((s) => s.isActive).length,
      totalSubVenuesCount: subVenues.length,
      dailyRevenues: [
        const DailyRevenueModel(date: '28/10', dayOfWeek: 'T2', revenue: 750000, bookingCount: 5),
        const DailyRevenueModel(date: '29/10', dayOfWeek: 'T3', revenue: 920000, bookingCount: 6),
        const DailyRevenueModel(date: '30/10', dayOfWeek: 'T4', revenue: 840000, bookingCount: 5),
        const DailyRevenueModel(date: '31/10', dayOfWeek: 'T5', revenue: 1100000, bookingCount: 7),
        const DailyRevenueModel(date: '01/11', dayOfWeek: 'T6', revenue: 1450000, bookingCount: 9),
        const DailyRevenueModel(date: '02/11', dayOfWeek: 'T7', revenue: 1800000, bookingCount: 11),
        const DailyRevenueModel(date: '03/11', dayOfWeek: 'CN', revenue: 1650000, bookingCount: 10),
      ],
      recentBookings: [
        OwnerBookingModel(
          bookingId: 101,
          bookingCode: 'SP-782194',
          customerName: 'Nguyễn Văn Minh',
          customerPhone: '0901234567',
          subVenueName: 'Sân Thảm 1',
          playDate: '2026-11-03',
          timeSlots: const ['18:00-19:00', '19:00-20:00'],
          totalPrice: 240000,
          depositAmount: 72000,
          status: 'Upcoming',
          escrowStatus: 'Holding',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        OwnerBookingModel(
          bookingId: 102,
          bookingCode: 'SP-654321',
          customerName: 'Trần Thu Trang',
          customerPhone: '0912345678',
          subVenueName: 'Sân Thảm 2',
          playDate: '2026-11-03',
          timeSlots: const ['17:00-18:00'],
          totalPrice: 120000,
          depositAmount: 36000,
          status: 'Completed',
          escrowStatus: 'Settled',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        OwnerBookingModel(
          bookingId: 103,
          bookingCode: 'SP-112233',
          customerName: 'Lê Hoàng Nam',
          customerPhone: '0988776655',
          subVenueName: 'Sân Thảm 1',
          playDate: '2026-11-03',
          timeSlots: const ['08:00-09:00'],
          totalPrice: 90000,
          depositAmount: 27000,
          status: 'Cancelled',
          escrowStatus: 'Refunded',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
      ],
      subVenues: subVenues,
    );
  }

  @override
  Future<bool> toggleSubVenueStatus(int subVenueId, {bool? isActive}) async {
    
    final current = _subVenueStates[subVenueId] ?? true;
    final next = isActive ?? !current;
    _subVenueStates[subVenueId] = next;
    return next;
  }
}

class ApiOwnerRepository implements IOwnerRepository {
  final ApiClient _client;
  final MockOwnerRepository _fallback = MockOwnerRepository();

  ApiOwnerRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<OwnerDashboardModel> getDashboard({int? venueId}) async {
    try {
      final vid = venueId ?? 1;
      final response = await _client.get('/api/owner/dashboard?venueId=$vid', requiresAuth: false);
      if (response is Map<String, dynamic>) {
        return OwnerDashboardModel.fromJson(response);
      }
      return await _fallback.getDashboard(venueId: venueId);
    } catch (_) {
      return await _fallback.getDashboard(venueId: venueId);
    }
  }

  @override
  Future<bool> toggleSubVenueStatus(int subVenueId, {bool? isActive}) async {
    try {
      final payload = <String, dynamic>{};
      if (isActive != null) payload['isActive'] = isActive;
      final response = await _client.put('/api/owner/subvenues/$subVenueId/toggle-status', payload);
      if (response is bool) return response;
      if (response is Map<String, dynamic> && response['data'] is bool) {
        return response['data'] as bool;
      }
      return await _fallback.toggleSubVenueStatus(subVenueId, isActive: isActive);
    } catch (_) {
      return await _fallback.toggleSubVenueStatus(subVenueId, isActive: isActive);
    }
  }
}
