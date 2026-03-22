import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF0D6EBE);
  static const Color darkBlue = Color(0xFF0A4F8A);
  static const Color deepNavy = Color(0xFF062D52);
  static const Color lightBlue = Color(0xFF4A9BE8);
  static const Color accentCyan = Color(0xFF17C3B2);
  static const Color surfaceLight = Color(0xFFF5F7FA);
  static const Color surfaceDark = Color(0xFF1A1F2E);
  static const Color cardDark = Color(0xFF242938);
  static const Color white = Colors.white;
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF6C7293);
  static const Color freeGreen = Color(0xFF27AE60);
  static const Color paidOrange = Color(0xFFE67E22);

  // ← font بناءً على اللغة
  static TextTheme _textTheme(bool isArabic) {
    if (isArabic) {
      return GoogleFonts.cairoTextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      );
    } else {
      return TextTheme(
        displayLarge: const TextStyle(fontFamily: 'Figtree', color: textDark),
        displayMedium: const TextStyle(fontFamily: 'Figtree', color: textDark),
        displaySmall: const TextStyle(fontFamily: 'Figtree', color: textDark),
        headlineLarge: const TextStyle(fontFamily: 'Figtree', color: textDark),
        headlineMedium: const TextStyle(fontFamily: 'Figtree', color: textDark),
        headlineSmall: const TextStyle(
            fontFamily: 'Figtree',
            color: textDark,
            fontWeight: FontWeight.w700),
        titleLarge: const TextStyle(
            fontFamily: 'Figtree',
            color: textDark,
            fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(
            fontFamily: 'Figtree',
            color: textDark,
            fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(
            fontFamily: 'Figtree',
            color: textDark,
            fontWeight: FontWeight.w500),
        bodyLarge: const TextStyle(fontFamily: 'Figtree', color: textDark),
        bodyMedium: const TextStyle(fontFamily: 'Figtree', color: textDark),
        bodySmall: const TextStyle(fontFamily: 'Figtree', color: textMuted),
        labelLarge: const TextStyle(
            fontFamily: 'Figtree',
            color: textDark,
            fontWeight: FontWeight.w600),
        labelMedium: const TextStyle(fontFamily: 'Figtree', color: textDark),
        labelSmall: const TextStyle(fontFamily: 'Figtree', color: textMuted),
      );
    }
  }

  static String _fontFamily(bool isArabic) =>
      isArabic ? GoogleFonts.cairo().fontFamily! : 'Figtree';

  static ThemeData getTheme({bool isArabic = true}) {
    final fontFamily = _fontFamily(isArabic);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentCyan,
        surface: surfaceLight,
        error: errorRed,
      ),
      scaffoldBackgroundColor: surfaceLight,
      textTheme: _textTheme(isArabic),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: TextStyle(fontFamily: fontFamily, color: textMuted),
        hintStyle: TextStyle(fontFamily: fontFamily, color: textMuted),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentCyan,
        foregroundColor: white,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkBlue,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // backward compat
  static ThemeData get lightTheme => getTheme(isArabic: true);
}
