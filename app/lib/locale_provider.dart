import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    _loadLocale();
  }

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['en', 'bn'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('locale_code', locale.languageCode),
    );
  }

  void clearLocale() {
    setLocale(const Locale('en'));
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('locale_code');
    if (saved != null && saved.isNotEmpty) {
      _locale = Locale(saved);
    } else {
      // First run: derive from device language; only 'bn' is localized, else fallback to 'en'
      final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      final resolved = (deviceLang == 'bn') ? 'bn' : 'en';
      _locale = Locale(resolved);
      await prefs.setString('locale_code', resolved);
    }
    notifyListeners();
  }
}