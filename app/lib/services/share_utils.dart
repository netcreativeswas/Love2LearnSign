import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

bool _needsShareOrigin() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

Rect _shareOriginFromContext(BuildContext context) {
  try {
    final ro = context.findRenderObject();
    final box = ro is RenderBox ? ro : null;
    if (box != null && box.hasSize) {
      final offset = box.localToGlobal(Offset.zero);
      final size = box.size;
      if (size.width > 0 && size.height > 0) {
        return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
      }
    }
  } catch (_) {
    // ignore
  }
  // Must be non-zero and within source view coordinate space.
  return const Rect.fromLTWH(0, 0, 1, 1);
}

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

Future<void> _fallbackShare(
  String text, {
  String? subject,
  BuildContext? context,
}) async {
  if (kDebugMode) debugPrint('↩️ Fallback to system share sheet');
  if (_needsShareOrigin() && context != null) {
    await Share.share(
      text,
      subject: subject,
      sharePositionOrigin: _shareOriginFromContext(context),
    );
    return;
  }
  await Share.share(text, subject: subject);
}

/// Shares a plain text message via the platform's native share sheet.
Future<void> shareGeneric(
  String message, {
  String? subject,
  BuildContext? context,
}) async {
  await _fallbackShare(message, subject: subject, context: context);
}

/// WhatsApp: try deep link → system chooser (avoid opening browser)
Future<void> shareOnWhatsApp(String message, {BuildContext? context}) async {
  final deep =
      Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
  if (await _tryLaunch(deep)) return;
  // If WhatsApp is not installed or deep link unsupported, fall back to system share sheet.
  await _fallbackShare(message, context: context);
}

/// Imo: try deep link → system chooser
Future<void> shareOnImo(String message, {BuildContext? context}) async {
  final imo = Uri.parse('imo://msg/text/${Uri.encodeComponent(message)}');
  if (await _tryLaunch(imo)) return;
  await _fallbackShare(message, context: context);
}

/// Messenger: try deep link (text param) → system chooser
Future<void> shareOnMessenger(String message, {BuildContext? context}) async {
  final msgr =
      Uri.parse('fb-messenger://share?text=${Uri.encodeComponent(message)}');
  if (await _tryLaunch(msgr)) return;
  await _fallbackShare(message, context: context);
}

/// Instagram: no text-only deep link; open app if present then system chooser
Future<void> shareOnInstagram(String message, {BuildContext? context}) async {
  final ig = Uri.parse('instagram://app');
  if (await _tryLaunch(ig)) {
    await _fallbackShare(message, context: context);
    return;
  }
  await _fallbackShare(message, context: context);
}

/// A reusable service for sharing video deep links.
class ShareService {
  /// Shares a deep link to open the video with [wordId] in the app.
  /// Optional [english] and [bengali] will be included in the message if provided.
  static Future<void> shareVideo(
    String wordId, {
    String? english,
    String? bengali,
    String? tenantId,
    String? signLangId,
    String? uiLocale,
    BuildContext? context,
  }) async {
    final base = Uri.parse('https://love2learnsign.com/word/$wordId');
    final qp = <String, String>{
      if (tenantId != null && tenantId.trim().isNotEmpty) 'tenant': tenantId.trim(),
      if (signLangId != null && signLangId.trim().isNotEmpty) 'lang': signLangId.trim(),
      // Website UI language (optional). We only include it when non-English to keep links short.
      if (uiLocale != null &&
          uiLocale.trim().isNotEmpty &&
          uiLocale.trim().toLowerCase() != 'en')
        'ui': uiLocale.trim().toLowerCase(),
    };
    final url = qp.isEmpty ? base.toString() : base.replace(queryParameters: qp).toString();
    final hasTitle = (english != null && english.trim().isNotEmpty) ||
        (bengali != null && bengali.trim().isNotEmpty);
    final title = [english, bengali]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' / ');
    final message = hasTitle ? 'Watch this sign: $title\n$url' : url;
    await shareGeneric(message, context: context);
  }
}
