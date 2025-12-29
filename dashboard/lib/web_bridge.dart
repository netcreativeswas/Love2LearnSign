import 'web_bridge_stub.dart'
    if (dart.library.html) 'web_bridge_web.dart' as impl;

/// Lightweight bridge to notify the embedding page (Next.js wrapper).
class WebBridge {
  static void notifySignedOut() => impl.notifySignedOut();
}


