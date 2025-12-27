import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  /// Checks if notifications are currently enabled.
  static Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Requests notification permission from the user.
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Opens the app settings so the user can manually enable permissions.
  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}