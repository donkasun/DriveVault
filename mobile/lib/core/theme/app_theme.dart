import 'package:flutter/material.dart';

/// Central app theme. Keep visual styling here, not scattered across widgets.
class AppTheme {
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color secondaryBlue = Color(0xFF2F6BFF);
  static const Color amberLink = Color(0xFFF5B301);
  static const Color lightBg = Color(0xFFF3F4F7);
  static const Color darkBg = Color(0xFF15151C);
  static const Color darkCardBg = Color(0xFF23232E);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: lightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: secondaryBlue,
          surface: Colors.white,
          error: const Color(0xFFD23B3B),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF15151C),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: secondaryBlue,
          surface: darkCardBg,
          brightness: Brightness.dark,
          error: const Color(0xFFD23B3B),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: darkCardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}
