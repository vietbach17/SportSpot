import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/booking_model.dart';
import '../../../providers/booking_provider.dart';

class TimeSlotGridWidget extends StatelessWidget {
  const TimeSlotGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final slots = bookingProvider.slots;
    final selectedSlots = bookingProvider.selectedSlots;
    final isLoading = bookingProvider.isLoadingSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Chú thích màu sắc (Legend)
        _buildLegend(),
        const SizedBox(height: 12),

        // 2. Trạng thái tải hoặc Lưới ma trận
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 3, color: AppTheme.accentBlue),
                  SizedBox(height: 12),
                  Text('Đang tải lưới khung giờ...', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                ],
              ),
            ),
          )
        else if (slots.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Text('Không có khung giờ khả dụng cho ngày này.', style: TextStyle(color: AppTheme.textGray)),
            ),
          )
        else
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.95,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final isSelected = selectedSlots.any((s) => s.slotId == slot.slotId);
              return _buildSlotCard(context, slot, isSelected, bookingProvider);
            },
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.pastelBlue.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(const Color(0xFF10B981), 'Còn trống'),
            _buildLegendItem(AppTheme.accentBlue, 'Đang chọn (tối đa 3h)'),
            _buildLegendItem(const Color(0xFF9CA3AF), 'Đã kín / Đã qua'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDark),
        ),
      ],
    );
  }

  Widget _buildSlotCard(
    BuildContext context,
    TimeSlotModel slot,
    bool isSelected,
    BookingProvider bookingProvider,
  ) {
    // Xác định màu sắc theo trạng thái
    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget trailingIcon;

    if (isSelected) {
      bgColor = AppTheme.accentBlue;
      borderColor = AppTheme.accentBlue;
      textColor = Colors.white;
      trailingIcon = const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18);
    } else if (slot.isAvailable) {
      bgColor = const Color(0xFFECFDF5); // Xanh lá pastel nhạt
      borderColor = const Color(0xFFA7F3D0);
      textColor = const Color(0xFF065F46);
      trailingIcon = const Icon(Icons.circle_outlined, color: Color(0xFF10B981), size: 16);
    } else {
      // Đã đặt hoặc đã qua
      bgColor = const Color(0xFFF3F4F6); // Xám
      borderColor = const Color(0xFFE5E7EB);
      textColor = const Color(0xFF9CA3AF);
      trailingIcon = Icon(
        slot.isPast ? Icons.history_rounded : Icons.lock_outline_rounded,
        color: const Color(0xFF9CA3AF),
        size: 16,
      );
    }

    return InkWell(
      onTap: () {
        if (!slot.isAvailable && !isSelected) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                slot.isPast
                    ? 'Khung giờ này trong ngày hôm nay đã trôi qua!'
                    : 'Khung giờ này đã được người khác đặt trước!',
              ),
              backgroundColor: Colors.grey.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        final errorMsg = bookingProvider.toggleSlot(slot);
        if (errorMsg != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMsg, style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
              backgroundColor: const Color(0xFFDC2626), // Đỏ cảnh báo
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentBlue.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  slot.timeRange,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                trailingIcon,
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  slot.formattedPrice,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white.withValues(alpha: 0.95) : textColor,
                  ),
                ),
                if (slot.isPeak)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Cao điểm',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFFD97706),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
