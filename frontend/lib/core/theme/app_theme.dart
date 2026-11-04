import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================================
// 1. PRIMITIVE DESIGN TOKENS (LAYER 1 - RAW VALUES)
// ============================================================================

class AppPrimitives {
  // --- Carbon / Neutral Grays ---
  static const Color carbon950 = Color(0xFF0B0D0E);
  static const Color carbon900 = Color(0xFF111315); // Core dark text
  static const Color carbon850 = Color(0xFF181A1D);
  static const Color carbon800 = Color(0xFF22242A);
  static const Color carbon700 = Color(0xFF2E313A);
  static const Color carbon600 = Color(0xFF4B5563);
  static const Color carbon500 = Color(0xFF6B7280); // Muted text
  static const Color carbon400 = Color(0xFF9CA3AF);
  static const Color carbon300 = Color(0xFFD1D5DB);
  static const Color carbon200 = Color(0xFFE4E4E0); // Structural borders
  static const Color carbon100 = Color(0xFFEBEBE7);
  static const Color carbon50 = Color(0xFFF6F6F3);  // Warm paper canvas

  // --- Athletic Sport Colors ---
  static const Color turf700 = Color(0xFF00753C);
  static const Color turf600 = Color(0xFF008F4A);
  static const Color turf500 = Color(0xFF00A859); // Core athletic green
  static const Color turf400 = Color(0xFF10B981);
  static const Color turf100 = Color(0xFFDCFCE7);

  // --- Energy Sport Accent (60-30-10 Rule: 10% Energetic Focus) ---
  static const Color orange600 = Color(0xFFEA580C);
  static const Color orange500 = Color(0xFFFF5E1F); // SportSpot signature orange
  static const Color orange400 = Color(0xFFFB923C);
  static const Color orange100 = Color(0xFFFFEDD5);

  // --- Status & Feedback Colors ---
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue100 = Color(0xFFEFF6FF);

  static const Color amber600 = Color(0xFFD97706);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber100 = Color(0xFFFEF3C7);

  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose100 = Color(0xFFFFE4E6);

  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo100 = Color(0xFFEDE9FE);

  // --- Spacing Scale (8pt Grid System) ---
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // --- Border Radii ---
  static const double radiusXs = 6.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 999.0;
  static const double radiusFull = 999.0;
}

// ============================================================================
// 2. SEMANTIC DESIGN TOKENS (LAYER 2 - PURPOSE & INTENT)
// ============================================================================

class AppSemantic {
  // 60% Dominant Canvas
  static const Color canvasLight = AppPrimitives.carbon50;
  static const Color canvasDark = Color(0xFF121316);

  // 30% Structural Elements & Content
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = AppPrimitives.carbon850;
  static const Color cardLight = Colors.white;
  static const Color cardDark = AppPrimitives.carbon800;

  static const Color borderLight = AppPrimitives.carbon200;
  static const Color borderDark = AppPrimitives.carbon700;

  static const Color textPrimaryLight = AppPrimitives.carbon900;
  static const Color textPrimaryDark = Color(0xFFF6F6F3);
  static const Color textSecondaryLight = AppPrimitives.carbon500;
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // 10% Accent Interactivity
  static const Color brandPrimary = AppPrimitives.orange500;
  static const Color brandSport = AppPrimitives.turf500;
  static const Color brandAction = AppPrimitives.carbon900;

  // Semantic Status
  static const Color success = AppPrimitives.turf500;
  static const Color warning = AppPrimitives.amber500;
  static const Color error = AppPrimitives.rose500;
  static const Color info = AppPrimitives.blue600;
}

// ============================================================================
// 3. COMPONENT & THEME ARCHITECTURE (LAYER 3 - READY-TO-USE SYSTEM)
// ============================================================================

class AppTheme {
  // Backward-compatible semantic color aliases
  static const Color background = AppSemantic.canvasLight;
  static const Color carbon = AppPrimitives.carbon900;
  static const Color turfGreen = AppPrimitives.turf500;
  static const Color terracotta = Color(0xFFD9532F);
  static const Color borderSubtle = AppSemantic.borderLight;
  static const Color cardBg = AppSemantic.cardLight;
  static const Color textDark = AppPrimitives.carbon900;
  static const Color textGray = AppPrimitives.carbon500;
  static const Color textMuted = AppPrimitives.carbon500;

  static const Color accentBlue = carbon;
  static const Color darkBlue = carbon;
  static const Color pastelBlue = AppPrimitives.carbon100;

  // Dark Theme Colors
  static const Color darkBackground = AppSemantic.canvasDark;
  static const Color darkSurface = AppSemantic.surfaceDark;
  static const Color darkCard = AppSemantic.cardDark;
  static const Color darkBorder = AppSemantic.borderDark;
  static const Color darkTextPrimary = AppSemantic.textPrimaryDark;
  static const Color darkTextSecondary = AppSemantic.textSecondaryDark;

  // Accents
  static const Color accentEmerald = turfGreen;
  static const Color accentAmber = AppPrimitives.amber500;
  static const Color accentRose = terracotta;
  static const Color brandOrange = AppPrimitives.orange500;

  // --- Gradients ---
  static const LinearGradient greenEnergyGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00A859)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeEnergyGradient = LinearGradient(
    colors: [Color(0xFFFF7A3D), Color(0xFFFF5E1F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCarbonGradient = LinearGradient(
    colors: [Color(0xFF1E2128), Color(0xFF111315)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Elevation & Shadows ---
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardElevation => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get floatingElevation => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      spreadRadius: -2,
      offset: const Offset(0, 10),
    ),
  ];

  // --- Typography: Montserrat (Unified SportSpot Design System) ---
  static String? get headingFont => GoogleFonts.montserrat().fontFamily;
  static String? get bodyFont => GoogleFonts.montserrat().fontFamily;

  // Typography scale
  static TextStyle displayStyle({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w900,
    Color? color,
    double? letterSpacing = -0.5,
  }) {
    return TextStyle(
      fontFamily: headingFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? carbon,
      letterSpacing: letterSpacing,
      height: 1.2,
    );
  }

  static TextStyle headingStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: headingFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle bodyStyle({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: bodyFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle captionStyle({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? letterSpacing = 0.1,
  }) {
    return TextStyle(
      fontFamily: bodyFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppPrimitives.carbon500,
      letterSpacing: letterSpacing,
    );
  }

  // ==========================================================================
  // LIGHT THEME CONFIGURATION
  // ==========================================================================
  // --- Standardized Button Style Presets ---
  static ButtonStyle primaryButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    double borderRadius = AppPrimitives.radiusMd,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? carbon,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: 0,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: TextStyle(
        fontFamily: headingFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }

  static ButtonStyle secondaryButtonStyle({
    Color? foregroundColor,
    Color? borderColor,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    double borderRadius = AppPrimitives.radiusMd,
  }) {
    return OutlinedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor ?? carbon,
      side: BorderSide(color: borderColor ?? borderSubtle, width: 1.2),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: TextStyle(
        fontFamily: headingFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static ButtonStyle destructiveButtonStyle({
    bool filled = false,
    EdgeInsetsGeometry? padding,
    double borderRadius = AppPrimitives.radiusMd,
  }) {
    if (filled) {
      return ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: TextStyle(
          fontFamily: headingFont,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return OutlinedButton.styleFrom(
      backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.08),
      foregroundColor: const Color(0xFFDC2626),
      side: BorderSide(
        color: const Color(0xFFDC2626).withValues(alpha: 0.35),
        width: 1.2,
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: TextStyle(
        fontFamily: headingFont,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static ButtonStyle successButtonStyle({
    EdgeInsetsGeometry? padding,
    double borderRadius = AppPrimitives.radiusMd,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppPrimitives.turf500,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: TextStyle(
        fontFamily: headingFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: carbon,
        primary: carbon,
        secondary: turfGreen,
        tertiary: brandOrange,
        surface: background,
        surfaceContainerHighest: AppPrimitives.carbon100,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: bodyFont,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        iconTheme: const IconThemeData(color: carbon),
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          color: carbon,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: carbon,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPrimitives.radiusMd),
          ),
          textStyle: TextStyle(
            fontFamily: headingFont,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: carbon,
          side: const BorderSide(color: borderSubtle, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPrimitives.radiusMd),
          ),
          textStyle: TextStyle(
            fontFamily: headingFont,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPrimitives.radiusSm),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPrimitives.radiusSm),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppPrimitives.radiusSm),
          borderSide: const BorderSide(color: carbon, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontFamily: bodyFont,
          color: AppPrimitives.carbon400,
          fontSize: 13,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPrimitives.radiusMd),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPrimitives.radiusPill),
        ),
        side: const BorderSide(color: borderSubtle, width: 1),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        labelStyle: TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ==========================================================================
  // DARK THEME CONFIGURATION
  // ==========================================================================
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkTextPrimary,
        secondary: turfGreen,
        tertiary: brandOrange,
        surface: darkSurface,
      ),
      fontFamily: bodyFont,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPrimitives.radiusMd),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

// ============================================================================
// 4. MICRO-INTERACTION & POLISH REUSABLE COMPONENTS
// ============================================================================

/// Widget cung cáº¥p hiá»‡u á»©ng co giÃ£n xÃºc giÃ¡c nháº¹ nhÃ ng khi nháº¥n (Tactile Micro-interaction)
class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final HitTestBehavior behavior;

  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) {
        if (widget.onTap != null) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Huy hiá»‡u nhÃ£n tráº¡ng thÃ¡i tinh gá»n (Pill Badge Component)
class AppBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    this.color,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppPrimitives.carbon900;
    final bg = backgroundColor ?? fg.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppPrimitives.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: AppTheme.headingFont,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. DESIGN SYSTEM TOKEN ALIASES (CONVENIENCE SHORTHANDS)
// ============================================================================

/// Há»‡ thá»‘ng nÃºt báº¥m chuáº©n má»±c SportSpot (Unified Button Design System)
enum AppButtonVariant { primary, secondary, destructive, success, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? trailing;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailing,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.borderRadius = 12.0,
    this.padding,
  });

  const AppButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.icon = Icons.cancel_outlined,
    this.trailing,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.borderRadius = 12.0,
    this.padding,
  }) : variant = AppButtonVariant.destructive;

  const AppButton.success({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailing,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.borderRadius = 12.0,
    this.padding,
  }) : variant = AppButtonVariant.success;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailing,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.borderRadius = 12.0,
    this.padding,
  }) : variant = AppButtonVariant.secondary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color fgColor;
    Border? border;

    switch (variant) {
      case AppButtonVariant.destructive:
        bgColor = const Color(0xFFDC2626).withValues(alpha: isDark ? 0.16 : 0.08);
        fgColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        border = Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.4 : 0.28),
          width: 1.2,
        );
        break;
      case AppButtonVariant.success:
        bgColor = AppPrimitives.turf500;
        fgColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bgColor = isDark ? const Color(0xFF1E2128) : Colors.white;
        fgColor = isDark ? Colors.white : AppPrimitives.carbon900;
        border = Border.all(
          color: isDark ? AppPrimitives.carbon700 : AppPrimitives.carbon200,
          width: 1.2,
        );
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = isDark ? Colors.white : AppPrimitives.carbon900;
        break;
      case AppButtonVariant.primary:
        bgColor = isDark ? Colors.white : AppPrimitives.carbon900;
        fgColor = isDark ? AppPrimitives.carbon900 : Colors.white;
        break;
    }

    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fgColor,
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18, color: fgColor),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ],
    );

    return AppPressable(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: height,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}

typedef AppColors = AppPrimitives;

class AppRadius {
  static const double xs = AppPrimitives.radiusXs;
  static const double sm = AppPrimitives.radiusSm;
  static const double md = AppPrimitives.radiusMd;
  static const double lg = AppPrimitives.radiusLg;
  static const double xl = AppPrimitives.radiusXl;
  static const double pill = AppPrimitives.radiusPill;
  static const double full = AppPrimitives.radiusFull;

  static BorderRadius get roundedXs => BorderRadius.circular(xs);
  static BorderRadius get roundedSm => BorderRadius.circular(sm);
  static BorderRadius get roundedMd => BorderRadius.circular(md);
  static BorderRadius get roundedLg => BorderRadius.circular(lg);
  static BorderRadius get roundedXl => BorderRadius.circular(xl);
  static BorderRadius get roundedPill => BorderRadius.circular(pill);
}

class AppShadows {
  static List<BoxShadow> get soft => AppTheme.softShadow;
  static List<BoxShadow> get card => AppTheme.cardElevation;
  static List<BoxShadow> get floating => AppTheme.floatingElevation;
}

class AppSpacing {
  static const double s2 = AppPrimitives.space2;
  static const double s4 = AppPrimitives.space4;
  static const double s6 = AppPrimitives.space6;
  static const double s8 = AppPrimitives.space8;
  static const double s10 = AppPrimitives.space10;
  static const double s12 = AppPrimitives.space12;
  static const double s16 = AppPrimitives.space16;
  static const double s20 = AppPrimitives.space20;
  static const double s24 = AppPrimitives.space24;
  static const double s32 = AppPrimitives.space32;
  static const double s40 = AppPrimitives.space40;
  static const double s48 = AppPrimitives.space48;
}
