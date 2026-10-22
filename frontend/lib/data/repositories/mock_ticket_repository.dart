import 'dart:convert';
import 'dart:typed_data';
import '../models/ticket_model.dart';
import 'ticket_repository.dart';

class MockTicketRepository implements TicketRepository {
  static const String _secret = '_SPORTSPOT_SECRET_KEY';

  final List<TicketModel> _tickets = [];
  final List<TransactionHistoryModel> _transactions = [];
  int _walletBalance = 120000;

  MockTicketRepository() {
    _seedInitialData();
  }

  static String buildSignedQrPayload(String bookingCode, int userId, String role) {
    final raw = 'SPORTSPOT|$bookingCode|$userId|$role';
    final checksum = _sha256Hex('$raw$_secret').substring(0, 8);
    return '$raw|$checksum';
  }

  static bool validateSignedQrPayload(String payload) {
    final parts = payload.trim().split('|');
    if (parts.length < 5 || parts[0] != 'SPORTSPOT') return false;
    final raw = '${parts[0]}|${parts[1]}|${parts[2]}|${parts[3]}';
    final expected = _sha256Hex('$raw$_secret').substring(0, 8);
    return expected == parts[4].toUpperCase();
  }

  /// Thuật toán SHA-256 chuẩn RFC 6234 thuần Dart (khớp 100% với SHA256.Create() trên .NET 8)
  static String _sha256Hex(String input) {
    const k = <int>[
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ];
    int rotr(int x, int n) => ((x & 0xffffffff) >>> n) | ((x << (32 - n)) & 0xffffffff);
    final bytes = utf8.encode(input);
    final bitLen = bytes.length * 8;
    final paddedLen = ((bytes.length + 9 + 63) ~/ 64) * 64;
    final data = Uint8List(paddedLen)..setRange(0, bytes.length, bytes);
    data[bytes.length] = 0x80;
    final bd = ByteData.sublistView(data);
    bd.setUint32(paddedLen - 8, (bitLen >>> 32) & 0xffffffff, Endian.big);
    bd.setUint32(paddedLen - 4, bitLen & 0xffffffff, Endian.big);

    var h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
    var h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;
    final w = List<int>.filled(64, 0);

    for (var offset = 0; offset < paddedLen; offset += 64) {
      for (var i = 0; i < 16; i++) {
        w[i] = bd.getUint32(offset + i * 4, Endian.big);
      }
      for (var i = 16; i < 64; i++) {
        final s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ ((w[i - 15] & 0xffffffff) >>> 3);
        final s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ ((w[i - 2] & 0xffffffff) >>> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
      }
      var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
      for (var i = 0; i < 64; i++) {
        final s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
        final ch = (e & f) ^ ((~e & 0xffffffff) & g);
        final temp1 = (h + s1 + ch + k[i] + w[i]) & 0xffffffff;
        final s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xffffffff;
        h = g; g = f; f = e; e = (d + temp1) & 0xffffffff;
        d = c; c = b; b = a; a = (temp1 + temp2) & 0xffffffff;
      }
      h0 = (h0 + a) & 0xffffffff; h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff; h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff; h5 = (h5 + f) & 0xffffffff;
      h6 = (h6 + g) & 0xffffffff; h7 = (h7 + h) & 0xffffffff;
    }

    return [h0, h1, h2, h3, h4, h5, h6, h7]
        .map((v) => v.toRadixString(16).padLeft(8, '0'))
        .join()
        .toUpperCase();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    // Vé 1: Cách hiện tại ~26 giờ (Bậc 1 >= 4h: Hoàn 100% cọc)
    final tomorrow = now.add(const Duration(days: 1));
    final date1 = _fmtDate(tomorrow);

    // Vé 2: Cách hiện tại ~2 giờ (Sắp diễn ra - kích hoạt cảnh báo nhắc lịch 2h & Bậc 2 hoàn 50%)
    final soon = now.add(const Duration(hours: 2, minutes: 15));
    final date2 = _fmtDate(soon);
    final slot2Start = '${soon.hour.toString().padLeft(2, '0')}:00';
    final slot2End = '${((soon.hour + 1) % 24).toString().padLeft(2, '0')}:00';

    // Vé 3: Vé tham gia kèo vãng lai (JoinedPlayer từ Module 4)
    final nextTwoDays = now.add(const Duration(days: 2));
    final date3 = _fmtDate(nextTwoDays);

    _tickets.addAll([
      TicketModel(
        bookingId: 501,
        bookingCode: 'SP-882410',
        venueId: 1,
        venueName: 'CLB Cầu Lông Cầu Giấy',
        subVenueName: 'Sân Số 1 (Thảm Yonex)',
        sportName: 'Cầu lông',
        address: 'Số 35 Trần Quý Kiên, Dịch Vọng, Cầu Giấy',
        playDate: date1,
        timeSlots: const ['18:00-19:00', '19:00-20:00'],
        userRoleInMatch: 'Host',
        courtPrice: 240000,
        servicesPrice: 30000,
        totalPrice: 270000,
        depositAmount: 135000,
        remainingBalance: 135000,
        status: 'Upcoming',
        escrowStatus: 'Holding',
        qrPayload: buildSignedQrPayload('SP-882410', 1, 'Host'),
        isCheckedIn: false,
      ),
      TicketModel(
        bookingId: 502,
        bookingCode: 'SP-391045',
        venueId: 2,
        venueName: 'Sân Bóng Đá Mini PVV',
        subVenueName: 'Sân 7A (Cỏ Nhân Tạo)',
        sportName: 'Bóng đá mini',
        address: 'Số 72 Trần Thái Tông, Dịch Vọng Hậu, Cầu Giấy',
        playDate: date2,
        timeSlots: ['$slot2Start-$slot2End'],
        userRoleInMatch: 'Host',
        courtPrice: 600000,
        servicesPrice: 0,
        totalPrice: 600000,
        depositAmount: 300000,
        remainingBalance: 300000,
        status: 'Upcoming',
        escrowStatus: 'Holding',
        qrPayload: buildSignedQrPayload('SP-391045', 1, 'Host'),
        isCheckedIn: false,
      ),
      TicketModel(
        bookingId: 503,
        bookingCode: 'SP-610299',
        venueId: 1,
        venueName: 'CLB Pickleball Thảo Điền',
        subVenueName: 'Court P1 (Mái che)',
        sportName: 'Pickleball',
        address: 'Số 28 Thảo Điền, TP. Thủ Đức',
        playDate: date3,
        timeSlots: const ['19:00-20:00', '20:00-21:00'],
        userRoleInMatch: 'JoinedPlayer',
        matchId: 12,
        courtPrice: 65000,
        servicesPrice: 0,
        totalPrice: 65000,
        depositAmount: 65000,
        remainingBalance: 0,
        status: 'Upcoming',
        escrowStatus: 'Holding',
        qrPayload: buildSignedQrPayload('SP-610299', 1, 'JoinedPlayer'),
        isCheckedIn: false,
      ),
    ]);

    _transactions.addAll([
      TransactionHistoryModel(
        id: 1,
        transactionCode: 'TXN-882410VN',
        bookingId: 501,
        bookingCode: 'SP-882410',
        venueName: 'CLB Cầu Lông Cầu Giấy',
        amount: 135000,
        paymentGateway: 'VNPay',
        status: 'Holding',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      ),
      TransactionHistoryModel(
        id: 2,
        transactionCode: 'TXN-391045MM',
        bookingId: 502,
        bookingCode: 'SP-391045',
        venueName: 'Sân Bóng Đá Mini PVV',
        amount: 300000,
        paymentGateway: 'MoMo',
        status: 'Holding',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      ),
      TransactionHistoryModel(
        id: 3,
        transactionCode: 'TXN-610299JP',
        bookingId: 503,
        bookingCode: 'SP-610299',
        venueName: 'CLB Pickleball Thảo Điền (Ghép kèo)',
        amount: 65000,
        paymentGateway: 'VNPay',
        status: 'Holding',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      ),
    ]);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<TicketSyncResult> getMyTickets({bool forceOffline = false}) async {
    return TicketSyncResult(
      tickets: List.unmodifiable(_tickets),
      isFromSqliteOffline: forceOffline,
    );
  }

  @override
  Future<TicketModel> createSandboxBookingAndPay({
    required int subVenueId,
    required String playDate,
    required List<int> slotIds,
    required int depositPercent,
    required String paymentGateway,
  }) async {
    final id = 600 + _tickets.length + 1;
    final code = 'SP-${(100000 + DateTime.now().millisecondsSinceEpoch % 899999)}';
    final courtPrice = slotIds.length * 120000;
    final deposit = (courtPrice * (depositPercent / 100.0)).round();

    if (paymentGateway.toLowerCase() == 'wallet') {
      if (_walletBalance < deposit) {
        throw Exception('Số dư ví không đủ để thanh toán cọc ($deposit đ)');
      }
      _walletBalance -= deposit;
    }

    final ticket = TicketModel(
      bookingId: id,
      bookingCode: code,
      venueId: 1,
      venueName: subVenueId == 2 ? 'Sân Bóng Đá Mini PVV' : 'CLB Cầu Lông Cầu Giấy',
      subVenueName: subVenueId == 2 ? 'Sân 7A (Cỏ Nhân Tạo)' : 'Sân Số 1 (Thảm Yonex)',
      sportName: subVenueId == 2 ? 'Bóng đá mini' : 'Cầu lông',
      address: 'Cầu Giấy, Hà Nội',
      playDate: playDate,
      timeSlots: slotIds.map((s) => '${(5 + s).toString().padLeft(2, '0')}:00-${(6 + s).toString().padLeft(2, '0')}:00').toList(),
      userRoleInMatch: 'Host',
      courtPrice: courtPrice,
      servicesPrice: 0,
      totalPrice: courtPrice,
      depositAmount: deposit,
      remainingBalance: courtPrice - deposit,
      status: 'Upcoming',
      escrowStatus: 'Holding',
      qrPayload: buildSignedQrPayload(code, 1, 'Host'),
      isCheckedIn: false,
    );

    _tickets.insert(0, ticket);
    _transactions.insert(
      0,
      TransactionHistoryModel(
        id: _transactions.length + 1,
        transactionCode: 'TXN-${code.replaceAll('SP-', '')}',
        bookingId: id,
        bookingCode: code,
        venueName: ticket.venueName,
        amount: deposit,
        paymentGateway: paymentGateway,
        status: 'Holding',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    return ticket;
  }

  @override
  Future<TicketModel> mockInstantPayByCode(String bookingCode) async {
    final idx = _tickets.indexWhere((t) => t.bookingCode == bookingCode);
    if (idx >= 0) {
      return _tickets[idx];
    }
    return createSandboxBookingAndPay(
      subVenueId: 1,
      playDate: _fmtDate(DateTime.now().add(const Duration(days: 1))),
      slotIds: const [13, 14],
      depositPercent: 50,
      paymentGateway: 'MockSandbox',
    );
  }

  @override
  Future<Map<String, dynamic>> verifyQrCheckIn(String qrPayload) async {
    if (!validateSignedQrPayload(qrPayload)) {
      throw Exception(
        'Mã QR không hợp lệ hoặc chữ ký bảo mật (SHA-256 Checksum) đã bị chỉnh sửa!',
      );
    }

    final parts = qrPayload.trim().split('|');
    final bookingCode = parts[1];
    final role = parts[3];

    final idx = _tickets.indexWhere((t) => t.bookingCode == bookingCode);
    if (idx >= 0) {
      if (_tickets[idx].isCheckedIn) {
        throw Exception('Vé $bookingCode này đã được check-in trước đó!');
      }
      _tickets[idx] = _tickets[idx].copyWith(
        status: 'Completed',
        escrowStatus: 'Settled',
        isCheckedIn: true,
      );
    }

    for (var i = 0; i < _transactions.length; i++) {
      if (_transactions[i].bookingCode == bookingCode &&
          _transactions[i].status == 'Holding') {
        final old = _transactions[i];
        _transactions[i] = TransactionHistoryModel(
          id: old.id,
          transactionCode: old.transactionCode,
          bookingId: old.bookingId,
          bookingCode: old.bookingCode,
          venueName: old.venueName,
          amount: old.amount,
          paymentGateway: old.paymentGateway,
          status: 'Settled',
          createdAt: old.createdAt,
        );
      }
    }

    return {
      'bookingCode': bookingCode,
      'customerName': 'Khách hàng SportSpot',
      'role': role,
      'subVenueName': idx >= 0 ? _tickets[idx].subVenueName : 'Sân Số 1',
      'venueName': idx >= 0 ? _tickets[idx].venueName : 'CLB Cầu Lông Cầu Giấy',
      'escrowStatus': 'Settled',
      'checkedInAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<CancelRefundResultModel> cancelTicket(TicketModel ticket) async {
    final preview = ticket.calculateRefundPreview();
    _walletBalance += preview.refundAmount;

    final idx = _tickets.indexWhere((t) => t.bookingCode == ticket.bookingCode);
    if (idx >= 0) {
      _tickets[idx] = _tickets[idx].copyWith(
        status: 'Cancelled',
        escrowStatus: preview.refundPercentage > 0 ? 'Refunded' : 'Settled',
      );
    }

    for (var i = 0; i < _transactions.length; i++) {
      if (_transactions[i].bookingCode == ticket.bookingCode &&
          _transactions[i].status == 'Holding') {
        final old = _transactions[i];
        _transactions[i] = TransactionHistoryModel(
          id: old.id,
          transactionCode: old.transactionCode,
          bookingId: old.bookingId,
          bookingCode: old.bookingCode,
          venueName: old.venueName,
          amount: old.amount,
          paymentGateway: old.paymentGateway,
          status: preview.refundPercentage > 0 ? 'Refunded' : 'Settled',
          createdAt: old.createdAt,
        );
      }
    }

    return CancelRefundResultModel(
      bookingId: ticket.bookingId,
      bookingCode: ticket.bookingCode,
      hoursBeforeMatch: preview.hoursBeforeMatch,
      refundPercentage: preview.refundPercentage,
      refundAmount: preview.refundAmount,
      penaltyAmount: preview.penaltyAmount,
      newWalletBalance: _walletBalance,
      policyApplied: preview.policyTitle,
    );
  }

  @override
  Future<WalletSummaryResult> getWalletAndHistory() async {
    final holding = _transactions
        .where((t) => t.status == 'Holding')
        .fold<int>(0, (sum, item) => sum + item.amount);

    return WalletSummaryResult(
      walletBalance: _walletBalance,
      escrowHoldingTotal: holding,
      transactions: List.unmodifiable(_transactions),
    );
  }
}
