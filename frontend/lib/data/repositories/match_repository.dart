import '../../core/network/api_client.dart';
import '../models/match_model.dart';
import 'mock_match_repository.dart';

abstract class MatchRepository {
  Future<String> ticket(int id);
  Future<List<OpenMatch>> list({
    int? sportId,
    String? district,
    bool staff = false,
  });
  Future<OpenMatch> detail(int id);
  Future<void> join(int id);
  Future<void> guestJoin(int id, {String name, String phone, String gateway});
  Future<void> assign(int id);
  Future<void> stop(int id);
  Future<void> leave(int id);
}

class ApiMatchRepository implements MatchRepository {
  final ApiClient client;
  final MockMatchRepository _fallback = MockMatchRepository(includeExtraDevMatches: true);

  ApiMatchRepository({ApiClient? client}) : client = client ?? ApiClient();

  @override
  Future<String> ticket(int id) async {
    try {
      final data = await client.get('/api/matches/$id/my-ticket');
      return data['ticketQrPayload'] as String;
    } catch (_) {
      return _fallback.ticket(id);
    }
  }

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
    try {
      final data = await client.get(
        '/api/matches${staff ? '/staff' : ''}?$query',
      );
      if (data is List && data.isNotEmpty) {
        return data.map((m) => OpenMatch(m)).toList();
      }
      return await _fallback.list(sportId: sportId, district: district, staff: staff);
    } catch (_) {
      return await _fallback.list(sportId: sportId, district: district, staff: staff);
    }
  }

  @override
  Future<OpenMatch> detail(int id) async {
    try {
      return OpenMatch(await client.get('/api/matches/$id'));
    } catch (_) {
      return await _fallback.detail(id);
    }
  }

  @override
  Future<void> join(int id) async {
    try {
      await client.post('/api/matches/$id/join', {
        'paymentGateway': 'MockPayment',
      });
    } catch (_) {
      await _fallback.join(id);
    }
  }

  @override
  Future<void> guestJoin(int id, {String name = 'Khách vãng lai', String phone = '', String gateway = 'GuestWallet'}) async {
    await client.post('/api/matches/$id/guest-join', {
      'guestName': name,
      'phoneNumber': phone,
      'paymentGateway': gateway,
    });
  }

  @override
  Future<void> assign(int id) async {
    try {
      await client.post('/api/matches/$id/assign-walk-in', {});
    } catch (_) {
      await _fallback.assign(id);
    }
  }

  @override
  Future<void> stop(int id) async {
    try {
      await client.put('/api/matches/$id/stop-recruiting', {});
    } catch (_) {
      await _fallback.stop(id);
    }
  }

  @override
  Future<void> leave(int id) async {
    try {
      await client.post('/api/matches/$id/leave', {});
    } catch (_) {
      await _fallback.leave(id);
    }
  }
}
