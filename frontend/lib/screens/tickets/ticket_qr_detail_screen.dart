import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/boarding_pass_ticket.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ticket_model.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/confirm_action_sheet.dart';
import 'cancel_ticket_dialog.dart';
import '../../widgets/brand_header.dart';

class TicketQrDetailScreen extends StatefulWidget {
  final TicketModel ticket;
  final TicketProvider provider;
  final bool isOfflineMode;

  const TicketQrDetailScreen({
    super.key,
    required this.ticket,
    required this.provider,
    this.isOfflineMode = false,
  });

  @override
  State<TicketQrDetailScreen> createState() => _TicketQrDetailScreenState();
}

class _TicketQrDetailScreenState extends State<TicketQrDetailScreen> {
  late TicketModel _currentTicket;
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
  }

  Future<void> _simulateStaffScanCheckIn() async {
    final confirmed = await SportSpotConfirmSheet.show(
      context,
      title: 'Xác nhận Quét QR Điểm danh',
      message: 'Hành động này sẽ giải ngân (Settled) toàn bộ số tiền cọc Escrow cho chủ sân.',
      confirmLabel: 'Xác nhận Điểm danh',
      cancelLabel: 'Hủy',
      icon: Icons.qr_code_scanner_rounded,
      actionType: ConfirmActionType.success,
      infoRows: [
        ConfirmInfoRow(label: 'Mã vé', value: _currentTicket.bookingCode),
        ConfirmInfoRow(label: 'Sân đấu', value: _currentTicket.venueName),
        ConfirmInfoRow(
          label: 'Tiền cọc giải ngân',
          value: CancelTicketDialog.formatVnd(_currentTicket.depositAmount),
          isBold: true,
          valueColor: const Color(0xFF16A34A),
        ),
      ],
    );
    if (confirmed != true) return;

    setState(() => _isCheckingIn = true);
    try {
      final res = await widget.provider.verifyQrCheckIn(_currentTicket.qrPayload);
      if (!mounted) return;
      setState(() {
        _currentTicket = _currentTicket.copyWith(
          status: 'Completed',
          escrowStatus: 'Settled',
          isCheckedIn: true,
        );
        _isCheckingIn = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          content: Text(
            'Check-in thành công vé ${res['bookingCode']}! Tiền cọc Escrow đã được giải ngân (Settled) cho chủ sân.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSettled = _currentTicket.escrowStatus == 'Settled' || _currentTicket.isCheckedIn;
    final isCancelled = _currentTicket.status == 'Cancelled';

    return Scaffold(
      appBar: SportSpotUnifiedHeader(
        screenName: 'Vé Điện Tử QR',
        actions: [
          IconButton(
            tooltip: 'Sao chép chuỗi QR Payload',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _currentTicket.qrPayload));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép chuỗi QR có chữ ký SHA-256!')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                // Huy hiệu Offline Ready SQLite
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.isOfflineMode
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.isOfflineMode
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF22C55E),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isOfflineMode
                            ? Icons.airplanemode_active_rounded
                            : Icons.offline_pin_rounded,
                        color: widget.isOfflineMode
                            ? const Color(0xFFD97706)
                            : const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.isOfflineMode
                              ? 'CHẾ ĐỘ NGOẠI TUYẾN • Vé được đọc trực tiếp từ SQLite trên máy (Không cần mạng)'
                              : 'SẴN SÀNG NGOẠI TUYẾN • Đã lưu bản sao vé vào SQLite trên thiết bị',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: widget.isOfflineMode
                                ? const Color(0xFF92400E)
                                : const Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Thẻ cuống vé QR
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Phần đầu vé
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F172A),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_currentTicket.sportName} • ${_currentTicket.userRoleInMatch == 'JoinedPlayer' ? 'Vãng lai' : 'Đội trưởng'}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _currentTicket.bookingCode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentTicket.venueName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_currentTicket.subVenueName} • ${_currentTicket.address}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Khung hiển thị mã QR Động (qr_flutter)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 22,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSettled
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                              ),
                              child: QrLaserScanLine(
                                isScanning: !isSettled && !isCancelled,
                                child: QrImageView(
                                  data: _currentTicket.qrPayload,
                                  version: QrVersions.auto,
                                  size: 210,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    size: 15,
                                    color: AppTheme.accentBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SHA-256 Checksum: ${_currentTicket.checksumSignature}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currentTicket.qrPayload,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textGray,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const TicketTearDivider(backgroundColor: AppTheme.background, cutoutRadius: 10),

                      // Thông tin chi tiết lịch đá & tiền cọc Escrow
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildDetailItem(
                              'Ngày thi đấu:',
                              _currentTicket.playDate,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailItem(
                              'Khung giờ đã đặt:',
                              _currentTicket.timeSlots.join(', '),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailItem(
                              'Tổng tiền hóa đơn:',
                              CancelTicketDialog.formatVnd(_currentTicket.totalPrice),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailItem(
                              'Tiền cọc Escrow đã đóng:',
                              CancelTicketDialog.formatVnd(_currentTicket.depositAmount),
                              valueColor: AppTheme.accentBlue,
                              isBold: true,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailItem(
                              'Còn thanh toán tại sân:',
                              CancelTicketDialog.formatVnd(_currentTicket.remainingBalance),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailItem(
                              'Trạng thái giữ tiền Escrow:',
                              isSettled
                                  ? 'ĐÃ GIẢI NGÂN (SETTLED)'
                                  : isCancelled
                                      ? 'ĐÃ HOÀN TIỀN / HỦY'
                                      : 'ĐANG TẠM GIỮ AN TOÀN (HOLDING)',
                              valueColor: isSettled
                                  ? const Color(0xFF16A34A)
                                  : isCancelled
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFD97706),
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Nút Giả lập Lễ tân quét mã QR Check-in & Giải ngân Escrow
                if (!isSettled && !isCancelled) ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppPrimitives.turf500,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppPrimitives.turf500.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isCheckingIn ? null : _simulateStaffScanCheckIn,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: _isCheckingIn
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Giả lập Lễ tân Quét QR',
                                      style: TextStyle(
                                        fontFamily: AppTheme.headingFont,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Điểm danh check-in · Giải ngân Escrow',
                                      style: TextStyle(
                                        fontFamily: AppTheme.bodyFont,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.88),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: AppTheme.destructiveButtonStyle(borderRadius: 14),
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        showDialog(
                          context: context,
                          builder: (_) => CancelTicketDialog(
                            ticket: _currentTicket,
                            onConfirmCancel: () async {
                              final cancelRes = await widget.provider.cancelTicket(_currentTicket);
                              if (!mounted) return;
                              setState(() {
                                _currentTicket = _currentTicket.copyWith(status: 'Cancelled');
                              });
                              messenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: AppPrimitives.turf500,
                                  content: Text(
                                    'Hủy vé thành công! Hoàn +${CancelTicketDialog.formatVnd(cancelRes.refundAmount)} vào Ví.',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        'Hủy Vé & Yêu Cầu Hoàn Tiền',
                        style: TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, color: AppTheme.textGray),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
