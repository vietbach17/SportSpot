import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../main/main_screen.dart';

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final isHoldExpired = bookingProvider.isHoldExpired;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          bookingProvider.stopHoldTimer();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Xác Nhận Đặt Sân'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              bookingProvider.stopHoldTimer();
              Navigator.pop(context);
            },
          ),
        ),
        body: isHoldExpired
            ? _buildExpiredView(context)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Đồng hồ đếm ngược giữ chỗ 5 phút (Hold Timer)
                    _buildHoldTimerBanner(bookingProvider),

                    const SizedBox(height: 16),

                    // 2. Tóm tắt sân & khung giờ đã chọn
                    _buildCourtSummaryCard(bookingProvider),

                    const SizedBox(height: 16),

                    // 3. Phụ kiện & Dịch vụ đi kèm (F12)
                    _buildServicesCard(bookingProvider),

                    const SizedBox(height: 16),

                    // 4. Tuyển vãng lai / Ghép kèo (Chuẩn bị cho Module 4)
                    _buildMatchmakingCard(bookingProvider),

                    const SizedBox(height: 16),

                    // 5. Tùy chọn đặt cọc (30% hoặc 100%)
                    _buildDepositOptionsCard(bookingProvider),

                    const SizedBox(height: 16),

                    // 6. Bảng chi tiết thanh toán
                    _buildPaymentSummaryCard(bookingProvider),

                    const SizedBox(height: 24),

                    // 7. Nút bấm Xác nhận đặt sân
                    _buildSubmitButton(context, bookingProvider),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHoldTimerBanner(BookingProvider provider) {
    final isUrgent = provider.holdSecondsLeft < 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFEE2E2) : AppTheme.pastelBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent ? const Color(0xFFEF4444) : AppTheme.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: isUrgent ? const Color(0xFFDC2626) : AppTheme.accentBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khung giờ đang được giữ chỗ tạm thời:',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUrgent ? const Color(0xFF991B1B) : AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  provider.formattedHoldTimer,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isUrgent ? const Color(0xFFDC2626) : AppTheme.accentBlue,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isUrgent ? 'Sắp hết hạn!' : '5 phút',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isUrgent ? const Color(0xFFDC2626) : AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatVietnameseDate(DateTime date) {
    const dayNames = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    final dayName = dayNames[date.weekday];
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$dayName, $d/$m/${date.year}';
  }

  Widget _buildCourtSummaryCard(BookingProvider provider) {
    final dateFormatted = _formatVietnameseDate(provider.selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stadium_rounded, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${provider.venueName} - ${provider.subVenueName}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event_rounded, size: 16, color: AppTheme.textGray),
              const SizedBox(width: 6),
              Text(
                dateFormatted,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 12),
          const Text(
            'Khung giờ đã chọn:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          ...provider.selectedSlots.map(
            (slot) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        slot.timeRange,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                      if (slot.isPeak) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Cao điểm',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    slot.formattedPrice,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tạm tính tiền sân:', style: TextStyle(fontSize: 13, color: AppTheme.textGray)),
              Text(
                _currencyFormat.format(provider.courtPrice),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.accentBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard(BookingProvider provider) {
    final services = provider.services;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppTheme.accentBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Dịch vụ & Phụ kiện đi kèm (F12)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (services.isEmpty)
            const Text('Không có dịch vụ đi kèm.', style: TextStyle(color: AppTheme.textGray, fontSize: 13))
          else
            ...services.map((svc) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            svc.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                          ),
                          Text(
                            '${svc.formattedPrice} / ${svc.type == 'Rental' ? 'lượt thuê' : 'món'}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: svc.quantity > 0
                              ? () => provider.updateServiceQuantity(svc.serviceId, -1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          iconSize: 22,
                          color: svc.quantity > 0 ? AppTheme.accentBlue : Colors.grey.shade400,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            '${svc.quantity}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => provider.updateServiceQuantity(svc.serviceId, 1),
                          icon: const Icon(Icons.add_circle_rounded),
                          iconSize: 22,
                          color: AppTheme.accentBlue,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMatchmakingCard(BookingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.groups_rounded, color: AppTheme.accentBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tuyển vãng lai / Ghép kèo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                ],
              ),
              Switch(
                value: provider.isOpenMatch,
                activeTrackColor: AppTheme.accentBlue,
                onChanged: (val) => provider.toggleOpenMatch(val),
              ),
            ],
          ),
          if (provider.isOpenMatch) ...[
            const SizedBox(height: 10),
            const Text(
              'Tự động tính chi phí chia đều cho mỗi thành viên:',
              style: TextStyle(fontSize: 12, color: AppTheme.textGray),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mỗi người đóng dự kiến:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    _currencyFormat.format(provider.costPerPerson),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.accentBlue),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepositOptionsCard(BookingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: AppTheme.accentBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Hình thức đặt cọc giữ chỗ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDepositChip(
                  label: 'Cọc 30%',
                  sublabel: 'Thanh toán cọc trước',
                  percent: 30,
                  provider: provider,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDepositChip(
                  label: 'Toàn phần 100%',
                  sublabel: 'Thanh toán đủ ngay',
                  percent: 100,
                  provider: provider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepositChip({
    required String label,
    required String sublabel,
    required int percent,
    required BookingProvider provider,
  }) {
    final isSelected = provider.depositPercentage == percent;
    return InkWell(
      onTap: () => provider.setDepositPercentage(percent),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.pastelBlue : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.accentBlue : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppTheme.accentBlue : AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard(BookingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Tiền sân:', _currencyFormat.format(provider.courtPrice)),
          _buildSummaryRow('Tiền phụ kiện:', _currencyFormat.format(provider.servicesPrice)),
          Divider(height: 16, color: AppTheme.borderColor),
          _buildSummaryRow('Tổng cộng:', _currencyFormat.format(provider.totalPrice), isBold: true),
          const SizedBox(height: 6),
          _buildSummaryRow(
            'Số tiền thanh toán cọc (${provider.depositPercentage}%):',
            _currencyFormat.format(provider.depositAmount),
            valueColor: AppTheme.accentBlue,
            isBold: true,
          ),
          if (provider.remainingBalance > 0)
            _buildSummaryRow(
              'Số tiền thanh toán tại sân:',
              _currencyFormat.format(provider.remainingBalance),
              valueColor: const Color(0xFFD97706),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? AppTheme.textDark : AppTheme.textGray,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, BookingProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: provider.isSubmitting ? null : () => _handleBookingSubmit(context, provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: provider.isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Đang xác nhận đặt sân...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              )
            : Text(
                'Xác nhận đặt sân & Thanh toán (${_currencyFormat.format(provider.depositAmount)})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Future<void> _handleBookingSubmit(BuildContext context, BookingProvider provider) async {
    try {
      final result = await provider.submitBooking();
      if (!context.mounted) return;

      if (result != null) {
        _showSuccessDialog(context, result);
      }
    } catch (e) {
      if (!context.mounted) return;
      final errorMsg = e.toString();

      // Kiểm tra lỗi 409 Conflict (Trùng lịch thi đấu)
      final isConflict = errorMsg.contains('409') || errorMsg.contains('vừa có người khác đặt');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isConflict ? Icons.warning_amber_rounded : Icons.error_outline_rounded,
                color: const Color(0xFFDC2626),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                isConflict ? 'Trùng Lịch Đặt Sân!' : 'Lỗi Đặt Sân',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Text(
              isConflict
                  ? 'Rất tiếc! Một trong các khung giờ bạn chọn vừa có khách khác đặt trước trên hệ thống (HTTP 409 Conflict).\n\nVui lòng quay lại và chọn khung giờ khác.'
                  : errorMsg,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // đóng dialog
                if (isConflict) {
                  Navigator.pop(context); // quay lại lưới chọn giờ
                  provider.loadSlots(); // tải lại dữ liệu mới nhất
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isConflict ? 'Chọn lại khung giờ' : 'Đã hiểu'),
            ),
          ],
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, BookingResponseModel booking) {
    final provider = context.read<BookingProvider>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đặt Sân Thành Công!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mã đặt sân: ${booking.bookingCode}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.accentBlue),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.venueName} - ${booking.subVenueName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                ),
                const SizedBox(height: 12),

                // Render mã QR check-in với kích thước ràng buộc tuyệt đối
                if (booking.qrPayload.isNotEmpty)
                  Container(
                    width: 130,
                    height: 130,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Center(
                      child: QrImageView(
                        data: booking.qrPayload,
                        version: QrVersions.auto,
                        size: 114.0,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelBlue.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiền cọc đã thanh toán:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(
                        booking.formattedDepositAmount,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.accentBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                provider.resetBookingState();
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Về Trang Chủ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_rounded, size: 72, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'Hết Hạn Giữ Chỗ!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đã quá 5 phút kể từ khi bạn bắt đầu đặt sân. Để đảm bảo công bằng cho người chơi khác, các khung giờ đã được mở lại.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textGray, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Quay lại chọn khung giờ', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
