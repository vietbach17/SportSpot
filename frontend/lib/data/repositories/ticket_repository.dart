import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/ticket_model.dart';
import '../services/database_helper.dart';
import 'mock_ticket_repository.dart';

class TicketSyncResult {
  final List<TicketModel> tickets;
  final bool isFromSqliteOffline;

  const TicketSyncResult({
    required this.tickets,
    required this.isFromSqliteOffline,
  });
}

class WalletSummaryResult {
  final int walletBalance;
  final int escrowHoldingTotal;
  final List<TransactionHistoryModel> transactions;

  const WalletSummaryResult({
    required this.walletBalance,
    required this.escrowHoldingTotal,
    required this.transactions,
  });
}

abstract class TicketRepository {
  Future<TicketSyncResult> getMyTickets({bool forceOffline = false});
  Future<TicketModel> createSandboxBookingAndPay({
    required int subVenueId,
    required String playDate,
    required List<int> slotIds,
    required int depositPercent,
    required String paymentGateway,
  });
  Future<TicketModel> mockInstantPayByCode(String bookingCode);
  Future<Map<String, dynamic>> verifyQrCheckIn(String qrPayload);
  Future<CancelRefundResultModel> cancelTicket(TicketModel ticket);
  Future<WalletSummaryResult> getWalletAndHistory();
}

class ApiTicketRepository implements TicketRepository {
  final ApiClient _client;
  final DatabaseHelper _dbHelper;
  final MockTicketRepository _fallbackMock;

  ApiTicketRepository({
    ApiClient? client,
    DatabaseHelper? dbHelper,
    MockTicketRepository? fallbackMock,
  })  : _client = client ?? ApiClient(),
        _dbHelper = dbHelper ?? DatabaseHelper(),
        _fallbackMock = fallbackMock ?? MockTicketRepository();

  @override
  Future<TicketSyncResult> getMyTickets({bool forceOffline = false}) async {
    if (forceOffline) {
      final localRows = await _dbHelper.getOfflineBookings();
      if (localRows.isNotEmpty) {
        return TicketSyncResult(
          tickets: localRows.map(TicketModel.fromSqliteMap).toList(),
          isFromSqliteOffline: true,
        );
      }
      // Nếu SQLite chưa có dữ liệu lần đầu, nạp bộ vé mẫu vào SQLite để demo Offline
      final mockRes = await _fallbackMock.getMyTickets(forceOffline: true);
      await _dbHelper.saveOfflineBookings(
        mockRes.tickets.map((t) => t.toSqliteMap()).toList(),
      );
      return TicketSyncResult(
        tickets: mockRes.tickets,
        isFromSqliteOffline: true,
      );
    }

    try {
      final data = await _client.get(ApiConstants.myTickets);
      final list = (data as List<dynamic>)
          .map((item) => TicketModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      if (list.isNotEmpty) {
        await _dbHelper.saveOfflineBookings(
          list.map((t) => t.toSqliteMap()).toList(),
        );
      }
      return TicketSyncResult(
        tickets: list,
        isFromSqliteOffline: false,
      );
    } catch (_) {
      // Mất kết nối mạng hoặc Server chưa bật -> Tự động đọc từ SQLite (Offline-first)
      final localRows = await _dbHelper.getOfflineBookings();
      if (localRows.isNotEmpty) {
        return TicketSyncResult(
          tickets: localRows.map(TicketModel.fromSqliteMap).toList(),
          isFromSqliteOffline: true,
        );
      }

      final mockRes = await _fallbackMock.getMyTickets(forceOffline: true);
      await _dbHelper.saveOfflineBookings(
        mockRes.tickets.map((t) => t.toSqliteMap()).toList(),
      );
      return TicketSyncResult(
        tickets: mockRes.tickets,
        isFromSqliteOffline: true,
      );
    }
  }

  @override
  Future<TicketModel> createSandboxBookingAndPay({
    required int subVenueId,
    required String playDate,
    required List<int> slotIds,
    required int depositPercent,
    required String paymentGateway,
  }) async {
    try {
      // Bước 1: Tạo đơn đặt sân
      final bookingData = await _client.post(ApiConstants.bookings, {
        'subVenueId': subVenueId,
        'playDate': playDate,
        'slotIds': slotIds,
        'depositPercentage': depositPercent,
        'paymentGateway': paymentGateway,
      });

      final createdTicket = TicketModel.fromJson(
        Map<String, dynamic>.from(bookingData as Map),
      );

      // Bước 2: Tạo Payment Intent & Xác nhận Webhook IPN để chuyển sang Holding Escrow
      final intentData = await _client.post(ApiConstants.createPaymentIntent, {
        'bookingId': createdTicket.bookingId,
        'amount': createdTicket.depositAmount,
        'paymentGateway': paymentGateway,
      });

      final intentMap = Map<String, dynamic>.from(intentData as Map);
      final txnCode = intentMap['transactionCode']?.toString() ?? '';
      if (txnCode.isNotEmpty && paymentGateway.toLowerCase() != 'wallet') {
        await _client.post(ApiConstants.paymentWebhook, {
          'transactionCode': txnCode,
          'isSuccess': true,
        });
      }

      // Bước 3: Lưu ngay vé có chữ ký SHA-256 vào SQLite `offline_bookings`
      await _dbHelper.upsertOfflineBooking(createdTicket.toSqliteMap());
      return createdTicket;
    } catch (_) {
      // Fallback sang Mock nếu đang chạy không bật Backend hoặc trùng slot
      final mockTicket = await _fallbackMock.createSandboxBookingAndPay(
        subVenueId: subVenueId,
        playDate: playDate,
        slotIds: slotIds,
        depositPercent: depositPercent,
        paymentGateway: paymentGateway,
      );
      await _dbHelper.upsertOfflineBooking(mockTicket.toSqliteMap());
      return mockTicket;
    }
  }

  @override
  Future<TicketModel> mockInstantPayByCode(String bookingCode) async {
    final data = await _client.post(ApiConstants.mockInstantPay(bookingCode), {});
    final ticket = TicketModel.fromJson(Map<String, dynamic>.from(data as Map));
    await _dbHelper.upsertOfflineBooking(ticket.toSqliteMap());
    return ticket;
  }

  @override
  Future<Map<String, dynamic>> verifyQrCheckIn(String qrPayload) async {
    try {
      final data = await _client.post(ApiConstants.verifyQr, {
        'qrPayload': qrPayload.trim(),
      });
      final map = Map<String, dynamic>.from(data as Map);
      final code = map['bookingCode']?.toString() ?? '';
      if (code.isNotEmpty) {
        await _dbHelper.updateOfflineBookingStatus(
          code,
          status: 'Completed',
          isCheckedIn: true,
        );
      }
      return map;
    } catch (e) {
      // Nếu lỗi do mã QR bị sửa đổi (Checksum không khớp), ném lỗi ngay để UI cảnh báo
      final msg = e.toString();
      if (msg.contains('không hợp lệ') || msg.contains('Checksum') || msg.contains('đã được check-in')) {
        rethrow;
      }
      // Nếu đang ở chế độ Offline / Mock, dùng trình kiểm tra chữ ký cục bộ của Mock
      final res = await _fallbackMock.verifyQrCheckIn(qrPayload);
      final code = res['bookingCode']?.toString() ?? '';
      if (code.isNotEmpty) {
        await _dbHelper.updateOfflineBookingStatus(
          code,
          status: 'Completed',
          isCheckedIn: true,
        );
      }
      return res;
    }
  }

  @override
  Future<CancelRefundResultModel> cancelTicket(TicketModel ticket) async {
    try {
      final data = await _client.post(
        ApiConstants.cancelTicket(ticket.bookingId),
        {},
      );
      final result = CancelRefundResultModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
      await _dbHelper.updateOfflineBookingStatus(
        ticket.bookingCode,
        status: 'Cancelled',
      );
      return result;
    } catch (_) {
      final result = await _fallbackMock.cancelTicket(ticket);
      await _dbHelper.updateOfflineBookingStatus(
        ticket.bookingCode,
        status: 'Cancelled',
      );
      return result;
    }
  }

  @override
  Future<WalletSummaryResult> getWalletAndHistory() async {
    try {
      final data = await _client.get(ApiConstants.paymentHistory);
      final map = Map<String, dynamic>.from(data as Map);
      final txList = (map['transactions'] as List<dynamic>? ?? [])
          .map((e) => TransactionHistoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return WalletSummaryResult(
        walletBalance: (map['walletBalance'] as num?)?.toInt() ?? 0,
        escrowHoldingTotal: (map['escrowHoldingTotal'] as num?)?.toInt() ?? 0,
        transactions: txList,
      );
    } catch (_) {
      return _fallbackMock.getWalletAndHistory();
    }
  }
}
