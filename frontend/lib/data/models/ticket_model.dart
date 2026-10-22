class TieredRefundPreview {
  final double hoursBeforeMatch;
  final int refundPercentage;
  final int refundAmount;
  final int penaltyAmount;
  final String policyTitle;
  final String policyDetail;

  const TieredRefundPreview({
    required this.hoursBeforeMatch,
    required this.refundPercentage,
    required this.refundAmount,
    required this.penaltyAmount,
    required this.policyTitle,
    required this.policyDetail,
  });
}

class TicketModel {
  final int bookingId;
  final String bookingCode;
  final int venueId;
  final String venueName;
  final String subVenueName;
  final String sportName;
  final String address;
  final String playDate; // YYYY-MM-DD
  final List<String> timeSlots; // ["18:00-19:00", "19:00-20:00"]
  final String userRoleInMatch; // 'Host' hoặc 'JoinedPlayer'
  final int? matchId;
  final int courtPrice;
  final int servicesPrice;
  final int totalPrice;
  final int depositAmount;
  final int remainingBalance;
  final String status; // 'Upcoming', 'Completed', 'Cancelled'
  final String escrowStatus; // 'Holding', 'Settled', 'Refunded'
  final String qrPayload; // SPORTSPOT|CODE|UID|ROLE|CHECKSUM
  final bool isCheckedIn;
  final int notificationId;

  const TicketModel({
    required this.bookingId,
    required this.bookingCode,
    this.venueId = 1,
    required this.venueName,
    required this.subVenueName,
    required this.sportName,
    required this.address,
    required this.playDate,
    required this.timeSlots,
    this.userRoleInMatch = 'Host',
    this.matchId,
    required this.courtPrice,
    this.servicesPrice = 0,
    required this.totalPrice,
    required this.depositAmount,
    required this.remainingBalance,
    required this.status,
    this.escrowStatus = 'Holding',
    required this.qrPayload,
    this.isCheckedIn = false,
    this.notificationId = 100,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['timeSlots'];
    List<String> parsedSlots = [];
    if (rawSlots is List) {
      parsedSlots = rawSlots.map((e) => e.toString()).toList();
    } else if (rawSlots is String && rawSlots.isNotEmpty) {
      parsedSlots = rawSlots.split(',').map((s) => s.trim()).toList();
    }

    final code = json['bookingCode']?.toString() ?? '';
    return TicketModel(
      bookingId: (json['bookingId'] as num?)?.toInt() ?? 0,
      bookingCode: code,
      venueId: (json['venueId'] as num?)?.toInt() ?? 1,
      venueName: json['venueName']?.toString() ?? 'Cụm Sân SportSpot',
      subVenueName: json['subVenueName']?.toString() ?? 'Sân 1',
      sportName: json['sportName']?.toString() ?? 'Cầu lông',
      address: json['address']?.toString() ?? '',
      playDate: json['playDate']?.toString() ?? '',
      timeSlots: parsedSlots,
      userRoleInMatch: json['userRoleInMatch']?.toString() ?? 'Host',
      matchId: (json['matchId'] as num?)?.toInt(),
      courtPrice: (json['courtPrice'] as num?)?.toInt() ?? 0,
      servicesPrice: (json['servicesPrice'] as num?)?.toInt() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      depositAmount: (json['depositAmount'] as num?)?.toInt() ?? 0,
      remainingBalance: (json['remainingBalance'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'Upcoming',
      escrowStatus: json['escrowStatus']?.toString() ??
          (json['status'] == 'Completed'
              ? 'Settled'
              : json['status'] == 'Cancelled'
                  ? 'Refunded'
                  : 'Holding'),
      qrPayload: json['qrPayload']?.toString() ?? '',
      isCheckedIn: json['isCheckedIn'] == true,
      notificationId: code.hashCode.abs() % 90000 + 10000,
    );
  }

  factory TicketModel.fromSqliteMap(Map<String, dynamic> map) {
    final rawSlots = map['time_slots']?.toString() ?? '';
    final parsedSlots = rawSlots
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final status = map['status']?.toString() ?? 'Upcoming';
    final isChecked = map['is_checked_in'] == 1 || map['is_checked_in'] == true;
    final totalPrice = (map['total_price'] as num?)?.toInt() ?? 0;
    final depositAmount = (map['deposit_amount'] as num?)?.toInt() ?? 0;

    return TicketModel(
      bookingId: (map['booking_id'] as num?)?.toInt() ??
          (map['notification_id'] as num?)?.toInt() ??
          1,
      bookingCode: map['booking_code']?.toString() ?? '',
      venueId: (map['venue_id'] as num?)?.toInt() ?? 1,
      venueName: map['venue_name']?.toString() ?? '',
      subVenueName: map['sub_venue_name']?.toString() ?? '',
      sportName: map['sport_name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      playDate: map['play_date']?.toString() ?? '',
      timeSlots: parsedSlots,
      userRoleInMatch: map['user_role_in_match']?.toString() ?? 'Host',
      courtPrice: totalPrice,
      servicesPrice: 0,
      totalPrice: totalPrice,
      depositAmount: depositAmount,
      remainingBalance: (totalPrice - depositAmount).clamp(0, totalPrice),
      status: status,
      escrowStatus: isChecked || status == 'Completed'
          ? 'Settled'
          : status == 'Cancelled'
              ? 'Refunded'
              : 'Holding',
      qrPayload: map['qr_payload']?.toString() ?? '',
      isCheckedIn: isChecked,
      notificationId: (map['notification_id'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'booking_id': bookingId,
      'booking_code': bookingCode,
      'venue_id': venueId,
      'venue_name': venueName,
      'sport_name': sportName,
      'sub_venue_name': subVenueName,
      'address': address,
      'play_date': playDate,
      'time_slots': timeSlots.join(', '),
      'user_role_in_match': userRoleInMatch,
      'total_price': totalPrice,
      'deposit_amount': depositAmount,
      'status': status,
      'qr_payload': qrPayload,
      'is_checked_in': isCheckedIn ? 1 : 0,
      'notification_id': notificationId,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  TicketModel copyWith({
    String? status,
    String? escrowStatus,
    bool? isCheckedIn,
  }) {
    return TicketModel(
      bookingId: bookingId,
      bookingCode: bookingCode,
      venueId: venueId,
      venueName: venueName,
      subVenueName: subVenueName,
      sportName: sportName,
      address: address,
      playDate: playDate,
      timeSlots: timeSlots,
      userRoleInMatch: userRoleInMatch,
      matchId: matchId,
      courtPrice: courtPrice,
      servicesPrice: servicesPrice,
      totalPrice: totalPrice,
      depositAmount: depositAmount,
      remainingBalance: remainingBalance,
      status: status ?? this.status,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      qrPayload: qrPayload,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      notificationId: notificationId,
    );
  }

  /// Trích xuất chữ ký SHA-256 (8 ký tự cuối) từ chuỗi QR Payload
  String get checksumSignature {
    final parts = qrPayload.split('|');
    if (parts.length >= 5) {
      return parts[4];
    }
    return 'VERIFIED';
  }

  /// Thời điểm bắt đầu ca thi đấu đầu tiên
  DateTime get matchStartDateTime {
    try {
      final dateParts = playDate.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      int hour = 18;
      int minute = 0;
      if (timeSlots.isNotEmpty) {
        final firstStart = timeSlots.first.split('-').first.trim();
        final timeParts = firstStart.split(':');
        if (timeParts.length >= 2) {
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
        }
      }
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return DateTime.now().add(const Duration(hours: 5));
    }
  }

  /// Số giờ còn lại trước giờ bóng lăn
  double hoursUntilMatch({DateTime? fromTime}) {
    final ref = fromTime ?? DateTime.now();
    final diffMinutes = matchStartDateTime.difference(ref).inMinutes;
    return double.parse((diffMinutes / 60.0).toStringAsFixed(1));
  }

  /// Cảnh báo nhắc lịch trước giờ thi đấu 2 tiếng (BR-PASS-03)
  bool isReminderDue({DateTime? fromTime}) {
    if (status != 'Upcoming' || isCheckedIn) return false;
    final hours = hoursUntilMatch(fromTime: fromTime);
    return hours > 0 && hours <= 2.5;
  }

  /// Tính toán chính sách hoàn/phạt bậc thang theo thời gian thực (BR-CANCEL-01..03)
  TieredRefundPreview calculateRefundPreview({DateTime? fromTime}) {
    final hours = hoursUntilMatch(fromTime: fromTime);
    int pct;
    String title;
    String detail;

    if (hours >= 4.0) {
      pct = 100;
      title = 'Bậc 1 (Trước >= 4 giờ): Hoàn 100% cọc';
      detail = 'Bạn hủy sớm trước giờ bóng lăn hơn 4 tiếng nên được hoàn 100% tiền đặt cọc về Ví SportSpot.';
    } else if (hours >= 2.0) {
      pct = 50;
      title = 'Bậc 2 (Từ 2 - 4 giờ): Hoàn 50% • Phạt 50%';
      detail = 'Hủy trong khoảng 2 đến 4 tiếng trước giờ đá: Hoàn 50% về Ví và trích 50% bồi thường chủ sân.';
    } else {
      pct = 0;
      title = 'Bậc 3 (Sát giờ < 2 giờ): Phạt 100% cọc';
      detail = 'Hủy sát giờ thi đấu (dưới 2 tiếng): Phạt 100% tiền cọc để bồi thường khung giờ trống cho chủ sân.';
    }

    final refund = (depositAmount * (pct / 100.0)).round();
    final penalty = depositAmount - refund;

    return TieredRefundPreview(
      hoursBeforeMatch: hours,
      refundPercentage: pct,
      refundAmount: refund,
      penaltyAmount: penalty,
      policyTitle: title,
      policyDetail: detail,
    );
  }
}

class CancelRefundResultModel {
  final int bookingId;
  final String bookingCode;
  final double hoursBeforeMatch;
  final int refundPercentage;
  final int refundAmount;
  final int penaltyAmount;
  final int newWalletBalance;
  final String policyApplied;

  const CancelRefundResultModel({
    required this.bookingId,
    required this.bookingCode,
    required this.hoursBeforeMatch,
    required this.refundPercentage,
    required this.refundAmount,
    required this.penaltyAmount,
    required this.newWalletBalance,
    required this.policyApplied,
  });

  factory CancelRefundResultModel.fromJson(Map<String, dynamic> json) {
    return CancelRefundResultModel(
      bookingId: (json['bookingId'] as num?)?.toInt() ?? 0,
      bookingCode: json['bookingCode']?.toString() ?? '',
      hoursBeforeMatch: (json['hoursBeforeMatch'] as num?)?.toDouble() ?? 0.0,
      refundPercentage: (json['refundPercentage'] as num?)?.toInt() ?? 0,
      refundAmount: (json['refundAmount'] as num?)?.toInt() ?? 0,
      penaltyAmount: (json['penaltyAmount'] as num?)?.toInt() ?? 0,
      newWalletBalance: (json['newWalletBalance'] as num?)?.toInt() ?? 0,
      policyApplied: json['policyApplied']?.toString() ?? '',
    );
  }
}

class TransactionHistoryModel {
  final int id;
  final String transactionCode;
  final int bookingId;
  final String bookingCode;
  final String venueName;
  final int amount;
  final String paymentGateway;
  final String status; // 'Holding', 'Settled', 'Refunded', 'Failed'
  final String createdAt;

  const TransactionHistoryModel({
    required this.id,
    required this.transactionCode,
    required this.bookingId,
    required this.bookingCode,
    required this.venueName,
    required this.amount,
    required this.paymentGateway,
    required this.status,
    required this.createdAt,
  });

  factory TransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      transactionCode: json['transactionCode']?.toString() ?? '',
      bookingId: (json['bookingId'] as num?)?.toInt() ?? 0,
      bookingCode: json['bookingCode']?.toString() ?? '',
      venueName: json['venueName']?.toString() ?? 'SportSpot Venue',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      paymentGateway: json['paymentGateway']?.toString() ?? 'VNPay',
      status: json['status']?.toString() ?? 'Holding',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
