// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html' as html;

class DebugLogImpl {
  static const String _url =
      'http://127.0.0.1:7243/ingest/e742e3b3-12ea-413e-9e63-f9ff4decb905';

  static void log(Map<String, dynamic> payload) {
    try {
      // Keep it extremely defensive: never throw, never block UI.
      final body = jsonEncode(payload);
      html.window.fetch(
        _url,
        {
          'method': 'POST',
          'headers': {'Content-Type': 'application/json'},
          'body': body,
        },
      ).catchError((_) {});
    } catch (_) {
      // ignore
    }
  }
}


