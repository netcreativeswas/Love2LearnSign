import 'dart:convert';
import 'dart:io';

class AgentLoggerImpl {
  // IMPORTANT:
  // - This app runs on Android emulator/device, so writing to a macOS path won't work.
  // - We POST to the local ingest server instead.
  // - For Android emulators, 10.0.2.2 points to the host machine.
  static const List<String> _endpoints = [
    // Cursor debug-mode ingest server (host machine)
    'http://127.0.0.1:7243/ingest/e742e3b3-12ea-413e-9e63-f9ff4decb905',
    // Android emulator -> host machine mapping
    'http://10.0.2.2:7243/ingest/e742e3b3-12ea-413e-9e63-f9ff4decb905',
  ];

  static Future<void> log(Map<String, dynamic> payload) async {
    final body = jsonEncode(payload);
    // #region agent log
    // Always print the log line so it shows up in Xcode / flutter run output.
    // This is critical on real iOS devices where 127.0.0.1 points to the phone itself.
    // (Do not log secrets/PII in payload.)
    // #endregion
    // ignore: avoid_print
    print(body);
    for (final url in _endpoints) {
      try {
        final client = HttpClient();
        final req = await client.postUrl(Uri.parse(url));
        req.headers.contentType = ContentType.json;
        req.write(body);
        await req.close();
        client.close(force: true);
        break;
      } catch (_) {
        // Try next endpoint.
      }
    }
  }
}


