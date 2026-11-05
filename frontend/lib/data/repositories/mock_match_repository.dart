import '../models/match_model.dart';
import 'match_repository.dart';
import 'mock_ticket_repository.dart';

/// In-memory fixture for UI development and tests. No calls to API, no real payment.
class MockMatchRepository implements MatchRepository {
  final int actorId;
  final bool isStaff;
  final bool includeExtraDevMatches;
  final Map<String, dynamic> _match;
  final List<Map<String, dynamic>> _extraMatches;
  final List<int> _membersWithTicket = [];

  MockMatchRepository({
    this.actorId = 2,
    this.isStaff = false,
    this.includeExtraDevMatches = false,
  })  : _match = {
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
        },
        _extraMatches = [
          {
            'matchId': 2,
            'bookingId': 2,
            'bookingCode': 'SP-MATCH-02',
            'hostUserId': 3,
            'hostName': 'Hoàng Nam (Host)',
            'hostAvatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
            'venueId': 3,
            'venueName': 'CLB Pickleball D-Sports Thủ Đức',
            'subVenueName': 'Sân P1 (Mái che USAPA)',
            'sportId': 2,
            'sportName': 'Pickleball',
            'district': 'Thủ Đức',
            'address': 'Số 18 đường Song Hành, An Phú, TP. Thủ Đức',
            'playDate': DateTime.now().toIso8601String().split('T').first,
            'timeSlots': ['10:00-11:00', '11:00-12:00'],
            'neededPlayers': 4,
            'totalExpectedPlayers': 4,
            'currentJoinedPlayers': 2,
            'costPerPerson': 50000,
            'remainingBalanceForHost': 100000,
            'status': 'Open',
            'skillLevel': 'Cơ bản (2.5 - 3.0)',
            'title': 'Kèo Đôi Pickleball D-Sports Tìm 2 Tay Vợt',
            'hostNote': 'Kèo giao lưu nhẹ nhàng buổi sáng, có bóng Franklin X-40 sẵn.',
            'hostPhone': '0934567890',
            'venueImageUrl': 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200&q=80',
            'members': <Map<String, dynamic>>[
              {'memberId': 1, 'userId': 3, 'name': 'Hoàng Nam', 'memberType': 'Host'},
              {'memberId': 2, 'userId': 6, 'name': 'Thanh Tùng', 'memberType': 'AppUser'},
            ],
          },
          {
            'matchId': 3,
            'bookingId': 3,
            'bookingCode': 'SP-MATCH-03',
            'hostUserId': 4,
            'hostName': 'Ngọc Linh (Host)',
            'hostAvatarUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80',
            'venueId': 1,
            'venueName': 'CLB Cầu Lông Kỳ Hòa',
            'subVenueName': 'Sân Thảm 2 (Yonex Pro)',
            'sportId': 1,
            'sportName': 'Cầu lông',
            'district': 'Quận 10',
            'address': 'Số 238 đường 3/2, Phường 12, Quận 10',
            'playDate': DateTime.now().toIso8601String().split('T').first,
            'timeSlots': ['18:00-19:00', '19:00-20:00'],
            'neededPlayers': 4,
            'totalExpectedPlayers': 8,
            'currentJoinedPlayers': 3,
            'costPerPerson': 60000,
            'remainingBalanceForHost': 60000,
            'status': 'Open',
            'skillLevel': 'Trung bình khá (B+)',
            'title': 'Tuyển 1 Slot Đôi Nam Nữ Giao Lưu Kỳ Hòa',
            'hostNote': 'Anh em đến trước 10 phút khởi động nhé. Cầu thi đấu Hải Yến đỏ.',
            'hostPhone': '0903123456',
            'venueImageUrl': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200&q=80',
            'members': <Map<String, dynamic>>[
              {'memberId': 1, 'userId': 4, 'name': 'Ngọc Linh', 'memberType': 'Host'},
              {'memberId': 2, 'userId': 7, 'name': 'Văn Toàn', 'memberType': 'AppUser'},
              {'memberId': 3, 'userId': 8, 'name': 'Minh Đức', 'memberType': 'AppUser'},
            ],
          },
        ];

  Map<String, dynamic> _getMatch(int id) {
    if (id == 1) return _match;
    return _extraMatches.firstWhere((m) => m['matchId'] == id, orElse: () => _match);
  }

  void _add(int id, int? userId, {String name = 'Khách vãng lai'}) {
    final m = _getMatch(id);
    if (m['status'] != 'Open') throw StateError('Kèo đã đóng');
    if (userId == 1 || (userId != null && _membersWithTicket.contains(userId))) {
      throw StateError('Đã tham gia');
    }
    final members = m['members'] as List;
    members.add({
      'memberId': members.length + 1,
      'userId': userId,
      'name': userId == null ? name : 'Người chơi demo',
      'memberType': userId == null ? 'WalkInAtDesk' : 'AppUser',
    });
    if (userId != null) _membersWithTicket.add(userId);
    m['currentJoinedPlayers'] = (m['currentJoinedPlayers'] as int) + 1;
    final cost = (m['costPerPerson'] as int?) ?? 60000;
    m['remainingBalanceForHost'] = ((m['remainingBalanceForHost'] as int?) ?? 0) - cost;
    if (m['currentJoinedPlayers'] >= m['neededPlayers']) m['status'] = 'Full';
  }

  @override
  Future<List<OpenMatch>> list({
    int? sportId,
    String? district,
    bool staff = false,
  }) async {
    if (staff && !isStaff) throw StateError('Chỉ dành cho lễ tân');
    final all = <Map<String, dynamic>>[_match];
    if (includeExtraDevMatches) {
      all.addAll(_extraMatches);
    }
    return all.where((m) {
      if (m['status'] != 'Open') return false;
      if (sportId != null && m['sportId'] != sportId) return false;
      if (district != null && district.trim().isNotEmpty) {
        final d = (m['district'] as String).toLowerCase();
        if (!d.contains(district.trim().toLowerCase())) return false;
      }
      return true;
    }).map((m) => OpenMatch(m)).toList();
  }

  @override
  Future<OpenMatch> detail(int id) async {
    return OpenMatch(_getMatch(id));
  }

  @override
  Future<String> ticket(int id) async {
    final m = _getMatch(id);
    final bookingCode = m['bookingCode']?.toString() ?? 'SP-DEMO01';
    return MockTicketRepository.buildSignedQrPayload(bookingCode, actorId, 'JoinedPlayer');
  }

  @override
  Future<void> join(int id, {String gateway = 'PayOS'}) async {
    _add(id, actorId);
  }

  @override
  Future<void> guestJoin(int id, {String name = 'Khách vãng lai', String phone = '', String gateway = 'PayOS'}) async {
    _add(id, null, name: name);
  }

  @override
  Future<void> assign(int id) async {
    if (!isStaff) throw StateError('Chỉ dành cho lễ tân');
    _add(id, null, name: 'Khách tại quầy');
  }

  @override
  Future<void> stop(int id) async {
    if (actorId != 1) throw StateError('Chỉ dành cho Host');
    _getMatch(id)['status'] = 'Stopped';
  }

  @override
  Future<void> leave(int id) async {
    final m = _getMatch(id);
    final members = m['members'] as List;
    members.removeWhere((item) => item['userId'] == actorId);
    _membersWithTicket.remove(actorId);
    if ((m['currentJoinedPlayers'] as int) > 0) {
      m['currentJoinedPlayers'] = (m['currentJoinedPlayers'] as int) - 1;
      final cost = (m['costPerPerson'] as int?) ?? 60000;
      m['remainingBalanceForHost'] = ((m['remainingBalanceForHost'] as int?) ?? 0) + cost;
    }
  }
}
