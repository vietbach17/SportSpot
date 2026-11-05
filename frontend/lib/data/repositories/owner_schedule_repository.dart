import '../../core/network/api_client.dart';
import '../models/owner_schedule_model.dart';

class OwnerScheduleRepository {
  final ApiClient client;
  OwnerScheduleRepository({ApiClient? client}) : client = client ?? ApiClient();
  Future<List<ManagedVenue>> venues() async =>
      ((await client.get('/api/owner/venues')) as List)
          .map((j) => ManagedVenue.fromJson(j))
          .toList();
  Future<OwnerSchedule> schedule(int venueId, String from, String to) async =>
      OwnerSchedule.fromJson(
        await client.get(
          '/api/owner/schedule?venueId=$venueId&from=$from&to=$to',
        ),
      );
  Future<void> create(Map<String, dynamic> body) async =>
      client.post('/api/owner/bookings', body);
  Future<void> complete(int id) async =>
      client.post('/api/owner/bookings/$id/complete', {});
  Future<void> cancel(int id, bool refund) async => client.post(
    '/api/owner/bookings/$id/cancel',
    {'confirmCashRefund': refund},
  );
  Future<void> collect(int id, int amount) async =>
      client.post('/api/owner/bookings/$id/collect', {'amount': amount});
  Future<void> prices(int id, int base, int peak) async => client.put(
    '/api/owner/venues/$id/prices',
    {'basePrice': base, 'peakPrice': peak},
  );
  Future<void> toggle(int id, bool active) async => client.put(
    '/api/owner/subvenues/$id/toggle-status',
    {'isActive': active},
  );
}
