import 'package:intl/intl.dart';

class TimeSlotModel {
  final int slotId;
  final String startTime;
  final String endTime;
  final int price;
  final bool isPeak;
  final String status; // 'Available', 'Booked', 'Past', 'Holding'

  TimeSlotModel({
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.isPeak,
    required this.status,
  });

  bool get isAvailable => status == 'Available';
  bool get isBooked => status == 'Booked';
  bool get isPast => status == 'Past';
  bool get isHolding => status == 'Holding';

  String get timeRange => '$startTime - $endTime';

  String get formattedPrice {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(price);
  }

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      slotId: json['slotId'] ?? json['id'] ?? 0,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      price: json['price'] ?? 0,
      isPeak: json['isPeak'] ?? false,
      status: json['status'] ?? (json['isBooked'] == true ? 'Booked' : 'Available'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'isPeak': isPeak,
      'status': status,
    };
  }
}

class ServiceItemModel {
  final int serviceId;
  final String name;
  final String type; // 'Rental' hoặc 'Sale'
  final int price;
  int quantity;

  ServiceItemModel({
    required this.serviceId,
    required this.name,
    required this.type,
    required this.price,
    this.quantity = 0,
  });

  String get formattedPrice {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(price);
  }

  int get itemTotalPrice => price * quantity;

  factory ServiceItemModel.fromJson(Map<String, dynamic> json) {
    return ServiceItemModel(
      serviceId: json['id'] ?? json['serviceId'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'Sale',
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'quantity': quantity,
    };
  }

  ServiceItemModel copyWith({int? quantity}) {
    return ServiceItemModel(
      serviceId: serviceId,
      name: name,
      type: type,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }
}

class BookingRequestModel {
  final int subVenueId;
  final DateTime playDate;
  final List<int> slotIds;
  final List<ServiceItemModel> services;
  final bool isOpenMatch;
  final int? totalExpectedPlayers;
  final int? neededPlayers;
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
    this.depositPercentage = 100,
    this.paymentGateway = 'MockPayment',
  });

  Map<String, dynamic> toJson() {
    return {
      'subVenueId': subVenueId,
      'playDate': DateFormat('yyyy-MM-dd').format(playDate),
      'slotIds': slotIds,
      'services': services.where((s) => s.quantity > 0).map((s) => s.toJson()).toList(),
      'isOpenMatch': isOpenMatch,
      'totalExpectedPlayers': totalExpectedPlayers,
      'neededPlayers': neededPlayers,
      'depositPercentage': depositPercentage,
      'paymentGateway': paymentGateway,
    };
  }
}

class BookingResponseModel {
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

  BookingResponseModel({
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
    this.isCheckedIn = false,
  });

  String get formattedTotalPrice => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(totalPrice);
  String get formattedCourtPrice => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(courtPrice);
  String get formattedServicesPrice => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(servicesPrice);
  String get formattedDepositAmount => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(depositAmount);
  String get formattedRemainingBalance => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(remainingBalance);

  factory BookingResponseModel.fromJson(Map<String, dynamic> json) {
    return BookingResponseModel(
      bookingId: json['bookingId'] ?? 0,
      bookingCode: json['bookingCode'] ?? '',
      venueName: json['venueName'] ?? '',
      subVenueName: json['subVenueName'] ?? '',
      sportName: json['sportName'] ?? '',
      address: json['address'] ?? '',
      playDate: json['playDate']?.toString() ?? '',
      timeSlots: (json['timeSlots'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      courtPrice: json['courtPrice'] ?? 0,
      servicesPrice: json['servicesPrice'] ?? 0,
      totalPrice: json['totalPrice'] ?? 0,
      depositAmount: json['depositAmount'] ?? 0,
      remainingBalance: json['remainingBalance'] ?? 0,
      status: json['status'] ?? 'Upcoming',
      qrPayload: json['qrPayload'] ?? '',
      isCheckedIn: json['isCheckedIn'] ?? false,
    );
  }
}
