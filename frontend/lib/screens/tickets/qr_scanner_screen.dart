import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ticket_provider.dart';

class QrScannerScreen extends StatefulWidget {
  final TicketProvider provider;

  const QrScannerScreen({super.key, required this.provider});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final TextEditingController _qrController = TextEditingController();
  bool _isVerifying = false;
  Map<String, dynamic>? _scanSuccessResult;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    final upcoming = widget.provider.upcomingTickets;
    if (upcoming.isNotEmpty) {
      _qrController.text = upcoming.first.qrPayload;
    }
  }

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _verifyQrPayload() async {
    final payload = _qrController.text.trim();
    if (payload.isEmpty) {
      setState(() {
        _scanError = 'Vui lòng nhập hoặc chọn chuỗi QR Payload cần quét';
        _scanSuccessResult = null;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _scanError = null;
      _scanSuccessResult = null;
    });

    try {
      final res = await widget.provider.verifyQrCheckIn(payload);
      if (!mounted) return;
      setState(() {
        _scanSuccessResult = res;
        _isVerifying = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanError = e.toString().replaceAll('Exception: ', '');
        _isVerifying = false;
      });
    }
  }

  void _tamperCurrentPayload() {
    final current = _qrController.text.trim();
    if (current.isEmpty) return;
    final lastChar = current[current.length - 1];
    final replacement = lastChar == 'F' ? '0' : 'F';
    setState(() {
      _qrController.text = current.substring(0, current.length - 1) + replacement;
      _scanSuccessResult = null;
      _scanError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = widget.provider.upcomingTickets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quầy Lễ Tân: Quét QR Check-in'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelBlue.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 36,
                        color: AppTheme.accentBlue,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xác thực chữ ký SHA-256 & Giải ngân Escrow',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Khi quét mã QR hợp lệ, hệ thống tự động chuyển trạng thái cọc từ Holding sang Settled (giải ngân cho chủ sân).',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (upcoming.isNotEmpty) ...[
                  const Text(
                    'Chọn nhanh vé sắp diễn ra để thử quét:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: upcoming.map((t) {
                      return ActionChip(
                        avatar: const Icon(Icons.confirmation_number_outlined, size: 16),
                        label: Text('${t.bookingCode} (${t.venueName})'),
                        onPressed: () {
                          setState(() {
                            _qrController.text = t.qrPayload;
                            _scanError = null;
                            _scanSuccessResult = null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Chuỗi dữ liệu mã QR (QR Payload):',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _qrController,
                  maxLines: 2,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'SPORTSPOT|SP-XXXXXX|1|Host|CHECKSUM',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _tamperCurrentPayload,
                        icon: const Icon(Icons.warning_amber_rounded, size: 18),
                        label: const Text('Thử sửa giả mạo QR (Test lỗi Checksum)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isVerifying ? null : _verifyQrPayload,
                    icon: const Icon(Icons.verified_rounded),
                    label: Text(
                      _isVerifying ? 'Đang kiểm tra chữ ký SHA-256...' : 'Xác thực QR & Check-in Nhận Sân',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Hiển thị kết quả lỗi nếu QR bị sửa đổi
                if (_scanError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gpp_bad_rounded, color: Color(0xFFDC2626), size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TỪ CHỐI CHECK-IN (CẢNH BÁO BẢO MẬT)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFDC2626),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _scanError!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Hiển thị kết quả thành công & Giải ngân Escrow
                if (_scanSuccessResult != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'CHECK-IN THÀNH CÔNG • ĐÃ GIẢI NGÂN ESCROW',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF15803D),
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22),
                        Text('Mã đơn: ${_scanSuccessResult!['bookingCode']}'),
                        const SizedBox(height: 4),
                        Text('Vai trò vé: ${_scanSuccessResult!['role']}'),
                        const SizedBox(height: 4),
                        Text('Sân nhận: ${_scanSuccessResult!['subVenueName']} (${_scanSuccessResult!['venueName']})'),
                        const SizedBox(height: 4),
                        const Text(
                          'Trạng thái tiền cọc: Holding -> Settled (Đã chuyển về ví chủ sân)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
