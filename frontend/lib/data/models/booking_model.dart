class VenueSlotModel {
  final int slotId;
  final String startTime;
  final String endTime;
  final bool isPeak;
  final int price;
  final bool isBooked;
  final String status;

  VenueSlotModel({
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.isPeak,
    required this.price,
    required this.isBooked,
    this.status = 'Available',
  });

  bool get isAvailable => !isBooked && status == 'Available';

  factory VenueSlotModel.fromJson(Map<String, dynamic> json) {
    final isBooked = json['isBooked'] == true;
    final statusStr = json['status']?.toString() ?? (isBooked ? 'Booked' : 'Available');
    return VenueSlotModel(
      slotId: json['slotId'] ?? json['id'] ?? 0,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isPeak: json['isPeak'] == true,
      price: (json['price'] as num?)?.toInt() ?? 0,
      isBooked: isBooked || statusStr == 'Booked' || statusStr == 'Past',
      status: statusStr,
    );
  }

  Map<String, dynamic> toJson() => {
    'slotId': slotId,
    'startTime': startTime,
    'endTime': endTime,
    'isPeak': isPeak,
    'price': price,
    'isBooked': isBooked,
    'status': status,
  };
}

class SubVenueModel {
  final int id;
  final String name;
  final bool isActive;

  SubVenueModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory SubVenueModel.fromJson(Map<String, dynamic> json) {
    return SubVenueModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isActive: json['isActive'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isActive': isActive,
  };
}

class VenueServiceModel {
  final int id;
  final String name;
  final String type;
  final int price;
  final int stockQuantity;

  VenueServiceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.stockQuantity,
  });

  factory VenueServiceModel.fromJson(Map<String, dynamic> json) {
    return VenueServiceModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'Rental',
      price: (json['price'] as num?)?.toInt() ?? 0,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'price': price,
    'stockQuantity': stockQuantity,
  };
}

class VenueDetailModel {
  final int id;
  final int sportId;
  final String sportName;
  final String name;
  final String address;
  final String district;
  final int basePrice;
  final int peakPrice;
  final double rating;
  final String amenities;
  final String? imageUrl;
  final List<SubVenueModel> subVenues;
  final List<VenueServiceModel> services;

  VenueDetailModel({
    required this.id,
    required this.sportId,
    required this.sportName,
    required this.name,
    required this.address,
    required this.district,
    required this.basePrice,
    required this.peakPrice,
    required this.rating,
    required this.amenities,
    this.imageUrl,
    required this.subVenues,
    required this.services,
  });

  factory VenueDetailModel.fromJson(Map<String, dynamic> json) {
    return VenueDetailModel(
      id: json['id'] ?? 0,
      sportId: json['sportId'] ?? 0,
      sportName: json['sportName'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      basePrice: (json['basePrice'] as num?)?.toInt() ?? 0,
      peakPrice: (json['peakPrice'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      amenities: json['amenities'] ?? '',
      imageUrl: json['imageUrl'],
      subVenues: (json['subVenues'] as List<dynamic>?)
              ?.map((e) => SubVenueModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => VenueServiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BookingServiceItemRequest {
  final int serviceId;
  final int quantity;

  BookingServiceItemRequest({
    required this.serviceId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'quantity': quantity,
  };
}

class BookingRequestModel {
  final int subVenueId;
  final String playDate; // YYYY-MM-DD
  final List<int> slotIds;
  final List<BookingServiceItemRequest> services;
  final bool isOpenMatch;
  final int? totalExpectedPlayers;
  final int? neededPlayers;
  final String skillLevel;
  final int depositPercentage;
  final String paymentGateway;

  BookingRequestModel({
    required this.subVenueId,
    required this.playDate,
    required this.slotIds,
    this.services = const [],
    this.isOpenMatch = false,
    this.totalExpectedPlayers,
    this.neededPlayers,
    this.skillLevel = 'Cơ bản',
    this.depositPercentage = 100,
    this.paymentGateway = 'MockPayment',
  });

  Map<String, dynamic> toJson() => {
    'subVenueId': subVenueId,
    'playDate': playDate,
    'slotIds': slotIds,
    'services': services.map((s) => s.toJson()).toList(),
    'isOpenMatch': isOpenMatch,
    if (isOpenMatch) ...{
      'totalExpectedPlayers': totalExpectedPlayers,
      'neededPlayers': neededPlayers,
      'skillLevel': skillLevel,
    },
    'depositPercentage': depositPercentage,
    'paymentGateway': paymentGateway,
  };
}

class BookingResultModel {
  final int bookingId;
  final String bookingCode;
  final String venueName;
  final String subVenueName;
  final String sportName;
  final String address;
  final String playDate;
  final List<String> timeSlots;
  final int courtPrice;
  final int servicesPrice;
  final int totalPrice;
  final int depositAmount;
  final int remainingBalance;
  final String status;
  final String qrPayload;
  final bool isCheckedIn;

  BookingResultModel({
    required this.bookingId,
    required this.bookingCode,
    required this.venueName,
    required this.subVenueName,
    required this.sportName,
    required this.address,
    required this.playDate,
    required this.timeSlots,
    required this.courtPrice,
    required this.servicesPrice,
    required this.totalPrice,
    required this.depositAmount,
    required this.remainingBalance,
    required this.status,
    required this.qrPayload,
    required this.isCheckedIn,
  });

  factory BookingResultModel.fromJson(Map<String, dynamic> json) {
    return BookingResultModel(
      bookingId: json['bookingId'] ?? 0,
      bookingCode: json['bookingCode'] ?? '',
      venueName: json['venueName'] ?? '',
      subVenueName: json['subVenueName'] ?? '',
      sportName: json['sportName'] ?? '',
      address: json['address'] ?? '',
      playDate: json['playDate']?.toString() ?? '',
      timeSlots: (json['timeSlots'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      courtPrice: (json['courtPrice'] as num?)?.toInt() ?? 0,
      servicesPrice: (json['servicesPrice'] as num?)?.toInt() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      depositAmount: (json['depositAmount'] as num?)?.toInt() ?? 0,
      remainingBalance: (json['remainingBalance'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'Upcoming',
      qrPayload: json['qrPayload'] ?? '',
      isCheckedIn: json['isCheckedIn'] == true,
    );
  }
}
