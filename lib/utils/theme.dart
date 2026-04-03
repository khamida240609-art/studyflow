import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color bg = Color(0xFF0D0D0F);
  static const Color bg2 = Color(0xFF141417);
  static const Color bg3 = Color(0xFF1C1C21);
  static const Color bg4 = Color(0xFF252530);
  static const Color accent = Color(0xFF6C63FF);
  static const Color accent2 = Color(0xFFA78BFA);
  static const Color green = Color(0xFF22C55E);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF0EFF5);
  static const Color textSecondary = Color(0xFF9B9AB0);
  static const Color textTertiary = Color(0xFF5C5B70);
  static const Color border = Color(0xFF2A2A38);
  static const Color border2 = Color(0xFF353548);
  static const Color lightBg = Color(0xFFF7F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1B1A23);
  static const Color lightSecondary = Color(0xFF5E5B73);

  static Color secondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondary : lightSecondary;

  static Color tertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textTertiary : lightSecondary;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent2,
        surface: bg2,
        error: red,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg3,
        hintStyle: const TextStyle(color: textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bg2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accent2,
        surface: lightSurface,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.light().textTheme,
      ).apply(bodyColor: lightText, displayColor: lightText),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: lightText, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: lightText),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Color(0xFFE6E3F2)),
        ),
      ),
    );
  }
}
