import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../data/models/ticket_model.dart';
import '../data/repositories/ticket_repository.dart';

class TicketProvider extends ChangeNotifier {
  final TicketRepository _repository;

  TicketProvider({TicketRepository? repository})
      : _repository = repository ?? ApiTicketRepository();

  List<TicketModel> _tickets = [];
  List<TransactionHistoryModel> _transactions = [];
  int _walletBalance = 320000;
  int _escrowHoldingTotal = 120000;
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
  TicketRepository get repository => _repository;

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
      _walletBalance = walletRes.walletBalance > 0 ? walletRes.walletBalance : (_walletBalance > 0 ? _walletBalance : 320000);
      _escrowHoldingTotal = walletRes.escrowHoldingTotal > 0 ? walletRes.escrowHoldingTotal : 120000;
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

  Future<TicketModel?> mockInstantPayByCode(String bookingCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ticket = await _repository.mockInstantPayByCode(bookingCode);
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

  Future<void> topUpWallet(int amount) async {
    try {
      await ApiClient().post('/api/payments/topup', {'amount': amount, 'userId': 1});
    } catch (_) {}
    _walletBalance += amount;
    _transactions.insert(
      0,
      TransactionHistoryModel(
        id: DateTime.now().millisecondsSinceEpoch % 10000,
        transactionCode: 'TOPUP-${DateTime.now().millisecondsSinceEpoch % 1000000}',
        bookingId: 0,
        bookingCode: 'TOPUP',
        venueName: 'Nạp tiền ví SportSpot',
        amount: amount,
        paymentGateway: 'VNPay',
        status: 'Settled',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> requestBankWithdrawal({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    required int amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _repository.requestBankWithdrawal(
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolder: accountHolder,
        amount: amount,
      );
      if (res.containsKey('remainingBalance')) {
        _walletBalance = res['remainingBalance'] as int;
      }
      _transactions.insert(
        0,
        TransactionHistoryModel(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          transactionCode: res['withdrawalCode']?.toString() ?? 'WD-NEW',
          bookingId: 0,
          bookingCode: 'WITHDRAWAL',
          venueName: 'Rút về $bankName ($accountNumber)',
          amount: amount,
          paymentGateway: 'BankTransfer',
          status: 'Processing',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void deductWallet(int amount) {
    if (_walletBalance >= amount) {
      _walletBalance -= amount;
      notifyListeners();
    }
  }

  void addConfirmedBookingTicket({
    required int bookingId,
    required String bookingCode,
    required String venueName,
    required String subVenueName,
    required String sportName,
    required String address,
    required String playDate,
    required List<String> timeSlots,
    required int courtPrice,
    required int servicesPrice,
    required int totalPrice,
    required int depositAmount,
    required int remainingBalance,
    required String qrPayload,
    required String paymentGateway,
    String userRoleInMatch = 'Khách ghép',
  }) {
    final newTicket = TicketModel(
      bookingId: bookingId,
      bookingCode: bookingCode,
      venueId: 1,
      venueName: venueName,
      subVenueName: subVenueName,
      sportName: sportName,
      address: address,
      playDate: playDate,
      timeSlots: timeSlots,
      userRoleInMatch: userRoleInMatch,
      courtPrice: courtPrice,
      servicesPrice: servicesPrice,
      totalPrice: totalPrice,
      depositAmount: depositAmount,
      remainingBalance: remainingBalance,
      status: 'Upcoming',
      escrowStatus: 'Holding',
      qrPayload: qrPayload,
    );

    _tickets.insert(0, newTicket);
    _escrowHoldingTotal += depositAmount;

    _transactions.insert(
      0,
      TransactionHistoryModel(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        transactionCode: 'TX-${DateTime.now().millisecondsSinceEpoch % 1000000}',
        bookingId: bookingId,
        bookingCode: bookingCode,
        venueName: venueName,
        amount: depositAmount,
        paymentGateway: paymentGateway,
        status: 'Holding',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    notifyListeners();
  }
}