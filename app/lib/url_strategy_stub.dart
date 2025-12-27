/// Stub PathUrlStrategy for non-web platforms.
class PathUrlStrategy {
  /// Creates a no-op path URL strategy stub.
  const PathUrlStrategy();
}

/// Stub for URL strategy on non-web platforms.
void setUrlStrategy(dynamic strategy) {
  // No-op on Android/iOS/desktop when not running on web.
}