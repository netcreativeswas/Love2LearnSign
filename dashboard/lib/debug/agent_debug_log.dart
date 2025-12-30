import 'agent_debug_log_stub.dart'
    if (dart.library.html) 'agent_debug_log_web.dart' as impl;

class DebugLog {
  static void log(Map<String, dynamic> payload) => impl.DebugLogImpl.log(payload);
}


