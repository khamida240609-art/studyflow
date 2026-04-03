import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color mist = Color(0xFFF9FBFC);
  static const Color midnight = Color(0xFF102033);
  static const Color teal = Color(0xFF4CA7AC);
  static const Color mint = Color(0xFF9FE2D8);
  static const Color coral = Color(0xFFFF7A6B);
  static const Color peach = Color(0xFFF9C7A8);
  static const Color sand = Color(0xFFFFF5F1);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF408D96), Color(0xFF4CA7AC), Color(0xFF7CCFC5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lostGradient = LinearGradient(
    colors: [Color(0xFFFFD5D1), Color(0xFFFF8E86)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient foundGradient = LinearGradient(
    colors: [Color(0xFFD0FFF1), Color(0xFF7BE0BA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      surface: Colors.white,
      surfaceContainer: const Color(0xFFF7F5F4),
      primary: teal,
      secondary: mint,
      tertiary: coral,
    );

    final textTheme = GoogleFonts.manropeTextTheme().copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: 48,
        letterSpacing: -1.2,
        color: midnight,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: 36,
        letterSpacing: -0.9,
        color: midnight,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        color: midnight,
      ),
      titleLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: midnight,
      ),
      titleMedium: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: midnight,
      ),
      titleSmall: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: midnight.withValues(alpha: 0.96),
      ),
      bodyLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: midnight,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: midnight.withValues(alpha: 0.94),
        height: 1.4,
      ),
      bodySmall: GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: midnight.withValues(alpha: 0.82),
        height: 1.35,
      ),
      labelLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: midnight.withValues(alpha: 0.96),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: mist,
      colorScheme: colorScheme,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        indicatorColor: teal.withValues(alpha: 0.14),
        height: 74,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: midnight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F3F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: teal.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: midnight.withValues(alpha: 0.76),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: midnight.withValues(alpha: 0.95),
        ),
        prefixIconColor: midnight.withValues(alpha: 0.82),
        iconColor: midnight.withValues(alpha: 0.82),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: const Color(0xFFF0F3F5),
        selectedColor: teal.withValues(alpha: 0.16),
        labelStyle: textTheme.labelLarge!,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerColor: Colors.black.withValues(alpha: 0.06),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: teal,
        selectionColor: teal.withValues(alpha: 0.22),
        selectionHandleColor: teal,
      ),
    );
  }

  static ThemeData darkTheme() {
    final base = lightTheme();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: mint,
      brightness: Brightness.dark,
      surface: const Color(0xFF0D1623),
      primary: mint,
      secondary: coral,
      tertiary: peach,
    );

    const darkText = Color(0xFFF4FBFC);
    const darkSoftText = Color(0xFFE0ECEF);
    const darkMutedText = Color(0xFFC9D9DD);
    const darkHintText = Color(0xFF9FB5BB);

    final darkTextTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(color: darkText),
      displayMedium: base.textTheme.displayMedium?.copyWith(color: darkText),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(color: darkText),
      titleLarge: base.textTheme.titleLarge?.copyWith(color: darkText),
      titleMedium: base.textTheme.titleMedium?.copyWith(color: darkText),
      titleSmall: base.textTheme.titleSmall?.copyWith(color: darkSoftText),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(color: darkText),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(color: darkSoftText),
      bodySmall: base.textTheme.bodySmall?.copyWith(color: darkMutedText),
      labelLarge: base.textTheme.labelLarge?.copyWith(color: darkText),
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF071018),
      colorScheme: colorScheme,
      textTheme: darkTextTheme,
      appBarTheme: base.appBarTheme.copyWith(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF1E6F74),
        titleTextStyle: darkTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(color: const Color(0xFF102033)),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFF102033),
        hintStyle: darkTextTheme.bodyMedium?.copyWith(color: darkHintText),
        labelStyle: darkTextTheme.bodyLarge?.copyWith(color: darkText),
        prefixIconColor: darkSoftText,
        iconColor: darkSoftText,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: mint.withValues(alpha: 0.9),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: const Color(0xFF0D1623),
        indicatorColor: mint.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          darkTextTheme.labelLarge?.copyWith(color: darkText),
        ),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: const Color(0xFF102033),
        contentTextStyle: darkTextTheme.bodyMedium?.copyWith(color: darkText),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: mint,
        selectionColor: mint.withValues(alpha: 0.24),
        selectionHandleColor: mint,
      ),
    );
  }
}
