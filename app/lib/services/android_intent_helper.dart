import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

class AndroidIntentHelper {
  static Future<void> openAppDetails() async {
    if (!kIsWeb && Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:com.love2learnsign.app',
      );
      await intent.launch();
    }
  }
}

