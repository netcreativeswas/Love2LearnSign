import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    _loadLocale();
  }

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  // Tenant-scoped allowed UI locales (language codes).
  // Default keeps current behavior.
  List<String> _allowedLocaleCodes = const ['en', 'bn'];
  List<String> get allowedLocaleCodes => List.unmodifiable(_allowedLocaleCodes);

  /// Update which locales are allowed for the current tenant.
  /// - Always ensures 'en' is present as a safe fallback.
  /// - If the current locale becomes disallowed, falls back to 'en' (or first allowed).
  Future<void> setAllowedLocaleCodes(List<String> codes) async {
    final next = <String>{
      'en',
      ...codes.map((c) => c.trim().toLowerCase()).where((c) => c.isNotEmpty),
    }.toList();

    next.sort(); // deterministic for comparisons
    final cur = List<String>.from(_allowedLocaleCodes)..sort();
    if (_sameList(cur, next)) return;

    _allowedLocaleCodes = next;
    if (!_allowedLocaleCodes.contains(_locale.languageCode)) {
      // Fall back to English if possible, otherwise first allowed.
      final fallback = _allowedLocaleCodes.contains('en') ? 'en' : _allowedLocaleCodes.first;
      _locale = Locale(fallback);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale_code', _locale.languageCode);
    }
    notifyListeners();
  }

  void setLocale(Locale locale) {
    final code = locale.languageCode.toLowerCase().trim();
    if (!_allowedLocaleCodes.contains(code)) return;
    _locale = Locale(code);
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('locale_code', _locale.languageCode),
    );
  }

  void clearLocale() {
    setLocale(const Locale('en'));
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('locale_code');
    if (saved != null && saved.isNotEmpty && _allowedLocaleCodes.contains(saved)) {
      _locale = Locale(saved);
    } else {
      // First run: derive from device language; only 'bn' is localized, else fallback to 'en'
      final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      final resolved =
          (_allowedLocaleCodes.contains(deviceLang)) ? deviceLang : 'en';
      _locale = Locale(resolved);
      await prefs.setString('locale_code', resolved);
    }
    notifyListeners();
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}