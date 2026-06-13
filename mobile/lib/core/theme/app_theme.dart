import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Background
  static const Color background = Color(0xFFEBEBF0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1D2B);

  // Accent
  static const Color primary = Color(0xFFFFD600);
  static const Color onPrimary = Color(0xFF1E1D2B);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF9898A6);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFF9898A6);

  // Utility
  static const Color divider = Color(0xFFE2E2EA);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color dangerBg = Color(0xFFFEE2E2);

  // Design-language tokens
  static const Color dashedBorder = Color(0xFFC2C4CF);
  static const Color cardGradientStart = Color(0xFF23232E);
  static const Color cardGradientEnd = Color(0xFF15151C);
  static const Color photoUploadTint = Color(0xFFFFF9E6);
}

/// Shared BoxDecoration for white surface cards.
/// Approximates `box-shadow: 0 4px 14px rgba(20,20,40,0.06)`.
const BoxDecoration appCardDecoration = BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: [
    BoxShadow(
      color: Color(0x0F14141F), // rgba(20,20,40,0.06) ≈ 0x0F
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ],
);

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.surfaceDark,
      onSecondary: AppColors.textOnDark,
      error: AppColors.danger,
      onError: AppColors.textOnDark,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Color(0x0F1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 16),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.focused)
              ? AppColors.textPrimary
              : AppColors.textMuted,
          fontSize: 12,
        );
      }),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted),
      labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8),
    ),
  );
}
