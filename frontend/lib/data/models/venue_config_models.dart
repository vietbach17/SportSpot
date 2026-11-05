import 'booking_model.dart';

class UploadedVenueImageModel {
  final int id;
  final String url;

  const UploadedVenueImageModel({required this.id, required this.url});

  factory UploadedVenueImageModel.fromJson(Map<String, dynamic> json) {
    return UploadedVenueImageModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      url: json['url']?.toString() ?? '',
    );
  }
}

class ModerationLogModel {
  final String decision;
  final String reason;
  final String adminName;
  final DateTime createdAt;

  const ModerationLogModel({
    required this.decision,
    required this.reason,
    required this.adminName,
    required this.createdAt,
  });

  factory ModerationLogModel.fromJson(Map<String, dynamic> json) {
    return ModerationLogModel(
      decision: json['decision']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      adminName: json['adminName']?.toString() ?? 'Admin',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class VenueSlotConfigItemModel {
  final int slotId;
  final String startTime;
  final String endTime;
  final bool isActive;
  final bool isPeak;
  final int? customPrice;
  final int effectivePrice;

  const VenueSlotConfigItemModel({
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.isPeak,
    this.customPrice,
    this.effectivePrice = 0,
  });

  VenueSlotConfigItemModel copyWith({
    bool? isActive,
    bool? isPeak,
    int? customPrice,
    bool clearCustomPrice = false,
    int? effectivePrice,
  }) {
    return VenueSlotConfigItemModel(
      slotId: slotId,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive ?? this.isActive,
      isPeak: isPeak ?? this.isPeak,
      customPrice: clearCustomPrice ? null : (customPrice ?? this.customPrice),
      effectivePrice: effectivePrice ?? this.effectivePrice,
    );
  }

  factory VenueSlotConfigItemModel.fromJson(Map<String, dynamic> json) {
    return VenueSlotConfigItemModel(
      slotId: (json['slotId'] as num?)?.toInt() ?? 0,
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      isActive: json['isActive'] != false,
      isPeak: json['isPeak'] == true,
      customPrice: (json['customPrice'] as num?)?.toInt(),
      effectivePrice: (json['effectivePrice'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toInputJson() => {
        'slotId': slotId,
        'isActive': isActive,
        'isPeak': isPeak,
        if (customPrice != null && customPrice! >= 1000) 'customPrice': customPrice,
      };
}

class VenueApplicationModel {
  final int id;
  final String name;
  final int sportId;
  final String sportName;
  final String address;
  final String district;
  final String hotline;
  final double latitude;
  final double longitude;
  final int basePrice;
  final int peakPrice;
  final int maxSlotsPerBooking;
  final int minDepositPercent;
  final int activeSlotCount;
  final String operatingHoursSummary;
  final String description;
  final String amenities;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final bool isActive;
  final int? ownerUserId;
  final String ownerName;
  final String ownerPhone;
  final DateTime? submittedAt;
  final String? rejectionReason;
  final int revision;
  final List<String> courtNames;
  final List<UploadedVenueImageModel> images;
  final List<VenueSlotConfigItemModel> slotConfigs;
  final List<VenueServiceModel> services;
  final List<ModerationLogModel> history;

  const VenueApplicationModel({
    required this.id,
    required this.name,
    required this.sportId,
    required this.sportName,
    required this.address,
    required this.district,
    required this.hotline,
    required this.latitude,
    required this.longitude,
    required this.basePrice,
    required this.peakPrice,
    this.maxSlotsPerBooking = 3,
    this.minDepositPercent = 30,
    this.activeSlotCount = 13,
    this.operatingHoursSummary = '06:00 - 22:00 (13 slot/ngày)',
    required this.description,
    required this.amenities,
    required this.status,
    required this.isActive,
    this.ownerUserId,
    required this.ownerName,
    required this.ownerPhone,
    this.submittedAt,
    this.rejectionReason,
    required this.revision,
    required this.courtNames,
    required this.images,
    this.slotConfigs = const [],
    this.services = const [],
    this.history = const [],
  });

  factory VenueApplicationModel.fromJson(Map<String, dynamic> json) {
    return VenueApplicationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      sportId: (json['sportId'] as num?)?.toInt() ?? 1,
      sportName: json['sportName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      hotline: json['hotline']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.7769,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.7009,
      basePrice: (json['basePrice'] as num?)?.toInt() ?? 100000,
      peakPrice: (json['peakPrice'] as num?)?.toInt() ?? 150000,
      maxSlotsPerBooking: (json['maxSlotsPerBooking'] as num?)?.toInt() ?? 3,
      minDepositPercent: (json['minDepositPercent'] as num?)?.toInt() ?? 30,
      activeSlotCount: (json['activeSlotCount'] as num?)?.toInt() ?? 13,
      operatingHoursSummary: json['operatingHoursSummary']?.toString() ?? '06:00 - 22:00 (13 slot/ngày)',
      description: json['description']?.toString() ?? '',
      amenities: json['amenities']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      isActive: json['isActive'] == true,
      ownerUserId: (json['ownerUserId'] as num?)?.toInt(),
      ownerName: json['ownerName']?.toString() ?? '',
      ownerPhone: json['ownerPhone']?.toString() ?? '',
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'].toString()) : null,
      rejectionReason: json['rejectionReason']?.toString(),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      courtNames: (json['courtNames'] as List?)?.map((e) => e.toString()).toList() ?? [],
      images: (json['images'] as List?)
              ?.map((e) => UploadedVenueImageModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      slotConfigs: (json['slotConfigs'] as List?)
              ?.map((e) => VenueSlotConfigItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      services: (json['services'] as List?)
              ?.map((e) => VenueServiceModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      history: (json['history'] as List?)
              ?.map((e) => ModerationLogModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}

class VenueStaffMemberModel {
  final int userId;
  final String fullName;
  final String phoneNumber;
  final String email;
  final bool isActive;

  const VenueStaffMemberModel({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.isActive,
  });

  factory VenueStaffMemberModel.fromJson(Map<String, dynamic> json) {
    return VenueStaffMemberModel(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      isActive: json['isActive'] != false,
    );
  }
}

class OwnerVenueConfigModel {
  final int venueId;
  final String name;
  final int sportId;
  final String sportName;
  final String address;
  final String district;
  final String hotline;
  final double latitude;
  final double longitude;
  final String description;
  final String amenities;
  final bool isActive;
  final String approvalStatus;
  final int basePrice;
  final int peakPrice;
  final int maxSlotsPerBooking;
  final int minDepositPercent;
  final int activeSlotCount;
  final String operatingHoursSummary;
  final List<UploadedVenueImageModel> images;
  final List<SubVenueModel> subVenues;
  final List<VenueServiceModel> services;
  final List<VenueSlotConfigItemModel> slotConfigs;
  final List<VenueStaffMemberModel> staffMembers;

  const OwnerVenueConfigModel({
    required this.venueId,
    required this.name,
    required this.sportId,
    required this.sportName,
    required this.address,
    required this.district,
    required this.hotline,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.amenities,
    required this.isActive,
    required this.approvalStatus,
    required this.basePrice,
    required this.peakPrice,
    required this.maxSlotsPerBooking,
    required this.minDepositPercent,
    required this.activeSlotCount,
    required this.operatingHoursSummary,
    required this.images,
    required this.subVenues,
    required this.services,
    required this.slotConfigs,
    required this.staffMembers,
  });

  factory OwnerVenueConfigModel.fromJson(Map<String, dynamic> json) {
    return OwnerVenueConfigModel(
      venueId: (json['venueId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      sportId: (json['sportId'] as num?)?.toInt() ?? 1,
      sportName: json['sportName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      hotline: json['hotline']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.7769,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.7009,
      description: json['description']?.toString() ?? '',
      amenities: json['amenities']?.toString() ?? '',
      isActive: json['isActive'] != false,
      approvalStatus: json['approvalStatus']?.toString() ?? 'Approved',
      basePrice: (json['basePrice'] as num?)?.toInt() ?? 100000,
      peakPrice: (json['peakPrice'] as num?)?.toInt() ?? 150000,
      maxSlotsPerBooking: (json['maxSlotsPerBooking'] as num?)?.toInt() ?? 3,
      minDepositPercent: (json['minDepositPercent'] as num?)?.toInt() ?? 30,
      activeSlotCount: (json['activeSlotCount'] as num?)?.toInt() ?? 13,
      operatingHoursSummary: json['operatingHoursSummary']?.toString() ?? '06:00 - 22:00',
      images: (json['images'] as List?)
              ?.map((e) => UploadedVenueImageModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      subVenues: (json['subVenues'] as List?)
              ?.map((e) => SubVenueModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      services: (json['services'] as List?)
              ?.map((e) => VenueServiceModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      slotConfigs: (json['slotConfigs'] as List?)
              ?.map((e) => VenueSlotConfigItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      staffMembers: (json['staffMembers'] as List?)
              ?.map((e) => VenueStaffMemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}

class AdminDayActivityModel {
  final String date;
  final int bookingCount;
  final int bookingValue;

  const AdminDayActivityModel({
    required this.date,
    required this.bookingCount,
    required this.bookingValue,
  });

  factory AdminDayActivityModel.fromJson(Map<String, dynamic> json) {
    return AdminDayActivityModel(
      date: json['date']?.toString() ?? '',
      bookingCount: (json['bookingCount'] as num?)?.toInt() ?? 0,
      bookingValue: (json['bookingValue'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminOverviewModel {
  final int totalUsers;
  final int activeUsers;
  final int totalVenues;
  final int pendingVenues;
  final int activeVenues;
  final int upcomingBookings;
  final int bookingValue30Days;
  final int escrowHolding;
  final List<AdminDayActivityModel> activity;
  final List<VenueApplicationModel> pendingApplications;

  const AdminOverviewModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalVenues,
    required this.pendingVenues,
    required this.activeVenues,
    required this.upcomingBookings,
    required this.bookingValue30Days,
    required this.escrowHolding,
    required this.activity,
    required this.pendingApplications,
  });

  factory AdminOverviewModel.fromJson(Map<String, dynamic> json) {
    return AdminOverviewModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
      totalVenues: (json['totalVenues'] as num?)?.toInt() ?? 0,
      pendingVenues: (json['pendingVenues'] as num?)?.toInt() ?? 0,
      activeVenues: (json['activeVenues'] as num?)?.toInt() ?? 0,
      upcomingBookings: (json['upcomingBookings'] as num?)?.toInt() ?? 0,
      bookingValue30Days: (json['bookingValue30Days'] as num?)?.toInt() ?? 0,
      escrowHolding: (json['escrowHolding'] as num?)?.toInt() ?? 0,
      activity: (json['activity'] as List?)
              ?.map((e) => AdminDayActivityModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      pendingApplications: (json['pendingApplications'] as List?)
              ?.map((e) => VenueApplicationModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}

class AdminUserModel {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final int venueCount;
  final int? staffVenueId;
  final String? staffVenueName;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.venueCount = 0,
    this.staffVenueId,
    this.staffVenueName,
  });

  AdminUserModel copyWith({
    String? role,
    bool? isActive,
    int? staffVenueId,
    String? staffVenueName,
  }) {
    return AdminUserModel(
      id: id,
      name: name,
      phone: phone,
      email: email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      venueCount: venueCount,
      staffVenueId: staffVenueId ?? this.staffVenueId,
      staffVenueName: staffVenueName ?? this.staffVenueName,
    );
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Player',
      isActive: json['isActive'] != false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      venueCount: (json['venueCount'] as num?)?.toInt() ?? 0,
      staffVenueId: (json['staffVenueId'] as num?)?.toInt(),
      staffVenueName: json['staffVenueName']?.toString(),
    );
  }
}

