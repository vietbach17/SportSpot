import 'package:flutter/material.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../providers/ticket_provider.dart';
import 'ticket_qr_detail_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  final Object? repository;

  const MyTicketsScreen({super.key, this.repository});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  bool isReminded = false;
  late final TicketProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = TicketProvider(
      repository: widget.repository is TicketRepository
          ? (widget.repository as TicketRepository)
          : null,
    );
    _provider.addListener(_onProviderChanged);
    _provider.loadTickets();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tickets = _provider.tickets;
    final activeTicket = tickets.isNotEmpty ? tickets.first : null;
    final reminders = _provider.upcomingReminders;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Escrow Wallet & Offline Control Bar
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242834) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VÍ HOÀN TIỀN',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatVnd(_provider.walletBalance),
                              key: const Key('wallet_balance_text'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 32, color: Colors.grey.withOpacity(0.2)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESCROW TẠM GIỮ',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatVnd(_provider.escrowHoldingTotal),
                              key: const Key('escrow_holding_text'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _provider.isOfflineMode ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                              size: 16,
                              color: _provider.isOfflineMode ? Colors.orange : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Switch(
                              key: const Key('offline_mode_switch'),
                              value: _provider.isOfflineMode,
                              activeColor: const Color(0xFFD97706),
                              onChanged: (val) => _provider.toggleOfflineMode(val),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_provider.isFromSqliteOffline) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.offline_bolt_rounded, size: 14, color: Colors.orange),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Đang mở vé từ bộ nhớ SQLite Offline',
                                style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Pre-match 2h Reminder Banner
              if (reminders.isNotEmpty)
                Container(
                  key: const Key('pre_match_reminder_banner'),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_on_rounded, color: Colors.amber, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nhắc lịch: Trận đấu sắp diễn ra trong 2 giờ!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${reminders.first.venueName} • ${reminders.first.timeSlots.join(", ")}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const Text('My Passes & Bookings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text(
                'Contactless gate entry passes and team split invoices.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Active Digital Pass
              Container(
                key: Key('ticket_card_${activeTicket?.bookingId ?? 501}'),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242834) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pass Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  activeTicket != null ? 'VERIFIED MATCH PASS (${activeTicket.escrowStatus.toUpperCase()})' : 'VERIFIED MATCH PASS',
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                activeTicket?.venueName ?? 'Cau Giay Pro Arena',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeTicket != null
                                    ? '${activeTicket.subVenueName} • ${activeTicket.sportName}'
                                    : 'Court 1 • Premium Maple Wood',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E212B) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: Text(
                            activeTicket?.bookingCode ?? 'SP-7842',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),

                    // Countdown & PIN
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E212B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.timer_rounded, size: 18, color: Colors.amber),
                              SizedBox(width: 8),
                              Text(
                                'Starts in 2h 45m',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            activeTicket != null ? 'ID: #${activeTicket.bookingId}' : 'Gate PIN: 4829',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Contactless QR Box
                    GestureDetector(
                      onTap: () {
                        if (activeTicket != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketQrDetailScreen(
                                ticket: activeTicket,
                                provider: _provider,
                                isOfflineMode: _provider.isOfflineMode,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 170,
                        height: 170,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 140,
                            color: Color(0xFF181A22),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Hold near turnstile optical reader for entry',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 22),

                    // Match Schedule detail
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E212B) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('DATE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(activeTicket?.playDate ?? 'Today (Fri)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          Column(
                            children: [
                              const Text('HOURS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(activeTicket != null ? activeTicket.timeSlots.join(', ') : '18:30 - 20:30', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          const Column(
                            children: [
                              Text('DURATION', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('120 Mins', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Team Split Breakdown
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E212B) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Team Split (3/4 Paid)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('60,000 VND / player', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ],
                          ),
                          const Divider(height: 18),
                          _buildMemberRow('You (Nam Nguyen)', 'Paid ✓', const Color(0xFF10B981)),
                          const SizedBox(height: 6),
                          _buildMemberRow('Minh Trí', 'Paid ✓', const Color(0xFF10B981)),
                          const SizedBox(height: 6),
                          _buildMemberRow('Hoàng Nam', 'Paid ✓', const Color(0xFF10B981)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Minh Tuan', style: TextStyle(fontSize: 12)),
                              Row(
                                children: [
                                  Text(
                                    isReminded ? 'Reminded 🔔' : 'Pending ⏳',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isReminded ? Colors.amber : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!isReminded) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => isReminded = true);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Payment reminder sent to Minh Tuan!')),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('Remind', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Directions & Help row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Navigation to 180 Xuân Thủy, Cầu Giấy...')),
                        );
                      },
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text('Get Directions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Calling Arena Reception (+84 24 3833 ...) ')),
                        );
                      },
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                      label: const Text('Contact Arena', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberRow(String name, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(fontSize: 12)),
        Text(status, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
