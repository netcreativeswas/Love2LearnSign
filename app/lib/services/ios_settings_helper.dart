import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class IOSSettingsHelper {
  static Future<void> openAppSettings() async {
    if (!kIsWeb && Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
    }
  }
}

