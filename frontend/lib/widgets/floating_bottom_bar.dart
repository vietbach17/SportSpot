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
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE2E4EB);
    final bgColor = isDark ? const Color(0xFF181A20) : Colors.white;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final items = [
      {
        'icon': Icons.sports_tennis_rounded,
        'activeIcon': Icons.sports_tennis_rounded,
        'label': 'Trang chủ',
      },
      {
        'icon': Icons.groups_outlined,
        'activeIcon': Icons.groups_rounded,
        'label': 'Tìm kèo',
      },
      {
        'icon': Icons.confirmation_number_outlined,
        'activeIcon': Icons.confirmation_number_rounded,
        'label': 'Vé của tôi',
      },
      {
        'icon': Icons.account_circle_outlined,
        'activeIcon': Icons.account_circle_rounded,
        'label': 'Cá nhân',
      },
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding + 4 : 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: isDark ? 0.94 : 0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
              blurRadius: 28,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF00A859).withValues(alpha: isDark ? 0.08 : 0.04),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(16),
                  splashColor: const Color(0xFF00A859).withValues(alpha: 0.1),
                  highlightColor: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF272B35) : const Color(0xFF111315))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (isDark ? Colors.black : const Color(0xFF111315))
                                    .withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (isSelected ? item['activeIcon'] : item['icon']) as IconData,
                          size: 20,
                          color: isSelected
                              ? (isDark ? const Color(0xFF00E676) : Colors.white)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: -0.1,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
