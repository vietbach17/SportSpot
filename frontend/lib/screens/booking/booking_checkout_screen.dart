import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/network/api_client.dart';
import '../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/match_ui.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/recruitment_form.dart';
import '../main/main_screen.dart';
import 'booking_detail_screen.dart';

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _isSubmitting = false;
  BookingProvider? _bookingProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bookingProvider = context.read<BookingProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookingProvider>();
      provider.startHoldTimer(
        onExpire: () {
          if (mounted) {
            _showTimeoutDialog();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _bookingProvider?.cancelHoldTimer();
    super.dispose();
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_off_outlined,
                  color: Color(0xFFD97706),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hết thời gian giữ chỗ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MatchColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đã hết 5 phút giữ chỗ. Các khung giờ có thể đã được mở lại cho người khác. Vui lòng chọn lại khung giờ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: MatchColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Chọn lại khung giờ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyablePaymentRow(String label, String value, VoidCallback? onCopy, bool isDark, Color valColor, Color labelColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: labelColor)),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valColor,
              ),
            ),
            if (onCopy != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.copy_rounded, size: 14, color: labelColor),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _handleConfirmBooking(BookingProvider provider) async {
    final ticketProvider = context.read<TicketProvider>();
    final auth = context.read<AuthProvider>();
    final isGuest = auth.isGuest || auth.currentUser == null;
    final int userWallet = isGuest ? 0 : ticketProvider.walletBalance;
    final int deposit = provider.depositAmount;
    final bool canPayWallet = userWallet >= deposit;

    int selectedMethod = canPayWallet ? 0 : 1; // 0: Ví SportSpot, 1: VietQR Chuyển khoản
    bool isPaying = false;

    final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    final transferCode = 'SPORTCOC${provider.selectedSubVenue?.id ?? 1}$randomSuffix';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final sheetBg = isDark ? const Color(0xFF1A1C22) : Colors.white;
          final textC = isDark ? const Color(0xFFF6F6F3) : const Color(0xFF111315);
          final mutedC = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
          final borderC = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);

          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield_rounded, color: Color(0xFF16A34A), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thanh Toán Cọc Escrow',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textC,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Khoản cọc được SportSpot tạm giữ bảo vệ đến khi check-in',
                              style: TextStyle(fontSize: 12, color: mutedC),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Booking Mini Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF22242B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderC),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sân đặt: ', style: TextStyle(fontSize: 12.5, color: mutedC)),
                            Expanded(
                              child: Text(
                                '${provider.venueDetail?.name ?? "Sân đấu"} - ${provider.selectedSubVenue?.name ?? ""}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textC),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Khung giờ: ', style: TextStyle(fontSize: 12.5, color: mutedC)),
                            Expanded(
                              child: Text(
                                '${provider.selectedSlots.map((s) => "${s.startTime}-${s.endTime}").join(", ")} (${DateFormat("dd/MM/yyyy").format(provider.selectedDate)})',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textC),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Tiền cọc cần thanh toán (30%):',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textC),
                              ),
                            ),
                            Text(
                              currencyFormat.format(deposit),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Còn lại thanh toán tại sân:', style: TextStyle(fontSize: 12, color: mutedC)),
                            Text(
                              currencyFormat.format(provider.remainingBalance),
                              style: TextStyle(fontSize: 12, color: mutedC, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'CHỌN PHƯƠNG THỨC THANH TOÁN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: mutedC, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),

                  // Option 1: Quét mã QR VietQR / Chuyển khoản (MoMo, Banking)
                  GestureDetector(
                    onTap: () => setModalState(() => selectedMethod = 1),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selectedMethod == 1
                            ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                            : (isDark ? const Color(0xFF22242B) : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedMethod == 1 ? const Color(0xFF16A34A) : borderC,
                          width: selectedMethod == 1 ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: 1,
                            groupValue: selectedMethod,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (v) => setModalState(() => selectedMethod = v!),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A859).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF00A859), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(child: Text('Quét mã QR VietQR / MoMo / VNPay', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textC))),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Khuyên dùng', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('Chuyển khoản liên ngân hàng miễn phí, đối soát tức thì', style: TextStyle(fontSize: 11.5, color: mutedC)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 0: Ví điện tử SportSpot
                  GestureDetector(
                    onTap: canPayWallet ? () => setModalState(() => selectedMethod = 0) : null,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selectedMethod == 0
                            ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                            : (isDark ? const Color(0xFF22242B) : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedMethod == 0 ? const Color(0xFF16A34A) : borderC,
                          width: selectedMethod == 0 ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: 0,
                            groupValue: selectedMethod,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: canPayWallet ? (v) => setModalState(() => selectedMethod = v!) : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFF59E0B), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ví điện tử SportSpot (${currencyFormat.format(userWallet)})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: canPayWallet ? textC : mutedC,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  canPayWallet
                                      ? 'Trừ trực tiếp số dư ví và sinh vé ngay lập tức'
                                      : 'Số dư không đủ để cọc (cần thêm ${currencyFormat.format(deposit - userWallet)})',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: canPayWallet ? mutedC : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // If Option 1 (VietQR) selected -> Show QR Code Box
                  if (selectedMethod == 1) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF22242B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderC),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'QUÉT MÃ ĐỂ THANH TOÁN TIỀN CỌC',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF16A34A), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderC),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: QrImageView(
                              data: '00020101021238540010A00000072701240006970422011003394570960208QRIBFTTA5303704540${deposit.toString().length}' + deposit.toString() + '5802VN62${transferCode.length + 4}080${transferCode.length}' + transferCode + '6304',
                              version: QrVersions.auto,
                              size: 160,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildCopyablePaymentRow('Ngân hàng', 'MBBank (Quân Đội)', null, isDark, textC, mutedC),
                          const SizedBox(height: 8),
                          _buildCopyablePaymentRow('Số tài khoản', '0339457096', () {
                            Clipboard.setData(const ClipboardData(text: '0339457096'));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép số tài khoản!')));
                          }, isDark, textC, mutedC),
                          const SizedBox(height: 8),
                          _buildCopyablePaymentRow('Chủ tài khoản', 'PHẠM VIỆT BÁCH', null, isDark, textC, mutedC),
                          const SizedBox(height: 8),
                          _buildCopyablePaymentRow('Số tiền cọc', currencyFormat.format(deposit), null, isDark, const Color(0xFF16A34A), mutedC, isBold: true),
                          const SizedBox(height: 8),
                          _buildCopyablePaymentRow('Nội dung CK', transferCode, () {
                            Clipboard.setData(ClipboardData(text: transferCode));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép nội dung chuyển khoản!')));
                          }, isDark, const Color(0xFF2563EB), mutedC, isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isPaying
                          ? null
                          : () async {
                              final isGuestUser = Provider.of<AuthProvider>(context, listen: false).isGuest;
                              setModalState(() => isPaying = true);
                              try {
                                final result = await provider.submitBooking();
                                if (selectedMethod == 0) {
                                  ticketProvider.deductWallet(deposit);
                                }
                                ticketProvider.addConfirmedBookingTicket(
                                  bookingId: result.bookingId,
                                  bookingCode: result.bookingCode,
                                  venueName: result.venueName,
                                  subVenueName: result.subVenueName,
                                  sportName: provider.venueDetail?.sportName ?? 'Thể thao',
                                  address: provider.venueDetail?.address ?? 'TP. Hồ Chí Minh',
                                  playDate: result.playDate,
                                  timeSlots: result.timeSlots,
                                  courtPrice: result.totalPrice - result.depositAmount,
                                  servicesPrice: 0,
                                  totalPrice: result.totalPrice,
                                  depositAmount: result.depositAmount,
                                  remainingBalance: result.remainingBalance,
                                  qrPayload: result.qrPayload,
                                  paymentGateway: selectedMethod == 0 ? 'SportSpotWallet' : 'VietQR_MBBank',
                                  userRoleInMatch: isGuestUser ? 'Khách ghép' : 'Đội trưởng',
                                );
                                if (mounted) {
                                  Navigator.pop(modalCtx);
                                  _showSuccessDialog(result);
                                }
                              } on ApiException catch (e) {
                                setModalState(() => isPaying = false);
                                if (mounted) {
                                  Navigator.pop(modalCtx);
                                  if (e.statusCode == 409) {
                                    _showConflictDialog(e.message);
                                  } else {
                                    _showErrorSnackBar(e.message);
                                  }
                                }
                              } catch (e) {
                                setModalState(() => isPaying = false);
                                if (mounted) {
                                  _showErrorSnackBar('Lỗi đặt sân: $e');
                                }
                              }
                            },
                      icon: isPaying
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Icon(selectedMethod == 0 ? Icons.payment_rounded : Icons.check_circle_outline_rounded, size: 20),
                      label: Text(
                        isPaying
                            ? 'Đang xác thực giao dịch Escrow...'
                            : (selectedMethod == 0
                                ? 'Thanh Toán Cọc Qua Ví (-${currencyFormat.format(deposit)})'
                                : 'Tôi Đã Chuyển Khoản Xong (Xác Nhận Đặt Sân)'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showConflictDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Trùng lịch đặt sân!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MatchColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.isNotEmpty
                    ? message
                    : 'Rất tiếc! Khung giờ bạn chọn vừa có người khác đặt trước. Vui lòng chọn khung giờ khác.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: MatchColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Quay lại chọn giờ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
      ),
    );
  }

  void _showSuccessDialog(BookingResultModel result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 44,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Đặt Sân Thành Công!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: MatchColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.bookingCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: MatchColors.blue,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 150,
                  height: 150,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: MatchColors.line),
                  ),
                  child: QrImageView(
                    data: result.qrPayload.isNotEmpty
                        ? result.qrPayload
                        : result.bookingCode,
                    version: QrVersions.auto,
                    size: 134,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${result.subVenueName} • ${result.timeSlots.join(', ')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MatchColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày: ${result.playDate}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: MatchColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MatchColors.line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Đã đặt cọc:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: MatchColors.muted,
                            ),
                          ),
                          Text(
                            currencyFormat.format(result.depositAmount),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      if (result.remainingBalance > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Còn lại tại sân:',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: MatchColors.muted,
                              ),
                            ),
                            Text(
                              currencyFormat.format(result.remainingBalance),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: MatchColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Text(
                        'Đã cọc thành công: ${currencyFormat.format(result.depositAmount)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('view_booking_detail_button'),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Xem Chi Tiết Đơn Đặt Sân'),
                    onPressed: () {
                      final bookingProvider = context.read<BookingProvider>();
                      final List<Map<String, dynamic>> serviceDetails = [];
                      final allServices = bookingProvider.venueDetail?.services ?? [];
                      bookingProvider.selectedServices.forEach((serviceId, qty) {
                        if (qty > 0) {
                          final svc = allServices.firstWhere(
                            (s) => s.id == serviceId,
                            orElse: () => VenueServiceModel(
                              id: serviceId,
                              name: 'Dịch vụ phụ kiện',
                              type: 'Service',
                              price: 0,
                              stockQuantity: 0,
                            ),
                          );
                          serviceDetails.add({
                            'name': svc.name,
                            'quantity': qty,
                            'price': svc.price * qty,
                          });
                        }
                      });
                      bookingProvider.resetBookingState();
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(
                            booking: result,
                            serviceDetails: serviceDetails,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('view_my_tickets_button'),
                    icon: const Icon(Icons.confirmation_number_rounded, size: 18),
                    label: const Text('Xem Vé Của Tôi (Mã QR Check-in)'),
                    onPressed: () {
                      final bookingProvider = context.read<BookingProvider>();
                      bookingProvider.resetBookingState();
                      context.read<TicketProvider>().loadTickets();
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const MainScreen(initialIndex: 2),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      final bookingProvider = context.read<BookingProvider>();
                      bookingProvider.resetBookingState();
                      try {
                        context.read<TicketProvider>().loadTickets();
                      } catch (_) {}
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const MainScreen(initialIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Về Trang Chủ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final venue = provider.venueDetail;
    final subVenue = provider.selectedSubVenue;

    return MatchTheme(
      child: Scaffold(
        appBar: const SportSpotUnifiedHeader(
          screenName: 'Tóm tắt & Đặt sân',
        ),
        bottomNavigationBar: _buildBottomConfirmBar(provider),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHoldTimerBanner(provider),
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBookingOverviewCard(provider, venue, subVenue),
                        const SizedBox(height: 16),
                        _buildAccessoriesSection(provider),
                        const SizedBox(height: 16),
                        // Module 4 Dual Matchmaking Integration
                        RecruitmentForm(
                          courtPrice: provider.courtPrice,
                          onChanged: (recruitmentVal) {
                            provider.updateRecruitment(recruitmentVal);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDepositSelector(provider),
                        const SizedBox(height: 16),
                        _buildCostBreakdownCard(provider),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoldTimerBanner(BookingProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF38BDF8)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'THỜI GIAN GIỮ CHỖ CÒN LẠI: ${provider.formattedHoldTime}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingOverviewCard(
    BookingProvider provider,
    VenueDetailModel? venue,
    SubVenueModel? subVenue,
  ) {
    final dateStr = DateFormat('dd/MM/yyyy').format(provider.selectedDate);
    final slotsStr = provider.selectedSlots
        .map((s) => '${s.startTime}-${s.endTime}')
        .join(', ');

    return MatchSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MatchSectionTitle(
            'Thông tin đặt sân',
            'Chi tiết sân đấu và khung giờ bạn đã chọn.',
            step: '01',
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  matchSportIcon(venue?.sportId ?? 1),
                  color: MatchColors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue?.name ?? 'Sân Thể Thao',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: MatchColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subVenue?.name ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MatchColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: MatchColors.line),
          const SizedBox(height: 14),
          _infoRow(Icons.calendar_today_outlined, 'Ngày thi đấu:', dateStr),
          const SizedBox(height: 8),
          _infoRow(Icons.access_time_rounded, 'Khung giờ:', slotsStr),
          const SizedBox(height: 8),
          _infoRow(
            Icons.payments_outlined,
            'Tiền sân tạm tính:',
            currencyFormat.format(provider.courtPrice),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessoriesSection(BookingProvider provider) {
    final services = provider.venueDetail?.services ?? [];
    if (services.isEmpty) return const SizedBox.shrink();

    return MatchSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MatchSectionTitle(
            'Dịch vụ & Phụ kiện',
            'Tùy chọn thuê vợt, mua bóng, nước giải khát...',
            step: '02',
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 20, color: MatchColors.line),
            itemBuilder: (context, index) {
              final item = services[index];
              final qty = provider.selectedServices[item.id] ?? 0;

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: MatchColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(item.price),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: MatchColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MatchColors.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: qty > 0
                              ? () => provider.updateServiceQuantity(item.id, -1)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$qty',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: MatchColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              provider.updateServiceQuantity(item.id, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDepositSelector(BookingProvider provider) {
    return MatchSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MatchSectionTitle(
            'Hình thức đặt cọc',
            'Chọn mức đặt cọc tối thiểu để hoàn tất giữ chỗ.',
            step: '04',
          ),
          Row(
            children: [
              Expanded(
                child: _depositOptionCard(
                  title: 'Cọc tối thiểu 30%',
                  subtitle: 'Trả 70% còn lại tại sân',
                  percentage: 30,
                  current: provider.depositPercentage,
                  onTap: () => provider.setDepositPercentage(30),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _depositOptionCard(
                  title: 'Thanh toán 100%',
                  subtitle: 'Thanh toán toàn bộ trước',
                  percentage: 100,
                  current: provider.depositPercentage,
                  onTap: () => provider.setDepositPercentage(100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _depositOptionCard({
    required String title,
    required String subtitle,
    required int percentage,
    required int current,
    required VoidCallback onTap,
  }) {
    final isSelected = current == percentage;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDF3FF) : const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? MatchColors.blue : MatchColors.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? MatchColors.blue : MatchColors.muted,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected ? MatchColors.blue : MatchColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? MatchColors.blue : MatchColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdownCard(BookingProvider provider) {
    return MatchSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MatchSectionTitle(
            'Bảng kê chi phí',
            'Chi tiết các khoản phí và số tiền cần thanh toán.',
            step: '05',
          ),
          _costRow('Tiền sân:', currencyFormat.format(provider.courtPrice)),
          const SizedBox(height: 8),
          _costRow(
            'Phụ kiện & dịch vụ:',
            currencyFormat.format(provider.servicesPrice),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: MatchColors.line),
          const SizedBox(height: 12),
          _costRow(
            'Tổng tiền đơn:',
            currencyFormat.format(provider.totalPrice),
            isBold: true,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MatchColors.line),
            ),
            child: Column(
              children: [
                _costRow(
                  'Số tiền cần cọc ngay:',
                  currencyFormat.format(provider.depositAmount),
                  valueColor: MatchColors.blue,
                  isBold: true,
                ),
                if (provider.remainingBalance > 0) ...[
                  const SizedBox(height: 8),
                  _costRow(
                    'Số tiền còn lại (trả tại quầy):',
                    currencyFormat.format(provider.remainingBalance),
                    valueColor: MatchColors.ink,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _costRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? MatchColors.ink : MatchColors.muted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ?? MatchColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomConfirmBar(BookingProvider provider) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: MatchColors.line)),
        ),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tiền cọc cần thanh toán',
                        style: TextStyle(
                          fontSize: 13,
                          color: MatchColors.muted,
                        ),
                      ),
                    ),
                    Text(
                      currencyFormat.format(provider.depositAmount),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: MatchColors.ink,
                        letterSpacing: -.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleConfirmBooking(provider),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(
                      _isSubmitting
                          ? 'Đang xác nhận đặt sân...'
                          : 'Xác nhận đặt sân · Cọc ${provider.depositPercentage}%',
                    ),
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
