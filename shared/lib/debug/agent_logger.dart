import 'agent_logger_stub.dart' if (dart.library.io) 'agent_logger_io.dart'
    as impl;

class AgentLogger {
  static Future<void> log(Map<String, dynamic> payload) =>
      impl.AgentLoggerImpl.log(payload);
}
