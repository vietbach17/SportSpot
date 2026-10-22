import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/network/api_client.dart';
import '../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/match_ui.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    borderRadius: BorderRadius.circular(16),
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
                    borderRadius: BorderRadius.circular(14),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final bookingProvider = context.read<BookingProvider>();
                      bookingProvider.resetBookingState();
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
        appBar: AppBar(
          title: const Text('Tóm tắt & Đặt sân'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBEB),
        border: Border(bottom: BorderSide(color: Color(0xFFFDE68A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Giữ chỗ tạm thời: ${provider.formattedHoldTime}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFFB45309),
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
                  borderRadius: BorderRadius.circular(12),
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
                      borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(16),
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
              color: const Color(0xFFEDF3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
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
