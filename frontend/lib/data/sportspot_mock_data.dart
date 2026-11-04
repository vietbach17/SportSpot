import 'sportspot_models.dart';

class SportSpotMockData {
  static const String logo =
      'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&q=80';
  static const String userNam =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&q=80';
  static const String heroBanner =
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1600&q=85';
  static const String cauGiayVenue =
      'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200&q=80';
  static const String cauGiayDetailHero =
      'https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=1200&q=80';
  static const String onboardingAthlete =
      'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=1200&q=85';
  static const String coachMinh =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80';

  static const String matchBadminton =
      'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200&q=80';
  static const String matchPickleball =
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200&q=80';
  static const String matchFootball =
      'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=1200&q=80';

  static const String friend1 =
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80';
  static const String friend2 =
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80';
  static const String friend3 =
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80';

  static final List<SportSpotVenue> venues = [
    const SportSpotVenue(
      id: 'cau-giay-pro-arena',
      name: 'Cau Giay Pro Arena & Sports Hub',
      address: '180 Xuân Thủy, Cầu Giấy, Hà Nội',
      distance: '1.2 km away',
      rating: 4.9,
      reviewCount: 128,
      priceFrom: 90000,
      openUntil: '23:00',
      totalCourts: 6,
      isVerified: true,
      image: cauGiayVenue,
      disciplines: ['badminton', 'pickleball'],
      amenities: [
        VenueAmenity(label: 'Free Parking', icon: 'local_parking'),
        VenueAmenity(label: 'Rackets for Rent', icon: 'sports_tennis'),
        VenueAmenity(label: 'Hot Showers', icon: 'shower'),
        VenueAmenity(label: 'AC Indoor', icon: 'ac_unit'),
      ],
      slotsAvailableToday: 8,
      courts: [
        CourtInfo(
            id: 'c1',
            name: 'Sân 1',
            surface: 'Wood Pro',
            type: 'Premium Maple Wood',
            tag: 'BWF Level 2 Certified'),
        CourtInfo(
            id: 'c2',
            name: 'Sân 2',
            surface: 'Vinyl Pro',
            type: 'Pro PVC Cushioned',
            tag: 'High Grip Shock-Absorb'),
        CourtInfo(
            id: 'c3',
            name: 'Sân 3',
            surface: 'Taraflex',
            type: 'Taraflex Olympic',
            tag: 'Official Tournament Spec'),
      ],
    ),
  ];

  static const List<TimeSlotItem> timeSlots = [
    TimeSlotItem(id: 1, time: '16:00 - 17:00', price: 90000, label: 'Tiêu chuẩn'),
    TimeSlotItem(id: 2, time: '17:00 - 18:00', price: 90000, label: 'Tiêu chuẩn'),
    TimeSlotItem(
        id: 3,
        time: '18:00 - 19:00',
        price: 120000,
        label: '★ Giờ Vàng (Prime)',
        isPrime: true),
    TimeSlotItem(
        id: 4,
        time: '19:00 - 20:00',
        price: 120000,
        label: '★ Giờ Vàng (Prime)',
        isPrime: true),
    TimeSlotItem(
        id: 5,
        time: '20:00 - 21:00',
        price: 110000,
        label: 'Đã có trận',
        isBooked: true),
    TimeSlotItem(id: 6, time: '21:00 - 22:00', price: 100000, label: 'Khung giờ muộn'),
  ];

  static final List<SportSpotMatch> openMatches = [
    const SportSpotMatch(
      id: 'match-1',
      sport: 'badminton',
      title: 'Badminton Doubles (Đôi Nam Nữ)',
      venueName: 'Cụm sân Cầu Giấy Pro Arena',
      courtDetails: 'Sân 2 • Sàn Gỗ Thi Đấu Trong Nhà',
      timeDisplay: '18:30 - 20:30',
      spotsTotal: 4,
      spotsTaken: 2,
      spotsNeeded: 2,
      hostName: 'Minh Trí',
      hostRank: 'Host • Rank B+',
      hostAvatar: friend1,
      image: matchBadminton,
      splitPrice: 60000,
      splitMultiplier: 4,
      level: 'intermediate',
      players: [
        SquadPlayerItem(id: 'p1', name: 'Minh Trí', avatar: friend1, hasPaid: true),
        SquadPlayerItem(id: 'p2', name: 'Hoàng Nam', avatar: friend2, hasPaid: true),
      ],
    ),
    const SportSpotMatch(
      id: 'match-2',
      sport: 'pickleball',
      title: 'Pickleball Giao Lưu Thứ 7',
      venueName: 'Mỹ Đình Sports Arena',
      courtDetails: 'Sân A4 • Mặt Sân Cứng Ngoài Trời',
      timeDisplay: 'Ngày mai, 07:00',
      spotsTotal: 4,
      spotsTaken: 3,
      spotsNeeded: 1,
      hostName: 'Lan Hương',
      hostRank: 'Host • Rank 3.0',
      hostAvatar: friend2,
      image: matchPickleball,
      splitPrice: 45000,
      splitMultiplier: 4,
      level: 'intermediate',
      players: [
        SquadPlayerItem(id: 'p1', name: 'Lan Hương', avatar: friend2, hasPaid: true),
      ],
    ),
    const SportSpotMatch(
      id: 'match-3',
      sport: 'football',
      title: 'Bóng đá Mini 5 người',
      venueName: 'Sân vận động Thanh Xuân',
      courtDetails: 'Sân Cỏ Nhân Tạo 1 • Đèn Cao Áp',
      timeDisplay: 'Hôm nay, 20:00',
      spotsTotal: 10,
      spotsTaken: 7,
      spotsNeeded: 3,
      hostName: 'Duy Nam',
      hostRank: 'Host • Trận giao hữu',
      hostAvatar: friend3,
      image: matchFootball,
      splitPrice: 50000,
      splitMultiplier: 10,
      level: 'beginner',
      players: [
        SquadPlayerItem(id: 'p1', name: 'Duy Nam', avatar: friend3, hasPaid: true),
      ],
    ),
  ];
}
