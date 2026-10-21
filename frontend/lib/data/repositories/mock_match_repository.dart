import '../models/match_model.dart';
import 'match_repository.dart';

/// In-memory fixture for UI development and tests. No calls to API, no real payment.
class MockMatchRepository implements MatchRepository {
  final int actorId;
  final bool isStaff;
  final Map<String, dynamic> _match;
  MockMatchRepository({this.actorId = 2, this.isStaff = false})
    : _match = {
        'matchId': 1,
        'bookingId': 1,
        'bookingCode': 'SP-DEMO01',
        'hostUserId': 1,
        'hostName': 'Host demo',
        'venueName': 'Sân thể thao demo',
        'subVenueName': 'Sân 1',
        'sportId': 1,
        'sportName': 'Cầu lông',
        'district': 'Thủ Đức',
        'address': 'Thủ Đức, TP.HCM',
        'playDate': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String()
            .split('T')
            .first,
        'timeSlots': ['18:00-20:00'],
        'neededPlayers': 4,
        'totalExpectedPlayers': 10,
        'currentJoinedPlayers': 0,
        'costPerPerson': 60000,
        'remainingBalanceForHost': 420000,
        'status': 'Open',
        'skillLevel': 'Cơ bản',
        'members': <Map<String, dynamic>>[],
      };
  final List<int> _membersWithTicket = [];
  void _requireId(int id) {
    if (id != 1) throw StateError('Không tìm thấy kèo demo');
  }

  void _add(int? userId) {
    if (_match['status'] != 'Open') throw StateError('Kèo đã đóng');
    if (userId == 1 || (userId != null && _membersWithTicket.contains(userId))) {
      throw StateError('Đã tham gia');
    }
    final members = _match['members'] as List;
    members.add({
      'memberId': members.length + 1,
      'userId': userId,
      'name': userId == null ? 'Khách tại quầy' : 'Người chơi demo',
      'memberType': userId == null ? 'WalkInAtDesk' : 'AppUser',
    });
    if (userId != null) _membersWithTicket.add(userId);
    _match['currentJoinedPlayers']++;
    _match['remainingBalanceForHost'] -= 60000;
    if (_match['currentJoinedPlayers'] == 4) _match['status'] = 'Full';
  }

  @override
  Future<List<OpenMatch>> list({
    int? sportId,
    String? district,
    bool staff = false,
  }) async {
    if (staff && !isStaff) throw StateError('Chỉ dành cho lễ tân');
    if (_match['status'] != 'Open' ||
        (sportId != null && sportId != 1) ||
        (district != null &&
            !'thủ đức'.contains(district.trim().toLowerCase()))) {
      return [];
    }
    return [OpenMatch(_match)];
  }

  @override
  Future<OpenMatch> detail(int id) async {
    _requireId(id);
    return OpenMatch(_match);
  }

  @override
  Future<void> join(int id) async {
    _requireId(id);
    _add(actorId);
  }

  @override
  Future<void> assign(int id) async {
    _requireId(id);
    if (!isStaff) throw StateError('Chỉ dành cho lễ tân');
    _add(null);
  }

  @override
  Future<void> stop(int id) async {
    _requireId(id);
    if (actorId != 1) throw StateError('Chỉ dành cho Host');
    _match['status'] = 'Stopped';
  }

  @override
  Future<void> leave(int id) async {
    _requireId(id);
    if (!_membersWithTicket.remove(actorId)) throw StateError('Chưa tham gia');
    (_match['members'] as List).removeWhere((m) => m['userId'] == actorId);
    _match['currentJoinedPlayers']--;
    _match['remainingBalanceForHost'] += 60000;
    if (_match['status'] == 'Full') _match['status'] = 'Open';
  }

  @override
  Future<String> ticket(int id) async {
    _requireId(id);
    if (!_membersWithTicket.contains(actorId)) throw StateError('Chưa có vé');
    return 'SPORTSPOT|SP-DEMO01|$actorId|JoinedPlayer|DEMO';
  }
}
