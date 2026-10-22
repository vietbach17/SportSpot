import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/booking_model.dart';
import 'match_ui.dart';

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
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Text(
            'Không có khung giờ nào khả dụng',
            style: TextStyle(color: MatchColors.muted, fontSize: 13),
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.48,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selectedSlots.any((s) => s.slotId == slot.slotId);
        final isAvailable = slot.isAvailable;

        // Module 4 visual palette
        final bgColor = isSelected
            ? MatchColors.blue
            : !isAvailable
                ? const Color(0xFFF0F3F7)
                : Colors.white;

        final borderColor = isSelected ? MatchColors.blue : MatchColors.line;

        final timeColor = isSelected
            ? Colors.white
            : !isAvailable
                ? MatchColors.muted.withValues(alpha: .5)
                : MatchColors.ink;

        final priceColor = isSelected
            ? MatchColors.lime
            : !isAvailable
                ? MatchColors.muted.withValues(alpha: .4)
                : MatchColors.muted;

        final priceStr = isAvailable
            ? currencyFormat.format(slot.price)
            : (slot.status == 'Past' ? 'Đã qua' : 'Đã kín');

        return GestureDetector(
          onTap: isAvailable ? () => onSlotToggled(slot) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${slot.startTime} - ${slot.endTime}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: timeColor,
                            letterSpacing: -.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          priceStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: priceColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (slot.isPeak && isAvailable && !isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Vàng',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
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
