import '../../core/network/api_client.dart';
import '../models/match_model.dart';

abstract class MatchRepository {
  Future<String> ticket(int id);
  Future<List<OpenMatch>> list({
    int? sportId,
    String? district,
    bool staff = false,
  });
  Future<OpenMatch> detail(int id);
  Future<void> join(int id);
  Future<void> assign(int id);
  Future<void> stop(int id);
  Future<void> leave(int id);
}

class ApiMatchRepository implements MatchRepository {
  @override
  Future<String> ticket(int id) async {
    final data = await client.get('/api/matches/$id/my-ticket');
    return data['ticketQrPayload'] as String;
  }

  final ApiClient client;
  ApiMatchRepository({ApiClient? client}) : client = client ?? ApiClient();
  @override
  Future<List<OpenMatch>> list({
    int? sportId,
    String? district,
    bool staff = false,
  }) async {
    final query = Uri(
      queryParameters: {
        if (sportId != null) 'sportId': '$sportId',
        if (district != null && district.trim().isNotEmpty)
          'district': district.trim(),
      },
    ).query;
    final data = await client.get(
      '/api/matches${staff ? '/staff' : ''}?$query',
    );
    return (data as List).map((m) => OpenMatch(m)).toList();
  }

  @override
  Future<OpenMatch> detail(int id) async =>
      OpenMatch(await client.get('/api/matches/$id'));
  @override
  Future<void> join(int id) async {
    await client.post('/api/matches/$id/join', {
      'paymentGateway': 'MockPayment',
    });
  }

  @override
  Future<void> assign(int id) async {
    await client.post('/api/matches/$id/assign-walk-in', {});
  }

  @override
  Future<void> stop(int id) async {
    await client.put('/api/matches/$id/stop-recruiting', {});
  }

  @override
  Future<void> leave(int id) async {
    await client.post('/api/matches/$id/leave', {});
  }
}
