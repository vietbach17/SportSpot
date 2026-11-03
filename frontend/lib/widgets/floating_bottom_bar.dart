import 'package:flutter/material.dart';

class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE4E4E0);
    final bgColor = isDark ? const Color(0xFF191A1E) : Colors.white;

    final items = [
      {'icon': Icons.sports_tennis_rounded, 'label': 'Trang chủ'},
      {'icon': Icons.groups_rounded, 'label': 'Tìm kèo'},
      {'icon': Icons.confirmation_number_rounded, 'label': 'Vé của tôi'},
      {'icon': Icons.account_circle_rounded, 'label': 'Cá nhân'},
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(color: borderColor, width: 1),
          ),
        ),
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom + 4
              : 12,
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? Colors.white12 : const Color(0xFF111315))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
