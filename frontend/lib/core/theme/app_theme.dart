import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Nike Training / Strava Editorial Design System
  static const Color background = Color(0xFFF6F6F3); // Sáng ấm (warm paper)
  static const Color carbon = Color(0xFF111315); // Carbon đậm cho chữ & nút chính
  static const Color turfGreen = Color(0xFF00A859); // Xanh sân đấu thể thao
  static const Color terracotta = Color(0xFFD9532F); // Cam đất nhấn
  static const Color borderSubtle = Color(0xFFE4E4E0); // Viền mảnh 1px cấu trúc
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF111315);
  static const Color textGray = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF6B7280);

  // Backward-compatible semantic aliases mapped to Nike/Strava palette
  static const Color accentBlue = carbon;
  static const Color darkBlue = carbon;
  static const Color pastelBlue = Color(0xFFEBEBE7);

  // Dark Theme Colors (Carbon Athletic Slate)
  static const Color darkBackground = Color(0xFF121316);
  static const Color darkSurface = Color(0xFF191A1E);
  static const Color darkCard = Color(0xFF22242A);
  static const Color darkBorder = Color(0xFF2E313A);
  static const Color darkTextPrimary = Color(0xFFF6F6F3);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Accents
  static const Color accentEmerald = turfGreen;
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = terracotta;

  // Modern Mobile-First Gradients & Shadows
  static const LinearGradient greenEnergyGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00A859)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCarbonGradient = LinearGradient(
    colors: [Color(0xFF1E2128), Color(0xFF111315)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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

  // Soft & Friendly Modern Typography: Nunito (Headings/Titles/Buttons/Prices) + Be Vietnam Pro (Body/Interface)
  static String? get headingFont => GoogleFonts.nunito().fontFamily;
  static String? get bodyFont => GoogleFonts.beVietnamPro().fontFamily;

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

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: carbon,
        primary: carbon,
        secondary: turfGreen,
        surface: background,
        surfaceContainerHighest: const Color(0xFFEBEBE7),
      ),
      scaffoldBackgroundColor: background,
      fontFamily: GoogleFonts.beVietnamPro().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: carbon),
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          color: carbon,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: carbon,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: carbon, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkTextPrimary,
        secondary: turfGreen,
        surface: darkSurface,
      ),
      fontFamily: GoogleFonts.beVietnamPro().fontFamily,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
    );
  }
}
