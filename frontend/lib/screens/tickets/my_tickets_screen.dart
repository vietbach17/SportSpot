import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../providers/ticket_provider.dart';
import '../payment/payment_checkout_screen.dart';
import 'cancel_ticket_dialog.dart';
import 'qr_scanner_screen.dart';
import 'ticket_qr_detail_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  final TicketRepository? repository;

  const MyTicketsScreen({super.key, this.repository});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  static const Color _green = Color(0xFF16A34A);
  static const Color _pastelGreen = Color(0xFFDCFCE7);
  static const Color _red = Color(0xFFDC2626);

  late final TicketProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = TicketProvider(repository: widget.repository);
    _provider.addListener(_onProviderChanged);
    _provider.loadTickets();
  }

  void _onProviderChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    super.dispose();
  }

  String _formatVnd(int amount) => CancelTicketDialog.formatVnd(amount);

  @override
  Widget build(BuildContext context) {
    final upcoming = _provider.upcomingTickets;
    final completed = _provider.completedTickets;
    final cancelled = _provider.cancelledTickets;
    final reminders = _provider.upcomingReminders;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Vé Đặt & Ví Escrow'),
          actions: [
            IconButton(
              tooltip: 'Đồng bộ lại vé & lưu SQLite',
              onPressed: () => _provider.loadTickets(),
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
          bottom: TabBar(
            labelColor: _green,
            unselectedLabelColor: AppTheme.textGray,
            indicatorColor: _green,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'Sắp tới (${upcoming.length})'),
              Tab(text: 'Hoàn thành (${completed.length})'),
              Tab(text: 'Đã hủy (${cancelled.length})'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Khu vực tổng quan Ví Escrow + Offline SQLite + Thao tác nhanh
            _buildTopControlPanel(context),

            // Banner nhắc lịch trước giờ bóng lăn 2 tiếng
            if (reminders.isNotEmpty) _buildPreMatchReminderBanner(reminders.first),

            // Danh sách vé theo Tab
            Expanded(
              child: _provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildTicketList(
                          upcoming,
                          emptyTitle: 'Chưa có vé sắp diễn ra',
                          emptySubtitle:
                              'Nhấn "Đặt Sân & Thanh Toán" bên trên để tạo vé QR mới.',
                        ),
                        _buildTicketList(
                          completed,
                          emptyTitle: 'Chưa có vé đã check-in hoàn thành',
                          emptySubtitle:
                              'Vé sau khi quét QR tại sân sẽ chuyển sang trạng thái Đã giải ngân (Settled).',
                        ),
                        _buildTicketList(
                          cancelled,
                          emptyTitle: 'Chưa có vé nào bị hủy',
                          emptySubtitle:
                              'Vé hủy sẽ được tính hoàn tiền tự động (100% / 50% / 0%) theo thời gian.',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControlPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Hàng 1: Số dư Ví Hoàn Tiền & Số dư Tạm Giữ Escrow
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _pastelGreen.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 15,
                            color: _green,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Ví Hoàn Tiền',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatVnd(_provider.walletBalance),
                        key: const Key('wallet_balance_text'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 15,
                            color: AppTheme.accentBlue,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Escrow Holding',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatVnd(_provider.escrowHoldingTotal),
                        key: const Key('escrow_holding_text'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Hàng 2: Công tắc Giả lập Mất mạng (Đọc từ SQLite offline_bookings)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _provider.isFromSqliteOffline
                  ? const Color(0xFFFEF3C7)
                  : AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _provider.isFromSqliteOffline
                      ? Icons.wifi_off_rounded
                      : Icons.storage_rounded,
                  size: 18,
                  color: _provider.isFromSqliteOffline
                      ? const Color(0xFFB45309)
                      : _green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _provider.isFromSqliteOffline
                        ? 'Đang mở vé từ bộ nhớ SQLite Offline (Không cần mạng)'
                        : 'Đã đồng bộ tự động vào bảng SQLite offline_bookings',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _provider.isFromSqliteOffline
                          ? const Color(0xFF92400E)
                          : AppTheme.textDark,
                    ),
                  ),
                ),
                Switch(
                  key: const Key('offline_mode_switch'),
                  value: _provider.isOfflineMode,
                  activeThumbColor: const Color(0xFFD97706),
                  onChanged: (val) => _provider.toggleOfflineMode(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Hàng 3: Các nút chức năng chính của Module 5
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('open_checkout_btn'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentCheckoutScreen(
                          ticketProvider: _provider,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_card_rounded, size: 17),
                  label: const Text('Đặt Sân & Thanh Toán'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('open_qr_scanner_btn'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QrScannerScreen(
                          provider: _provider,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 17),
                  label: const Text('Lễ Tân Quét QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentBlue,
                    side: const BorderSide(color: AppTheme.accentBlue),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const Key('open_tx_history_btn'),
                tooltip: 'Lịch sử dòng tiền Escrow',
                onPressed: () => _showTransactionHistorySheet(context),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.background,
                ),
                icon: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.textDark,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreMatchReminderBanner(TicketModel ticket) {
    final hoursLeft = ticket.hoursUntilMatch();
    final minutesLeft = (hoursLeft * 60).round().clamp(1, 180);
    final slotsText = ticket.timeSlots.join(', ');

    return Container(
      key: const Key('pre_match_reminder_banner'),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NHẮC LỊCH: Trận đấu bắt đầu sau ~$minutesLeft phút!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ticket.venueName} • ${ticket.subVenueName} ($slotsText)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketQrDetailScreen(
                    ticket: ticket,
                    provider: _provider,
                    isOfflineMode: _provider.isFromSqliteOffline,
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFB45309),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Mở QR',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(
    List<TicketModel> list, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 56,
                color: AppTheme.textGray.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 12),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textGray,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _provider.loadTickets(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildTicketCard(list[index]),
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    final isUpcoming = ticket.status == 'Upcoming' && !ticket.isCheckedIn;
    final isCompleted = ticket.status == 'Completed' || ticket.isCheckedIn;
    final isHost = ticket.userRoleInMatch == 'Host';

    Color statusColor = AppTheme.accentBlue;
    String statusLabel = 'Sắp diễn ra';
    if (isCompleted) {
      statusColor = _green;
      statusLabel = 'Đã Check-in • Settled';
    } else if (ticket.status == 'Cancelled') {
      statusColor = _red;
      statusLabel = 'Đã hủy';
    }

    return Container(
      key: Key('ticket_card_${ticket.bookingId}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ticket.isReminderDue()
              ? const Color(0xFFF59E0B)
              : Colors.grey.shade200,
          width: ticket.isReminderDue() ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng trên: Vai trò + Trạng thái vé
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isHost ? _pastelGreen : const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHost ? 'Chủ sân (Host)' : 'Ghép kèo (Joined Player)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isHost ? _green : const Color(0xFF6D28D9),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tên sân & môn thể thao
          Text(
            ticket.venueName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${ticket.subVenueName} • Môn ${ticket.sportName}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 10),

          // Thời gian & Số tiền Escrow
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: AppTheme.textGray,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${ticket.playDate} (${ticket.timeSlots.join(', ')})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatVnd(ticket.depositAmount),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Thông tin trạng thái Escrow
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 15,
                color: AppTheme.accentBlue,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Trạng thái Escrow: ${_translateEscrowStatus(ticket.escrowStatus)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ),
              Text(
                ticket.bookingCode,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (isUpcoming) ...[
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: Key('cancel_ticket_${ticket.bookingId}'),
                    onPressed: () => _handleCancelTicket(ticket),
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: const Text('Hủy & Hoàn Tiền'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(
                        color: _red.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    key: Key('view_qr_${ticket.bookingId}'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketQrDetailScreen(
                            ticket: ticket,
                            provider: _provider,
                            isOfflineMode: _provider.isFromSqliteOffline,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Mã QR Check-in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isCompleted) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketQrDetailScreen(
                        ticket: ticket,
                        provider: _provider,
                        isOfflineMode: _provider.isFromSqliteOffline,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_rounded, size: 16),
                label: const Text('Xem Chứng Từ Vé Đã Check-in'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _translateEscrowStatus(String status) {
    switch (status) {
      case 'Holding':
        return 'Đang tạm giữ (Holding)';
      case 'Settled':
        return 'Đã giải ngân cho sân (Settled)';
      case 'Refunded':
        return 'Đã hoàn tiền vào Ví';
      case 'PartiallyRefunded':
        return 'Hoàn 50% • Trừ phí 50%';
      case 'Forfeited':
        return 'Không hoàn tiền (Hủy sát giờ <2h)';
      default:
        return status;
    }
  }

  Future<void> _handleCancelTicket(TicketModel ticket) async {
    var confirmed = false;
    await showDialog<void>(
      context: context,
      builder: (_) => CancelTicketDialog(
        ticket: ticket,
        onConfirmCancel: () {
          confirmed = true;
        },
      ),
    );
    if (!confirmed || !mounted) return;

    try {
      final result = await _provider.cancelTicket(ticket);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: _green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kết Quả Hủy Vé & Hoàn Tiền',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.policyApplied,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã vé: ${result.bookingCode} • Số dư ví mới: ${_formatVnd(result.newWalletBalance)}',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const Divider(height: 20),
              Text(
                '• Tiền hoàn vào Ví (${result.refundPercentage}%): ${_formatVnd(result.refundAmount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Phí phạt hủy sân: ${_formatVnd(result.penaltyAmount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _red,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã Hiểu'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: _red,
        ),
      );
    }
  }

  void _showTransactionHistorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final txs = _provider.transactions;
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: AppTheme.accentBlue),
                  SizedBox(width: 8),
                  Text(
                    'Lịch Sử Dòng Tiền Escrow',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: txs.isEmpty
                    ? const Center(
                        child: Text('Chưa có lịch sử giao dịch Escrow.'),
                      )
                    : ListView.separated(
                        itemCount: txs.length,
                        separatorBuilder: (_, _) => const Divider(height: 14),
                        itemBuilder: (_, idx) {
                          final tx = txs[idx];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.pastelBlue,
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                color: AppTheme.accentBlue,
                              ),
                            ),
                            title: Text(
                              '${tx.venueName} (${tx.bookingCode})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            subtitle: Text(
                              '${tx.paymentGateway} • ${_translateEscrowStatus(tx.status)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              _formatVnd(tx.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _green,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
