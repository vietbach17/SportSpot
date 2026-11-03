class MatchMember {
  final int? userId;
  final String name, type;
  final String? avatarUrl;
  MatchMember(Map<String, dynamic> json)
    : userId = json['userId'],
      name = json['name'] ?? '',
      type = json['memberType'] ?? '',
      avatarUrl = json['avatarUrl'];
}

class OpenMatch {
  final int id, hostId, needed, joined, cost, balance, sportId, venueId;
  final String title,
      venue,
      court,
      sport,
      district,
      address,
      date,
      host,
      status,
      skill,
      venueImageUrl;
  final String? hostNote, hostPhone, hostAvatarUrl, amenities;
  final double? latitude, longitude, distanceKm;
  final List<String> slots;
  final List<MatchMember> members;

  OpenMatch(Map<String, dynamic> json)
    : id = json['matchId'] ?? 0,
      hostId = json['hostUserId'] ?? 0,
      venueId = json['venueId'] ?? 0,
      needed = json['neededPlayers'] ?? 0,
      joined = json['currentJoinedPlayers'] ?? 0,
      cost = json['costPerPerson'] ?? 0,
      balance = json['remainingBalanceForHost'] ?? 0,
      sportId = json['sportId'] ?? 1,
      title = (json['title'] != null && json['title'].toString().isNotEmpty)
          ? json['title'].toString()
          : '${json['sportName'] ?? 'Kèo'} giao lưu @ ${json['venueName'] ?? 'Sân'}',
      venue = json['venueName'] ?? '',
      court = json['subVenueName'] ?? '',
      sport = json['sportName'] ?? '',
      district = json['district'] ?? '',
      address = json['address'] ?? '',
      date = json['playDate']?.toString() ?? '',
      host = json['hostName'] ?? 'Host',
      status = json['status'] ?? 'Open',
      skill = json['skillLevel'] ?? 'Cơ bản',
      venueImageUrl = (json['venueImageUrl'] != null && json['venueImageUrl'].toString().isNotEmpty)
          ? json['venueImageUrl'].toString()
          : _fallbackSportImage(json['sportId']),
      latitude = (json['latitude'] as num?)?.toDouble() ?? 10.7725,
      longitude = (json['longitude'] as num?)?.toDouble() ?? 106.6710,
      distanceKm = (json['distanceKm'] as num?)?.toDouble() ?? 1.8,
      hostNote = json['hostNote']?.toString(),
      hostPhone = json['hostPhone']?.toString() ?? '0903123456',
      hostAvatarUrl = (json['hostAvatarUrl'] != null && json['hostAvatarUrl'].toString().isNotEmpty)
          ? json['hostAvatarUrl'].toString()
          : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&q=80',
      amenities = json['amenities']?.toString(),
      slots = List<String>.from(json['timeSlots'] ?? []),
      members = (json['members'] as List? ?? [])
          .map((m) => MatchMember(m as Map<String, dynamic>))
          .toList();

  int get remaining => needed - joined;

  List<String> get amenityList {
    if (amenities == null || amenities!.trim().isEmpty) {
      return const ['Wifi miễn phí', 'Bãi đỗ xe', 'Căng tin / Nước giải khát', 'Tắm nóng lạnh'];
    }
    return amenities!
        .split(RegExp(r'[,;•|]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String _fallbackSportImage(dynamic sportId) {
    final id = (sportId as num?)?.toInt() ?? 1;
    switch (id) {
      case 2:
        return 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200&q=80';
      case 3:
        return 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=1200&q=80';
      case 4:
        return 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200&q=80';
      case 1:
      default:
        return 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200&q=80';
    }
  }
}
