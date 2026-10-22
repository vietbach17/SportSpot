import 'package:flutter/foundation.dart';
import '../data/models/ticket_model.dart';
import '../data/repositories/ticket_repository.dart';

class TicketProvider extends ChangeNotifier {
  final TicketRepository _repository;

  TicketProvider({TicketRepository? repository})
      : _repository = repository ?? ApiTicketRepository();

  List<TicketModel> _tickets = [];
  List<TransactionHistoryModel> _transactions = [];
  int _walletBalance = 0;
  int _escrowHoldingTotal = 0;
  bool _isLoading = false;
  bool _isOfflineMode = false;
  bool _isFromSqliteOffline = false;
  String? _errorMessage;

  List<TicketModel> get tickets => _tickets;
  List<TransactionHistoryModel> get transactions => _transactions;
  int get walletBalance => _walletBalance;
  int get escrowHoldingTotal => _escrowHoldingTotal;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;
  bool get isFromSqliteOffline => _isFromSqliteOffline || _isOfflineMode;
  String? get errorMessage => _errorMessage;

  List<TicketModel> get upcomingTickets =>
      _tickets.where((t) => t.status == 'Upcoming' && !t.isCheckedIn).toList();

  List<TicketModel> get completedTickets =>
      _tickets.where((t) => t.status == 'Completed' || t.isCheckedIn).toList();

  List<TicketModel> get cancelledTickets =>
      _tickets.where((t) => t.status == 'Cancelled').toList();

  /// Danh sách vé sắp đến giờ thi đấu trong vòng <= 2.5 giờ (Nhắc lịch trước 2h)
  List<TicketModel> get upcomingReminders =>
      upcomingTickets.where((t) => t.isReminderDue()).toList();

  Future<void> loadTickets({bool? forceOffline}) async {
    _isLoading = true;
    _errorMessage = null;
    if (forceOffline != null) {
      _isOfflineMode = forceOffline;
    }
    notifyListeners();

    try {
      final res = await _repository.getMyTickets(forceOffline: _isOfflineMode);
      _tickets = res.tickets;
      _isFromSqliteOffline = res.isFromSqliteOffline;

      final walletRes = await _repository.getWalletAndHistory();
      _walletBalance = walletRes.walletBalance;
      _escrowHoldingTotal = walletRes.escrowHoldingTotal;
      _transactions = walletRes.transactions;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleOfflineMode(bool value) async {
    _isOfflineMode = value;
    await loadTickets(forceOffline: value);
  }

  Future<TicketModel?> createSandboxBookingAndPay({
    required int subVenueId,
    required String playDate,
    required List<int> slotIds,
    required int depositPercent,
    required String paymentGateway,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ticket = await _repository.createSandboxBookingAndPay(
        subVenueId: subVenueId,
        playDate: playDate,
        slotIds: slotIds,
        depositPercent: depositPercent,
        paymentGateway: paymentGateway,
      );
      await loadTickets(forceOffline: _isOfflineMode);
      return ticket;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>> verifyQrCheckIn(String qrPayload) async {
    final result = await _repository.verifyQrCheckIn(qrPayload);
    await loadTickets(forceOffline: _isOfflineMode);
    return result;
  }

  Future<CancelRefundResultModel> cancelTicket(TicketModel ticket) async {
    final result = await _repository.cancelTicket(ticket);
    await loadTickets(forceOffline: _isOfflineMode);
    return result;
  }
}
