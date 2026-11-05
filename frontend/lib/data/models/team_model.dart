class FootballTeam {
  final int id, captainUserId, teamSize;
  final String name, captainName, skillLevel;
  FootballTeam.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      captainUserId = j['captainUserId'],
      teamSize = j['teamSize'],
      name = j['name'],
      captainName = j['captainName'],
      skillLevel = j['skillLevel'];
}

class TeamApplication {
  final int id;
  final FootballTeam team;
  final String message, status;
  TeamApplication.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      team = FootballTeam.fromJson(j['team']),
      message = j['message'],
      status = j['status'];
}

class TeamChallenge {
  final int id, bookingId, opponentCourtShare;
  final FootballTeam team;
  final String venueName, subVenueName, district, playDate, note, status;
  final String? contactPhone;
  final bool isHost;
  final List<String> timeSlots;
  final List<TeamApplication> requests;
  TeamChallenge.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      bookingId = j['bookingId'],
      opponentCourtShare = j['opponentCourtShare'],
      team = FootballTeam.fromJson(j['team']),
      venueName = j['venueName'],
      subVenueName = j['subVenueName'],
      district = j['district'],
      playDate = j['playDate'],
      note = j['note'],
      status = j['status'],
      isHost = j['isHost'],
      contactPhone = j['contactPhone'],
      timeSlots = List<String>.from(j['timeSlots']),
      requests = (j['requests'] as List)
          .map((r) => TeamApplication.fromJson(r))
          .toList();
}
