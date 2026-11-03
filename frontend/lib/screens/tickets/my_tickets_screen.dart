import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/boarding_pass_ticket.dart';
import '../../widgets/shimmer_skeleton.dart';
import 'qr_scanner_screen.dart';
import 'package:provider/provider.dart';
import 'ticket_qr_detail_screen.dart';
import 'cancel_ticket_dialog.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/bounce_interaction.dart';

class MyTicketsScreen extends StatefulWidget {
  final Object? repository;

  const MyTicketsScreen({super.key, this.repository});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  TicketProvider? _localProvider;
  TicketProvider? _boundProvider;
  TicketProvider get _provider => _localProvider ?? _boundProvider!;
  int _selectedTabIndex = 0; // 0: Tất cả, 1: Sắp tới, 2: Đã xong, 3: Đã hủy

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _localProvider = TicketProvider(
        repository: widget.repository is TicketRepository
            ? (widget.repository as TicketRepository)
            : null,
      );
      _localProvider!.addListener(_onProviderChanged);
      _localProvider!.loadTickets();
    }
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _localProvider?.removeListener(_onProviderChanged);
    _localProvider?.dispose();
    super.dispose();
  }

  String _formatVnd(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return '${buffer.toString()} đ';
  }

  List<TicketModel> get _filteredTickets {
    switch (_selectedTabIndex) {
      case 1:
        return _provider.upcomingTickets;
      case 2:
        return _provider.completedTickets;
      case 3:
        return _provider.cancelledTickets;
      default:
        return _provider.tickets;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localProvider != null) {
      _boundProvider = _localProvider;
    } else {
      try {
        _boundProvider = Provider.of<TicketProvider>(context, listen: true);
      } catch (_) {
        _localProvider = TicketProvider();
        _boundProvider = _localProvider;
      }
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111216) : const Color(0xFFF7F8FA);
    final cardColor = isDark ? const Color(0xFF191A20) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFF6F6F3) : const Color(0xFF111315);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    final tickets = _filteredTickets;
    final reminders = _provider.upcomingReminders;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: SportSpotUnifiedHeader(
        screenName: 'Vé Thi Đấu & Lịch Sân',
        showBackButton: false,
        actions: [
          IconButton(
            key: const Key('open_qr_scanner_btn'),
            icon: Icon(Icons.qr_code_scanner_rounded, color: textColor),
            tooltip: 'Quét vé QR (Lễ tân / Chủ sân)',
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
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            tooltip: 'Làm mới danh sách',
            onPressed: () => _provider.loadTickets(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _provider.loadTickets(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Escrow Wallet & Offline Control Bar
                _buildWalletAndOfflineBar(cardColor, borderColor, textColor, mutedColor),
                const SizedBox(height: 14),

                // 2. Pre-match 2h Reminder Banner
                if (reminders.isNotEmpty) ...[
                  _buildPreMatchReminderBanner(reminders.first),
                  const SizedBox(height: 14),
                ],

                // 3. Tab Filter Pills
                _buildFilterTabs(cardColor, borderColor, textColor, mutedColor),
                const SizedBox(height: 16),

                // 4. Ticket List
                if (_provider.isLoading && _provider.tickets.isEmpty)
                  Column(
                    children: const [
                      SkeletonCard(height: 160),
                      SizedBox(height: 12),
                      SkeletonCard(height: 160),
                    ],
                  )
                else if (tickets.isEmpty)
                  _buildEmptyState(cardColor, borderColor, textColor, mutedColor)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tickets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return _buildTicketCard(
                        ticket: ticket,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletAndOfflineBar(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VÍ HOÀN TIỀN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: mutedColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatVnd(_provider.walletBalance),
                      key: const Key('wallet_balance_text'),
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: borderColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESCROW TẠM GIỮ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: mutedColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatVnd(_provider.escrowHoldingTotal),
                      key: const Key('escrow_holding_text'),
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111315),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _provider.isOfflineMode ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                    size: 16,
                    color: _provider.isOfflineMode ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    key: const Key('offline_mode_switch'),
                    value: _provider.isOfflineMode,
                    activeThumbColor: const Color(0xFFD97706),
                    onChanged: (val) => _provider.toggleOfflineMode(val),
                  ),
                ],
              ),
            ],
          ),
          if (_provider.isFromSqliteOffline) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_bolt_rounded, size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đang mở vé từ bộ nhớ SQLite Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreMatchReminderBanner(TicketModel ticket) {
    return Container(
      key: const Key('pre_match_reminder_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFDE68A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_on_rounded, size: 18, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NHẮC LỊCH ĐẤU • SẮP DIỄN RA (< 2.5 GIỜ)',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ticket.venueName} • ${ticket.timeSlots.join(', ')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(Color cardColor, Color borderColor, Color textColor, Color mutedColor) {
    final tabs = [
      'Tất cả (${_provider.tickets.length})',
      'Sắp tới (${_provider.upcomingTickets.length})',
      'Đã đấu (${_provider.completedTickets.length})',
      'Đã hủy (${_provider.cancelledTickets.length})',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: BounceTap(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF111315) : cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF111315) : borderColor,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  tabs[index],
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: AppTheme.headingFont,
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTicketCard({
    required TicketModel ticket,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111315) : const Color(0xFFF6F6F3);
    final isCheckedIn = ticket.isCheckedIn || ticket.status == 'Completed';
    final isCancelled = ticket.status == 'Cancelled';

    Color statusBg = const Color(0xFFEDF3FF);
    Color statusFg = const Color(0xFF111315);
    String statusText = 'KÝ QUỸ TẠM GIỮ';

    if (isCheckedIn) {
      statusBg = const Color(0xFFDCFCE7);
      statusFg = const Color(0xFF16A34A);
      statusText = 'ĐÃ VÀO SÂN (QUYẾT TOÁN)';
    } else if (isCancelled) {
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFFDC2626);
      statusText = 'ĐÃ HỦY (HOÀN TIỀN)';
    }

    return Container(
      key: Key('ticket_card_${ticket.bookingId}'),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TicketQrDetailScreen(
                  ticket: ticket,
                  provider: _provider,
                  isOfflineMode: _provider.isOfflineMode,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Sport badge + Escrow status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${ticket.sportName.toUpperCase()} • ${ticket.userRoleInMatch == 'JoinedPlayer' ? 'VÃNG LAI' : 'ĐỘI TRƯỞNG'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusFg,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Venue & Subvenue
                Text(
                  ticket.venueName,
                  style: TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ticket.subVenueName} • ${ticket.address}',
                  style: TextStyle(fontSize: 12.5, color: mutedColor),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 12),

                // Date & Time metadata row
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: mutedColor),
                    const SizedBox(width: 5),
                    Text(
                      ticket.playDate,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.access_time_rounded, size: 14, color: mutedColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        ticket.timeSlots.join(', '),
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TicketTearDivider(backgroundColor: bgColor, cutoutRadius: 8),
                const SizedBox(height: 10),

                // Bottom row: Booking code + View QR Pass CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ticket.bookingCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.2,
                        color: Color(0xFF111315),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCancelled && !isCheckedIn) ...[
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => CancelTicketDialog(
                                  ticket: ticket,
                                  onConfirmCancel: () async {
                                    final res = await _provider.cancelTicket(ticket);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppPrimitives.turf500,
                                        content: Text(
                                          'Hủy vé thành công! Hoàn +${CancelTicketDialog.formatVnd(res.refundAmount)} vào Ví.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.16 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.4 : 0.28),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cancel_outlined,
                                    size: 13,
                                    color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Hủy đặt',
                                    style: TextStyle(
                                      fontFamily: AppTheme.headingFont,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E313A) : const Color(0xFF111315),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 15, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                'Mở Vé QR',
                                style: TextStyle(
                                  fontFamily: AppTheme.headingFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white70),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color cardColor, Color borderColor, Color textColor, Color mutedColor) {
    return LivelyEmptyState(
      icon: Icons.confirmation_number_outlined,
      title: 'Chưa có vé nào trong mục này',
      subtitle: 'Đặt sân và nhận vé điện tử kèm mã QR điểm danh tự động.',
      actionLabel: 'Làm mới vé',
      onAction: () => _provider.loadTickets(),
    );
  }
}