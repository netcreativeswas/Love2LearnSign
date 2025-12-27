import 'dart:convert';
import 'dart:io';

class AgentLoggerImpl {
  // IMPORTANT:
  // - This app runs on Android emulator/device, so writing to a macOS path won't work.
  // - We POST to the local ingest server instead.
  // - For Android emulators, 10.0.2.2 points to the host machine.
  static const List<String> _endpoints = [
    'http://127.0.0.1:7242/ingest/9a094446-bd02-48fd-b135-914128dcd952',
    'http://10.0.2.2:7242/ingest/9a094446-bd02-48fd-b135-914128dcd952',
  ];

  static Future<void> log(Map<String, dynamic> payload) async {
    final body = jsonEncode(payload);
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


