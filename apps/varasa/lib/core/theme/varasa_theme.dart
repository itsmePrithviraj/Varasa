import 'package:flutter/material.dart';

abstract final class VarasaTheme {
  static const ink = Color(0xFF622A0F);
  static const parchment = Color(0xFFFFEEDB);
  static const paper = Color(0xFFFFFCF7);
  static const terracotta = Color(0xFF903A36);
  static ThemeData get light {
    final colors = ColorScheme.fromSeed(seedColor: ink, surface: paper)
        .copyWith(
          primary: ink,
          onPrimary: Colors.white,
          secondary: terracotta,
          surface: paper,
          onSurface: ink,
          error: const Color(0xFFAB2323),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: parchment,
        foregroundColor: ink,
        centerTitle: false,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: parchment,
        indicatorColor: Color(0xFFE6C8AC),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'CinzelDecorative',
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'CinzelDecorative',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ink),
      ),
    );
  }
}
