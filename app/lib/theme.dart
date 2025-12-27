// lib/theme.dart
import 'package:flutter/material.dart';
export 'package:l2l_shared/theme_extensions.dart';

class AppTheme {
  // Light theme
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF232F34),
      onPrimary: const Color(0xFFFFFFFF),
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF232F34),
      secondary: const Color(0xFFF9AA33),
      onSecondary: const Color(0xFFFFFFFF),
    ),
    scaffoldBackgroundColor: const Color(0xFFE4E1DD),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFF9AA33),
      foregroundColor: Colors.black,
    ),
  );

  // Dark theme
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF90A4AE),
      onPrimary: const Color(0xFF232F34),
      surface: const Color(0xFF232F34),
      onSurface: const Color(0xFFFFFFFF),
      secondary: const Color(0xFFF9AA33),
      onSecondary: const Color(0xFFFFFFFF),
    ),
    scaffoldBackgroundColor: const Color(0xFF181B1F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFF9AA33),
      foregroundColor: Colors.black,
    ),
  );
}
