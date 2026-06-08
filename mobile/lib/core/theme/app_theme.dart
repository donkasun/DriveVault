import 'package:flutter/material.dart';

/// Central app theme. Keep visual styling here, not scattered across widgets.
class AppTheme {
  static const Color _seed = Color(0xFF1565C0); // DriveVault blue

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        appBarTheme: const AppBarTheme(centerTitle: false),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false),
      );
}
