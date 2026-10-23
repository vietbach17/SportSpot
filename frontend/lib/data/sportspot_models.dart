class CourtInfo {
  final String id;
  final String name;
  final String surface;
  final String type;
  final String tag;

  const CourtInfo({
    required this.id,
    required this.name,
    required this.surface,
    required this.type,
    required this.tag,
  });
}

class VenueAmenity {
  final String label;
  final String icon;

  const VenueAmenity({required this.label, required this.icon});
}

class SportSpotVenue {
  final String id;
  final String name;
  final String address;
  final String distance;
  final double rating;
  final int reviewCount;
  final int priceFrom;
  final String openUntil;
  final int totalCourts;
  final bool isVerified;
  final String image;
  final List<String> disciplines;
  final List<VenueAmenity> amenities;
  final int slotsAvailableToday;
  final List<CourtInfo> courts;

  const SportSpotVenue({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.priceFrom,
    required this.openUntil,
    required this.totalCourts,
    required this.isVerified,
    required this.image,
    required this.disciplines,
    required this.amenities,
    required this.slotsAvailableToday,
    required this.courts,
  });
}

class TimeSlotItem {
  final int id;
  final String time;
  final int price;
  final String label;
  final bool isBooked;
  final bool isPrime;

  const TimeSlotItem({
    required this.id,
    required this.time,
    required this.price,
    required this.label,
    this.isBooked = false,
    this.isPrime = false,
  });
}

class SquadPlayerItem {
  final String id;
  final String name;
  final String? avatar;
  final bool isYou;
  final bool hasPaid;

  const SquadPlayerItem({
    required this.id,
    required this.name,
    this.avatar,
    this.isYou = false,
    this.hasPaid = false,
  });
}

class SportSpotMatch {
  final String id;
  final String sport;
  final String title;
  final String venueName;
  final String courtDetails;
  final String timeDisplay;
  final int spotsTotal;
  final int spotsTaken;
  final int spotsNeeded;
  final String hostName;
  final String hostRank;
  final String hostAvatar;
  final String image;
  final int splitPrice;
  final int splitMultiplier;
  final String level;
  final bool isJoined;
  final List<SquadPlayerItem> players;

  const SportSpotMatch({
    required this.id,
    required this.sport,
    required this.title,
    required this.venueName,
    required this.courtDetails,
    required this.timeDisplay,
    required this.spotsTotal,
    required this.spotsTaken,
    required this.spotsNeeded,
    required this.hostName,
    required this.hostRank,
    required this.hostAvatar,
    required this.image,
    required this.splitPrice,
    required this.splitMultiplier,
    required this.level,
    this.isJoined = false,
    required this.players,
  });

  SportSpotMatch copyWith({
    bool? isJoined,
    int? spotsTaken,
    int? spotsNeeded,
    List<SquadPlayerItem>? players,
  }) {
    return SportSpotMatch(
      id: id,
      sport: sport,
      title: title,
      venueName: venueName,
      courtDetails: courtDetails,
      timeDisplay: timeDisplay,
      spotsTotal: spotsTotal,
      spotsTaken: spotsTaken ?? this.spotsTaken,
      spotsNeeded: spotsNeeded ?? this.spotsNeeded,
      hostName: hostName,
      hostRank: hostRank,
      hostAvatar: hostAvatar,
      image: image,
      splitPrice: splitPrice,
      splitMultiplier: splitMultiplier,
      level: level,
      isJoined: isJoined ?? this.isJoined,
      players: players ?? this.players,
    );
  }
}

class SportSpotPass {
  final String id;
  final String passCode;
  final String venueName;
  final String courtName;
  final String sport;
  final String date;
  final String timeSlot;
  final int totalAmount;
  final int perPersonAmount;
  final bool isSplitEnabled;
  final String status;
  final String gateCode;
  final String address;
  final List<SquadPlayerItem> players;

  const SportSpotPass({
    required this.id,
    required this.passCode,
    required this.venueName,
    required this.courtName,
    required this.sport,
    required this.date,
    required this.timeSlot,
    required this.totalAmount,
    required this.perPersonAmount,
    required this.isSplitEnabled,
    required this.status,
    required this.gateCode,
    required this.address,
    required this.players,
  });
}
