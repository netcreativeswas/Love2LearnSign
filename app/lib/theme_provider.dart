import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A ChangeNotifier that holds the app’s ThemeMode and persists it.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode;

  ThemeProvider._(this._mode);

  /// Factory constructor that loads the saved preference (or defaults to system).
  static Future<ThemeProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    final darkOn = prefs.getBool('darkMode') ?? false;
    return ThemeProvider._(darkOn ? ThemeMode.dark : ThemeMode.light);
  }

  ThemeMode get mode => _mode;

  /// Switch between light and dark, and persist the choice.
  Future<void> setMode(ThemeMode newMode) async {
    if (newMode == _mode) return;
    _mode = newMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', newMode == ThemeMode.dark);
  }
}