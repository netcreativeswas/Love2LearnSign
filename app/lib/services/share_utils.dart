import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> _tryLaunch(Uri uri) async {
  try {
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (kDebugMode) debugPrint('🔗 Launched: $uri (ok=$ok)');
      return ok;
    }
    if (kDebugMode) debugPrint('❌ No handler for: $uri');
    return false;
  } catch (e, st) {
    if (kDebugMode) debugPrint('⚠️ Launch failed for $uri -> $e\n$st');
    return false;
  }
}

Future<void> _fallbackShare(String text, {String? subject}) async {
  if (kDebugMode) debugPrint('↩️ Fallback to system share sheet');
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: subject,
    ),
  );
}

/// Shares a plain text message via the platform's native share sheet.
Future<void> shareGeneric(String message, {String? subject}) async {
  await _fallbackShare(message, subject: subject);
}

/// WhatsApp: try deep link → system chooser (avoid opening browser)
Future<void> shareOnWhatsApp(String message) async {
  final deep =
      Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
  if (await _tryLaunch(deep)) return;
  // If WhatsApp is not installed or deep link unsupported, fall back to system share sheet.
  await _fallbackShare(message);
}

/// Imo: try deep link → system chooser
Future<void> shareOnImo(String message) async {
  final imo = Uri.parse('imo://msg/text/${Uri.encodeComponent(message)}');
  if (await _tryLaunch(imo)) return;
  await _fallbackShare(message);
}

/// Messenger: try deep link (text param) → system chooser
Future<void> shareOnMessenger(String message) async {
  final msgr =
      Uri.parse('fb-messenger://share?text=${Uri.encodeComponent(message)}');
  if (await _tryLaunch(msgr)) return;
  await _fallbackShare(message);
}

/// Instagram: no text-only deep link; open app if present then system chooser
Future<void> shareOnInstagram(String message) async {
  final ig = Uri.parse('instagram://app');
  if (await _tryLaunch(ig)) {
    await _fallbackShare(message);
    return;
  }
  await _fallbackShare(message);
}

/// A reusable service for sharing video deep links.
class ShareService {
  /// Shares a deep link to open the video with [wordId] in the app.
  /// Optional [english] and [bengali] will be included in the message if provided.
  static Future<void> shareVideo(String wordId,
      {String? english, String? bengali}) async {
    final url = 'https://love2learnsign.com/word/$wordId';
    final hasTitle = (english != null && english.trim().isNotEmpty) ||
        (bengali != null && bengali.trim().isNotEmpty);
    final title = [english, bengali]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' / ');
    final message = hasTitle ? 'Watch this sign: $title\n$url' : url;
    await shareGeneric(message);
  }
}
