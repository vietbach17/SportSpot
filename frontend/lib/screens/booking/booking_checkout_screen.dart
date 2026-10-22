import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/recruitment_form.dart';
import '../main/main_screen.dart';

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _isSubmitting = false;

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
    super.dispose();
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.timer_off_outlined, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Hết thời gian giữ chỗ'),
          ],
        ),
        content: const Text(
          'Đã hết 5 phút giữ chỗ. Các khung giờ có thể đã được mở lại cho người khác. Vui lòng chọn lại khung giờ.',
          style: TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to slots screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Chọn lại giờ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmBooking(BookingProvider provider) async {
    setState(() => _isSubmitting = true);

    try {
      final result = await provider.submitBooking();
      if (mounted) {
        _showSuccessDialog(result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 409) {
          _showConflictDialog(e.message);
        } else {
          _showErrorSnackBar(e.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showConflictDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Trùng lịch đặt sân!'),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Text(
            message.isNotEmpty
                ? message
                : 'Rất tiếc! Khung giờ bạn chọn vừa có người khác đặt trước. Vui lòng chọn khung giờ khác.',
            style: const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to slot grid screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Quay lại chọn giờ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(BookingResultModel result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 48),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đặt Sân Thành Công!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã đặt chỗ: ${result.bookingCode}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 140,
                  height: 140,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: QrImageView(
                    data: result.qrPayload.isNotEmpty ? result.qrPayload : result.bookingCode,
                    version: QrVersions.auto,
                    size: 128,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${result.subVenueName} • ${result.timeSlots.join(', ')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày: ${result.playDate}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Đã đặt cọc:', style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
                          Text(
                            currencyFormat.format(result.depositAmount),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      if (result.remainingBalance > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Còn lại tại sân:', style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
                            Text(
                              currencyFormat.format(result.remainingBalance),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final bookingProvider = context.read<BookingProvider>();
                      bookingProvider.resetBookingState();
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Về Trang Chủ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tóm Tắt & Thanh Toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHoldTimerBanner(provider),
            Padding(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomConfirmBar(provider),
    );
  }

  Widget _buildHoldTimerBanner(BookingProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border(bottom: BorderSide(color: Colors.amber.shade300, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 20, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Text(
            'Giữ chỗ tạm thời trong: ${provider.formattedHoldTime}',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingOverviewCard(BookingProvider provider, VenueDetailModel? venue, SubVenueModel? subVenue) {
    final dateStr = DateFormat('dd/MM/yyyy').format(provider.selectedDate);
    final slotsStr = provider.selectedSlots.map((s) => '${s.startTime}-${s.endTime}').join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.accentBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue?.name ?? 'Sân Thể Thao',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                    ),
                    Text(
                      subVenue?.name ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.accentBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),
          _infoRow(Icons.calendar_today_outlined, 'Ngày thi đấu:', dateStr),
          const SizedBox(height: 8),
          _infoRow(Icons.access_time_rounded, 'Khung giờ:', slotsStr),
          const SizedBox(height: 8),
          _infoRow(Icons.payments_outlined, 'Tiền sân tạm tính:', currencyFormat.format(provider.courtPrice)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textGray),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textGray)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
        ),
      ],
    );
  }

  Widget _buildAccessoriesSection(BookingProvider provider) {
    final services = provider.venueDetail?.services ?? [];
    if (services.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 18, color: AppTheme.accentBlue),
              SizedBox(width: 6),
              Text(
                'Dịch vụ & Phụ kiện đi kèm (F12)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            separatorBuilder: (context, index) => const Divider(height: 16, color: Color(0xFFF3F4F6)),
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
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(item.price),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.accentBlue),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          onPressed: qty > 0 ? () => provider.updateServiceQuantity(item.id, -1) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '$qty',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          onPressed: () => provider.updateServiceQuantity(item.id, 1),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppTheme.accentBlue),
              SizedBox(width: 6),
              Text(
                'Hình thức thanh toán cọc',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _depositOptionCard(
                  title: 'Cọc tối thiểu 30%',
                  percentage: 30,
                  current: provider.depositPercentage,
                  onTap: () => provider.setDepositPercentage(30),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _depositOptionCard(
                  title: 'Thanh toán 100%',
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
    required int percentage,
    required int current,
    required VoidCallback onTap,
  }) {
    final isSelected = current == percentage;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.pastelBlue : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.accentBlue : AppTheme.textGray,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.accentBlue : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdownCard(BookingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bảng kê chi phí',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),
          _costRow('Tiền sân:', currencyFormat.format(provider.courtPrice)),
          const SizedBox(height: 6),
          _costRow('Phụ kiện & dịch vụ:', currencyFormat.format(provider.servicesPrice)),
          const Divider(height: 20, thickness: 1, color: Color(0xFFF3F4F6)),
          _costRow('Tổng tiền đơn:', currencyFormat.format(provider.totalPrice), isBold: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _costRow(
                  'Số tiền cần cọc ngay:',
                  currencyFormat.format(provider.depositAmount),
                  valueColor: const Color(0xFF2E7D32),
                  isBold: true,
                ),
                if (provider.remainingBalance > 0) ...[
                  const SizedBox(height: 6),
                  _costRow(
                    'Số tiền còn lại (trả tại quầy):',
                    currencyFormat.format(provider.remainingBalance),
                    valueColor: AppTheme.textDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _costRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppTheme.textDark : AppTheme.textGray,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14.5 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomConfirmBar(BookingProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tiền cọc thanh toán:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGray),
                  ),
                  Text(
                    currencyFormat.format(provider.depositAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _handleConfirmBooking(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                disabledBackgroundColor: AppTheme.textGray.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'Xác Nhận Đặt',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
