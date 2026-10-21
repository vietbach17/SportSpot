import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import 'booking_checkout_screen.dart';
import 'widgets/date_selector_widget.dart';
import 'widgets/time_slot_grid_widget.dart';

class CourtSlotsScreen extends StatelessWidget {
  const CourtSlotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final selectedSlots = bookingProvider.selectedSlots;
    final courtPrice = bookingProvider.courtPrice;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Khung Giờ Đặt Sân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới khung giờ',
            onPressed: () => bookingProvider.loadSlots(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thẻ thông tin cụm sân & Chọn sân con
            _buildVenueHeader(context, bookingProvider),

            const SizedBox(height: 12),

            // 2. Thanh chọn ngày 7 ngày tới
            const DateSelectorWidget(),

            const SizedBox(height: 16),

            // 3. Tiêu đề lưới giờ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 20, color: AppTheme.accentBlue),
                      SizedBox(width: 8),
                      Text(
                        'Khung giờ thi đấu (60 phút/slot)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  if (selectedSlots.isNotEmpty)
                    TextButton(
                      onPressed: () => bookingProvider.clearSelectedSlots(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Bỏ chọn tất cả', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 4. Lưới ma trận khung giờ (Time-slot Grid)
            const TimeSlotGridWidget(),

            const SizedBox(height: 100), // Khoảng trống cho BottomBar
          ],
        ),
      ),
      // 5. Thanh điều khiển dưới đáy (Bottom bar)
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedSlots.isEmpty
                          ? 'Chưa chọn khung giờ'
                          : 'Đã chọn ${selectedSlots.length} slot (${selectedSlots.length} tiếng)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedSlots.isEmpty ? AppTheme.textGray : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedSlots.isEmpty ? 'Tối đa 3 slot liên tiếp' : formatter.format(courtPrice),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: selectedSlots.isEmpty ? AppTheme.textGray : AppTheme.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: selectedSlots.isEmpty
                    ? null
                    : () {
                        // Kích hoạt đồng hồ giữ chỗ 5:00 phút khi qua màn hình checkout
                        bookingProvider.startHoldTimer(
                          onExpired: () {
                            if (context.mounted && Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Hết hạn 5 phút giữ chỗ! Vui lòng chọn lại khung giờ.'),
                                  backgroundColor: Color(0xFFDC2626),
                                ),
                              );
                            }
                          },
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BookingCheckoutScreen()),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: selectedSlots.isEmpty ? 0 : 4,
                ),
                child: Row(
                  children: [
                    Text(
                      'Tiếp tục',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selectedSlots.isEmpty ? Colors.grey.shade500 : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: selectedSlots.isEmpty ? Colors.grey.shade500 : Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueHeader(BuildContext context, BookingProvider bookingProvider) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.accentBlue, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookingProvider.venueName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textGray),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bookingProvider.address,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 12),

          // Chọn sân con (SubVenues)
          const Text(
            'Chọn sân thi đấu:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: bookingProvider.availableSubVenues.map((sv) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildSubVenueChip(sv.name, sv.id, bookingProvider),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubVenueChip(String name, int subId, BookingProvider bookingProvider) {
    final isSelected = bookingProvider.subVenueId == subId;
    return ChoiceChip(
      label: Text(name),
      selected: isSelected,
      onSelected: (_) => bookingProvider.switchSubVenue(subId, name),
      selectedColor: AppTheme.accentBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textDark,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
        ),
      ),
      showCheckmark: false,
    );
  }
}
