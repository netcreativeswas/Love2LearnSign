import 'package:flutter/material.dart';

import 'url_strategy_stub.dart'
    if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'app_bootstrap.dart';
import 'startup_timing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remove the hash (#) from Flutter web URLs
  setUrlStrategy(PathUrlStrategy());

  debugPrint('STARTUP_TIMING: main() +${sinceAppStartMs()}ms');
  runApp(const AppBootstrap());
}
