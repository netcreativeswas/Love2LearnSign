class AgentLoggerImpl {
  static Future<void> log(Map<String, dynamic> payload) async {
    // No-op on platforms without dart:io (e.g. web).
  }
}



