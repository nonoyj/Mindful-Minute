import 'package:flutter/material.dart';

/// Dark, Alarmy-inspired palette.
class Pal {
  static const bg = Color(0xFF121417);
  static const card = Color(0xFF1E2126);
  static const card2 = Color(0xFF2A2E35);
  static const accent = Color(0xFF2DD4BF);
  static const muted = Color(0xFF8A9099);
  static const danger = Color(0xFFE8334A);
}

ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Pal.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Pal.accent,
        brightness: Brightness.dark,
      ).copyWith(surface: Pal.bg),
      appBarTheme: const AppBarTheme(
        backgroundColor: Pal.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Pal.bg,
        indicatorColor: Pal.card2,
      ),
    );
