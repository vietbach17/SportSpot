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
  final int id, hostId, needed, joined, cost, balance, sportId;
  final String venue,
      court,
      sport,
      district,
      address,
      date,
      host,
      status,
      skill;
  final List<String> slots;
  final List<MatchMember> members;
  OpenMatch(Map<String, dynamic> json)
    : id = json['matchId'],
      hostId = json['hostUserId'],
      needed = json['neededPlayers'],
      joined = json['currentJoinedPlayers'],
      cost = json['costPerPerson'],
      balance = json['remainingBalanceForHost'],
      sportId = json['sportId'],
      venue = json['venueName'],
      court = json['subVenueName'],
      sport = json['sportName'],
      district = json['district'],
      address = json['address'],
      date = json['playDate'],
      host = json['hostName'],
      status = json['status'],
      skill = json['skillLevel'],
      slots = List<String>.from(json['timeSlots'] ?? []),
      members = (json['members'] as List? ?? [])
          .map((m) => MatchMember(m))
          .toList();
  int get remaining => needed - joined;
}
