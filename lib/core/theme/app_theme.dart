import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Warm green + cream palette from Khayal design spec.
  static const Color primaryGreen = Color(0xFF6DBB7A);
  static const Color lightGreen = Color(0xFFE8F6EA);
  static const Color softWhite = Color(0xFFFAFFFB);
  static const Color deepText = Color(0xFF1F2E21);
  static const Color takenGreen = Color(0xFF2E7D32);
  static const Color upcomingAmber = Color(0xFFF9A825);
  static const Color missedRed = Color(0xFFC62828);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      surface: softWhite,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'KhayalRoboto',
      fontFamilyFallback: const ['NotoNastaliqUrdu'],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: softWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: deepText,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD8EFD9)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCDE8D0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCDE8D0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textTheme: const TextTheme(
        // Accessibility spec:
        // Normal 18, Large 22, Extra Large 26, headings >= 24.
        displaySmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 18),
        bodySmall: TextStyle(fontSize: 18),
      ).apply(bodyColor: deepText, displayColor: deepText),
    );
  }
}
