import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Visual language scoped to matchmaking; the other modules retain their theme.
abstract final class MatchColors {
  static const ink = Color(0xFF10243A);
  static const navy = Color(0xFF102D4D);
  static const blue = Color(0xFF2563EB);
  static const lime = Color(0xFFCBF36B);
  static const canvas = Color(0xFFF3F6FA);
  static const muted = Color(0xFF6C7D90);
  static const line = Color(0xFFE5EBF2);
}

class MatchTheme extends StatelessWidget {
  final Widget child;
  const MatchTheme({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: MatchColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MatchColors.blue,
          primary: MatchColors.blue,
          surface: Colors.white,
        ),
        textTheme: base.textTheme.apply(
          fontFamily: 'Roboto',
          bodyColor: MatchColors.ink,
          displayColor: MatchColors.ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: MatchColors.canvas,
          foregroundColor: MatchColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: MatchColors.ink,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: MatchColors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: MatchColors.ink,
            minimumSize: const Size(0, 50),
            side: const BorderSide(color: MatchColors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F9FC),
          labelStyle: const TextStyle(color: MatchColors.muted, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: MatchColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: MatchColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: MatchColors.blue, width: 1.5),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: MatchColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      child: child,
    );
  }
}

class MatchSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  const MatchSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: MatchColors.line),
    ),
    child: child,
  );
}

class MatchPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background, foreground;
  const MatchPill(
    this.label, {
    super.key,
    this.icon,
    this.background = const Color(0xFFEDF3FF),
    this.foreground = MatchColors.blue,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}

class MatchSectionTitle extends StatelessWidget {
  final String title, caption;
  final String? step;
  const MatchSectionTitle(this.title, this.caption, {super.key, this.step});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        if (step != null) ...[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF3FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              step!,
              style: const TextStyle(
                color: MatchColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                style: const TextStyle(
                  fontSize: 12,
                  color: MatchColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

IconData matchSportIcon(int sportId) => switch (sportId) {
  1 => Icons.sports_tennis_rounded,
  2 => Icons.sports_tennis_rounded,
  3 => Icons.sports_soccer_rounded,
  4 => Icons.sports_basketball_rounded,
  _ => Icons.sports_rounded,
};

String matchDay(String date) {
  final parsed = DateTime.tryParse(date);
  return parsed == null ? date : DateFormat('dd/MM/yyyy').format(parsed);
}

String matchStatus(String status) => switch (status) {
  'Open' => 'Đang tuyển',
  'Full' => 'Đã đủ người',
  'Stopped' => 'Đã dừng tuyển',
  'Cancelled' => 'Đã hủy',
  _ => 'Đã đóng',
};

class MatchHero extends StatelessWidget {
  final String eyebrow, title, subtitle;
  final Widget? footer;
  const MatchHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.footer,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MatchColors.navy, Color(0xFF174E7C)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -20,
            bottom: -20,
            width: 235,
            child: IgnorePointer(child: CustomPaint(painter: CourtPainter())),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: MatchColors.lime,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFCADEEF),
                      height: 1.6,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (footer != null) ...[const SizedBox(height: 20), footer!],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Court lines are vector artwork, so they remain sharp on every screen size.
class CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * .22, size.height * .12);
    canvas.rotate(.24);
    final rect = Rect.fromLTWH(0, 0, size.width * .78, size.height * .85);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, line);
    canvas.drawRect(rect.deflate(17), line);
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      line,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top),
      Offset(rect.center.dx, rect.bottom),
      line,
    );
    canvas.drawCircle(rect.center, rect.width * .23, line);
    canvas.drawCircle(
      Offset(rect.width * .74, rect.height * .7),
      7,
      Paint()..color = MatchColors.lime.withValues(alpha: .8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CourtPainter oldDelegate) => false;
}

class MatchEmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final VoidCallback? onRetry;
  const MatchEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.sports_rounded,
    this.onRetry,
  });
  @override
  Widget build(BuildContext context) => MatchSurface(
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFFEDF3FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: MatchColors.blue, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: MatchColors.muted,
            height: 1.6,
            fontSize: 13,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ],
    ),
  );
}
