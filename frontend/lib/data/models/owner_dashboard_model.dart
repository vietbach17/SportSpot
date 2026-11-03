class DailyRevenueModel {
  final String date;
  final String dayOfWeek;
  final int revenue;
  final int bookingCount;

  const DailyRevenueModel({
    required this.date,
    required this.dayOfWeek,
    required this.revenue,
    required this.bookingCount,
  });

  factory DailyRevenueModel.fromJson(Map<String, dynamic> json) {
    return DailyRevenueModel(
      date: json['date'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      bookingCount: (json['bookingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class OwnerBookingModel {
  final int bookingId;
  final String bookingCode;
  final String customerName;
  final String customerPhone;
  final String subVenueName;
  final String playDate;
  final List<String> timeSlots;
  final int totalPrice;
  final int depositAmount;
  final String status;
  final String escrowStatus;
  final DateTime createdAt;

  const OwnerBookingModel({
    required this.bookingId,
    required this.bookingCode,
    required this.customerName,
    required this.customerPhone,
    required this.subVenueName,
    required this.playDate,
    required this.timeSlots,
    required this.totalPrice,
    required this.depositAmount,
    required this.status,
    required this.escrowStatus,
    required this.createdAt,
  });

  factory OwnerBookingModel.fromJson(Map<String, dynamic> json) {
    return OwnerBookingModel(
      bookingId: json['bookingId'] as int? ?? 0,
      bookingCode: json['bookingCode'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Khách đặt sân',
      customerPhone: json['customerPhone'] as String? ?? '',
      subVenueName: json['subVenueName'] as String? ?? 'Sân chính',
      playDate: json['playDate'] as String? ?? '',
      timeSlots: (json['timeSlots'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      depositAmount: (json['depositAmount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'Upcoming',
      escrowStatus: json['escrowStatus'] as String? ?? 'Holding',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SubVenueManagementModel {
  final int id;
  final String name;
  final bool isActive;
  final int totalSlotsToday;
  final int bookedSlotsToday;

  const SubVenueManagementModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.totalSlotsToday,
    required this.bookedSlotsToday,
  });

  factory SubVenueManagementModel.fromJson(Map<String, dynamic> json) {
    return SubVenueManagementModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      totalSlotsToday: (json['totalSlotsToday'] as num?)?.toInt() ?? 13,
      bookedSlotsToday: (json['bookedSlotsToday'] as num?)?.toInt() ?? 0,
    );
  }

  SubVenueManagementModel copyWith({bool? isActive}) {
    return SubVenueManagementModel(
      id: id,
      name: name,
      isActive: isActive ?? this.isActive,
      totalSlotsToday: totalSlotsToday,
      bookedSlotsToday: bookedSlotsToday,
    );
  }
}

class OwnerDashboardModel {
  final int venueId;
  final String venueName;
  final String venueAddress;
  final String sportName;
  final int totalBookings;
  final int totalRevenue;
  final int escrowHoldingAmount;
  final int occupancyRatePercentage;
  final int activeSubVenuesCount;
  final int totalSubVenuesCount;
  final List<DailyRevenueModel> dailyRevenues;
  final List<OwnerBookingModel> recentBookings;
  final List<SubVenueManagementModel> subVenues;

  const OwnerDashboardModel({
    required this.venueId,
    required this.venueName,
    required this.venueAddress,
    required this.sportName,
    required this.totalBookings,
    required this.totalRevenue,
    required this.escrowHoldingAmount,
    required this.occupancyRatePercentage,
    required this.activeSubVenuesCount,
    required this.totalSubVenuesCount,
    required this.dailyRevenues,
    required this.recentBookings,
    required this.subVenues,
  });

  factory OwnerDashboardModel.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardModel(
      venueId: json['venueId'] as int? ?? 1,
      venueName: json['venueName'] as String? ?? 'CLB Thể Thao',
      venueAddress: json['venueAddress'] as String? ?? '',
      sportName: json['sportName'] as String? ?? 'Cầu lông',
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
      escrowHoldingAmount: (json['escrowHoldingAmount'] as num?)?.toInt() ?? 0,
      occupancyRatePercentage: (json['occupancyRatePercentage'] as num?)?.toInt() ?? 0,
      activeSubVenuesCount: (json['activeSubVenuesCount'] as num?)?.toInt() ?? 0,
      totalSubVenuesCount: (json['totalSubVenuesCount'] as num?)?.toInt() ?? 0,
      dailyRevenues: (json['dailyRevenues'] as List<dynamic>? ?? [])
          .map((e) => DailyRevenueModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      recentBookings: (json['recentBookings'] as List<dynamic>? ?? [])
          .map((e) => OwnerBookingModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subVenues: (json['subVenues'] as List<dynamic>? ?? [])
          .map((e) => SubVenueManagementModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
