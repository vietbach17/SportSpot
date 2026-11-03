import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Overlapping athletic player avatars with initial badges and overflow indicator.
class StackedAvatars extends StatelessWidget {
  final int joinedCount;
  final int totalNeeded;
  final double size;
  final int maxVisible;

  const StackedAvatars({
    super.key,
    required this.joinedCount,
    required this.totalNeeded,
    this.size = 28,
    this.maxVisible = 3,
  });

  static const List<Color> _avatarColors = [
    Color(0xFF00A859), // Turf Green
    Color(0xFF2563EB), // Royal Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
  ];

  static const List<String> _playerInitials = ['VN', 'TU', 'HA', 'LK', 'DP', 'QU'];

  @override
  Widget build(BuildContext context) {
    if (joinedCount <= 0) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: size * 0.55,
          color: const Color(0xFF94A3B8),
        ),
      );
    }

    final visibleCount = joinedCount.clamp(0, maxVisible);
    final overflowCount = joinedCount - visibleCount;

    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size + (visibleCount - 1) * (size * 0.65) + (overflowCount > 0 ? (size * 0.7) : 0),
            height: size,
            child: Stack(
              children: [
                for (int i = 0; i < visibleCount; i++)
                  Positioned(
                    left: i * (size * 0.65),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: _avatarColors[i % _avatarColors.length],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _playerInitials[i % _playerInitials.length],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (overflowCount > 0)
                  Positioned(
                    left: visibleCount * (size * 0.65),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111315),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '+$overflowCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Smooth athletic progress bar with gradient fill and pill ratio tag.
class AthleticProgressBar extends StatelessWidget {
  final int joined;
  final int total;
  final double height;
  final Color? activeColor;
  final Color? trackColor;

  const AthleticProgressBar({
    super.key,
    required this.joined,
    required this.total,
    this.height = 7,
    this.activeColor,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (joined / total).clamp(0.0, 1.0);
    final isFull = joined >= total;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultActive = isFull ? const Color(0xFF16A34A) : const Color(0xFF00A859);
    final fill = activeColor ?? defaultActive;
    final track = trackColor ?? (isDark ? const Color(0xFF282B36) : const Color(0xFFE5E7EB));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      isFull ? 'Kèo đã đủ người' : 'Đang ghép: $joined/$total người',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${(ratio * 100).toInt()}%',
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: fill,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            width: double.infinity,
            color: track,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      fill.withValues(alpha: 0.8),
                      fill,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
