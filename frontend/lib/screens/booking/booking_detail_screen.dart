import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/ticket_model.dart';
import '../../widgets/match_ui.dart';
import '../main/main_screen.dart';
import '../matches/match_checkout_screen.dart';
import '../tickets/cancel_ticket_dialog.dart';
import '../tickets/ticket_share_helper.dart';
import '../../providers/ticket_provider.dart';
import 'package:provider/provider.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingResultModel? booking;
  final TicketModel? ticket;
  final List<Map<String, dynamic>>? serviceDetails;

  const BookingDetailScreen({
    super.key,
    this.booking,
    this.ticket,
    this.serviceDetails,
  });

  String _formatVnd(int amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount).replaceAll(',', '.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    final code = booking?.bookingCode ?? ticket?.bookingCode ?? 'SP-882410';
    final venueName = booking?.venueName ?? ticket?.venueName ?? 'Cụm Sân SportSpot';
    final subVenueName = booking?.subVenueName ?? ticket?.subVenueName ?? 'Sân 1';
    final sportName = booking?.sportName ?? ticket?.sportName ?? 'Cầu lông';
    final address = booking?.address ?? ticket?.address ?? 'Hà Nội';
    final playDate = booking?.playDate ?? ticket?.playDate ?? '2026-10-26';
    final timeSlots = booking?.timeSlots ?? ticket?.timeSlots ?? ['18:00-20:00'];
    final courtPrice = booking?.courtPrice ?? ticket?.courtPrice ?? 240000;
    final servicesPrice = booking?.servicesPrice ?? ticket?.servicesPrice ?? 0;
    final totalPrice = booking?.totalPrice ?? ticket?.totalPrice ?? (courtPrice + servicesPrice);
    final depositAmount = booking?.depositAmount ?? ticket?.depositAmount ?? (totalPrice ~/ 2);
    final remainingBalance = booking?.remainingBalance ?? ticket?.remainingBalance ?? (totalPrice - depositAmount);
    final qrPayload = booking?.qrPayload.isNotEmpty == true
        ? booking!.qrPayload
        : (ticket?.qrPayload.isNotEmpty == true ? ticket!.qrPayload : code);
    final isCheckedIn = booking?.isCheckedIn ?? ticket?.isCheckedIn ?? false;
    final status = booking?.status ?? ticket?.status ?? 'Upcoming';

    return MatchTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi Tiết Đơn Đặt Sân'),
          actions: [
            IconButton(
              tooltip: 'Sao chép mã đơn',
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã sao chép mã đơn $code')),
                );
              },
            ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 1. Thẻ mã đơn & trạng thái
                MatchSurface(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MÃ ĐẶT SÂN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: MatchColors.muted,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                code,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: MatchColors.blue,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusBadge(status, isCheckedIn),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 16, color: Color(0xFF16A34A)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Khoản cọc được SportSpot Escrow bảo vệ an toàn cho đến khi check-in.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Thẻ Thông tin sân & Thời gian thi đấu
                MatchSurface(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: MatchColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.stadium_rounded,
                              color: MatchColors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  venueName,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: MatchColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$subVenueName • Môn $sportName',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: MatchColors.blue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: MatchColors.line),
                      const SizedBox(height: 14),
                      _detailRow(Icons.place_outlined, 'Địa chỉ cụ thể:', address),
                      const SizedBox(height: 10),
                      _detailRow(Icons.calendar_month_outlined, 'Ngày thi đấu:', playDate),
                      const SizedBox(height: 10),
                      _detailRow(
                        Icons.access_time_rounded,
                        'Khung giờ thi đấu:',
                        timeSlots.join(', '),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Thẻ Mã QR Check-in Nhận Sân
                MatchSurface(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'MÃ QR CHECK-IN TẠI SÂN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: MatchColors.muted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: MatchColors.line, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrPayload,
                          version: QrVersions.auto,
                          size: 190,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isCheckedIn
                            ? '✓ ĐÃ CHECK-IN XÁC NHẬN NHẬN SÂN'
                            : 'Xuất trình mã này cho nhân viên quầy lễ tân khi đến sân để nhận sân và giải ngân cọc.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCheckedIn ? const Color(0xFF16A34A) : MatchColors.muted,
                          fontWeight: isCheckedIn ? FontWeight.w800 : FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Bảng Kê Chi Phí Chi Tiết (Cost Breakdown Table)
                MatchSurface(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 20, color: MatchColors.blue),
                          SizedBox(width: 8),
                          Text(
                            'BẢNG KÊ CHI PHÍ MINH BẠCH',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: MatchColors.ink,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: MatchColors.line),
                      const SizedBox(height: 12),

                      // Tiền thuê sân
                      _costLine(
                        'Tiền thuê sân (${timeSlots.length} ca x ${_formatVnd(courtPrice ~/ (timeSlots.isEmpty ? 1 : timeSlots.length))})',
                        _formatVnd(courtPrice),
                      ),

                      // Dịch vụ phụ kiện nếu có
                      if (servicesPrice > 0 || (serviceDetails != null && serviceDetails!.isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        if (serviceDetails != null)
                          ...serviceDetails!.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _costLine(
                                '• ${s['name']} (x${s['quantity']})',
                                _formatVnd(s['price'] as int),
                                isSubItem: true,
                              ),
                            ),
                          )
                        else
                          _costLine(
                            'Dịch vụ & Phụ kiện đi kèm',
                            _formatVnd(servicesPrice),
                          ),
                      ],

                      const Divider(height: 20, color: MatchColors.line),

                      // Tổng tiền hóa đơn
                      _costLine(
                        'Tổng giá trị đơn đặt',
                        _formatVnd(totalPrice),
                        isBold: true,
                        fontSize: 14.5,
                      ),
                      const SizedBox(height: 8),

                      // Tiền cọc đã trả
                      _costLine(
                        'Tiền cọc Escrow đã thanh toán:',
                        '- ${_formatVnd(depositAmount)}',
                        valueColor: const Color(0xFF16A34A),
                        isBold: true,
                      ),

                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: remainingBalance > 0
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFEDFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: remainingBalance > 0
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              remainingBalance > 0
                                  ? 'CÒN THANH TOÁN TẠI QUẦY:'
                                  : 'ĐÃ THANH TOÁN ĐỦ 100%:',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: remainingBalance > 0
                                    ? const Color(0xFF92400E)
                                    : const Color(0xFF15803D),
                              ),
                            ),
                            Text(
                              _formatVnd(remainingBalance),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: remainingBalance > 0
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Secondary Action Row: Chia sẻ vé & Hủy cọc
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Chia Sẻ Vé'),
                        onPressed: () {
                          TicketShareHelper.shareTicket(
                            context,
                            bookingCode: code,
                            venueName: venueName,
                            subVenueName: subVenueName,
                            sportName: sportName,
                            playDate: playDate,
                            timeSlots: timeSlots,
                            status: status,
                            escrowStatus: isCheckedIn ? 'Settled' : 'Holding',
                          );
                        },
                      ),
                    ),
                    if (ticket != null && !isCheckedIn && status == 'Upcoming') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                          label: const Text('Hủy Sân (Hoàn Cọc)', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => CancelTicketDialog(
                                ticket: ticket!,
                                onConfirmCancel: () async {
                                  Navigator.of(context).pop();
                                  try {
                                    final tp = context.read<TicketProvider>();
                                    await tp.cancelTicket(ticket!);
                                  } catch (_) {}
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFF2563EB),
                                      content: Text('Đã hủy đặt sân và hoàn cọc về Ví theo chính sách Escrow!'),
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Nút thao tác
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.group_add_rounded, size: 18),
                        label: const Text('Mở Tuyển Ghép Kèo'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MatchCheckoutScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.home_rounded, size: 18),
                        label: const Text('Về Trang Chủ'),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainScreen(initialIndex: 0),
                            ),
                            (route) => false,
                          );
                        },
                      ),
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

  Widget _buildStatusBadge(String status, bool isCheckedIn) {
    Color bg = const Color(0xFFEDF3FF);
    Color fg = MatchColors.blue;
    String label = 'Đã Xác Nhận Cọc';

    if (isCheckedIn) {
      bg = const Color(0xFFEDFDF5);
      fg = const Color(0xFF16A34A);
      label = 'Đã Check-in Sân';
    } else if (status == 'Cancelled') {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFDC2626);
      label = 'Đã Hủy';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: MatchColors.muted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: MatchColors.muted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MatchColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _costLine(
    String label,
    String value, {
    bool isBold = false,
    bool isSubItem = false,
    Color? valueColor,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isSubItem ? MatchColors.muted : (isBold ? MatchColors.ink : MatchColors.muted),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ?? MatchColors.ink,
          ),
        ),
      ],
    );
  }
}
