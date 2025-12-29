// lib/theme.dart
import 'package:flutter/material.dart';
export 'package:l2l_shared/theme_extensions.dart';

class AppTheme {
  static const Color defaultPrimary = Color(0xFF232F34);
  static const Color defaultSecondary = Color(0xFFF9AA33);

  static Color _onFor(Color c) {
    final b = ThemeData.estimateBrightnessForColor(c);
    return (b == Brightness.dark) ? Colors.white : Colors.black;
  }

  static ThemeData themed({
    required Brightness brightness,
    Color? primary,
    Color? secondary,
  }) {
    final seed = primary ?? defaultPrimary;
    final accent = secondary ?? defaultSecondary;

    var scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    scheme = scheme.copyWith(
      primary: seed,
      onPrimary: _onFor(seed),
      secondary: accent,
      onSecondary: _onFor(accent),
    );

    return ThemeData(
    useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
        iconTheme: IconThemeData(color: scheme.onPrimary),
      titleTextStyle: TextStyle(
          color: scheme.onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
    ),
    );
  }

  // Backwards-compatible defaults
  static final ThemeData light = themed(brightness: Brightness.light);
  static final ThemeData dark = themed(brightness: Brightness.dark);
}
