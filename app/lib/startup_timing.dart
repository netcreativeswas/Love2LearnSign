/// Timestamp captured at Dart isolate startup.
final int appStartMs = DateTime.now().millisecondsSinceEpoch;

int sinceAppStartMs() => DateTime.now().millisecondsSinceEpoch - appStartMs;


