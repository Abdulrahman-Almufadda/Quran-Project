import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Quran-style colors
  static const Color ayahNumberGold = Color(0xFFB8860B); // dark goldenrod
  static const Color ayahNumberGoldLight = Color(0xFFD4A84B);
  static const Color quranHighlightRed = Color(0xFF8B0000); // dark red for Allah, Rabbana

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F0E6), // off-white / cream
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F0E6),
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );

  static TextStyle arabicVerseStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.amiri(
      fontSize: 22,
      height: 1.6,
      wordSpacing: 2,
      color: isDark ? Colors.white : Colors.black87,
    );
  }

  static TextStyle arabicBasmalahStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.amiri(
      fontSize: 24,
      height: 1.6,
      color: isDark ? Colors.white : Colors.black87,
    );
  }

  static TextStyle surahTitleStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.amiri(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black87,
    );
  }
}

