import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// Service to determine the user’s country code via SIM, falling back to device locale.
class LocationService {
  static const MethodChannel _channel =
      MethodChannel('love_to_learn_sign/countryCode');
  static const MethodChannel _tzChannel =
      MethodChannel('love_to_learn_sign/timezone');

  /// Returns the ISO country code (e.g., 'BD', 'US').
  /// First attempts to read SIM country ISO via platform channel.
  /// If that fails, falls back to device locale.
  static Future<String?> getCountryCode() async {
    try {
      final String? simIso =
          await _channel.invokeMethod<String>('getSimCountryIso');
      if (simIso != null && simIso.isNotEmpty) {
        return simIso.toUpperCase();
      }
    } on PlatformException {
      // SIM lookup failed – fall back below
    }
    // Fallback to device locale
    return ui.PlatformDispatcher.instance.locale.countryCode;
  }
}

/// Helper for platform timezone name
Future<String?> getPlatformTimeZoneName() async {
  try {
    final String? name = await LocationService._tzChannel.invokeMethod<String>('getTimeZoneName');
    return name;
  } catch (_) {
    return null;
  }
}