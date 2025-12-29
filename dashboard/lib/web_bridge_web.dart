// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void notifySignedOut() {
  try {
    html.window.top?.postMessage({'type': 'SIGNED_OUT'}, '*');
  } catch (_) {
    // ignore
  }
}


