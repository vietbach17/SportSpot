import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../data/models/booking_model.dart';

class TimeSlotGridWidget extends StatelessWidget {
  final List<VenueSlotModel> slots;
  final List<VenueSlotModel> selectedSlots;
  final ValueChanged<VenueSlotModel> onSlotToggled;

  const TimeSlotGridWidget({
    super.key,
    required this.slots,
    required this.selectedSlots,
    required this.onSlotToggled,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Không có khung giờ nào khả dụng',
            style: TextStyle(color: AppTheme.textGray, fontSize: 14),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selectedSlots.any((s) => s.slotId == slot.slotId);
        final isAvailable = slot.isAvailable;

        // Visual Palette:
        // 1. Selected: Accent Blue / Orange
        // 2. Available: Green
        // 3. Booked / Past: Gray
        Color bgColor;
        Color borderColor;
        Color textColor;
        Color priceColor;

        if (isSelected) {
          bgColor = AppTheme.accentBlue;
          borderColor = AppTheme.accentBlue;
          textColor = Colors.white;
          priceColor = Colors.white.withValues(alpha: 0.9);
        } else if (isAvailable) {
          bgColor = const Color(0xFFF1F8E9);
          borderColor = const Color(0xFFA5D6A7);
          textColor = const Color(0xFF1B5E20);
          priceColor = const Color(0xFF2E7D32);
        } else {
          bgColor = const Color(0xFFF5F5F5);
          borderColor = const Color(0xFFE0E0E0);
          textColor = const Color(0xFF9E9E9E);
          priceColor = const Color(0xFFBDBDBD);
        }

        final priceStr = '${(slot.price / 1000).toStringAsFixed(0)}k';

        return GestureDetector(
          onTap: isAvailable ? () => onSlotToggled(slot) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1.2),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.accentBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${slot.startTime} - ${slot.endTime}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAvailable || isSelected ? priceStr : (slot.status == 'Past' ? 'Đã qua' : 'Đã kín'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: priceColor,
                      ),
                    ),
                  ],
                ),
                if (slot.isPeak && isAvailable && !isSelected)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Vàng',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
