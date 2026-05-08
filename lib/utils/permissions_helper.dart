import 'package:permission_handler/permission_handler.dart';

/// Helper class for managing app permissions
class PermissionsHelper {
  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check microphone permission
  static Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check notification permission
  static Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Open app settings page
  static Future<void> goToAppSettings() async {
    await openAppSettings();
  }

  /// Request all required permissions at once
  static Future<Map<String, bool>> requestAllPermissions() async {
    final statuses = await [
      Permission.microphone,
      Permission.notification,
    ].request();

    return {
      'microphone': statuses[Permission.microphone]?.isGranted ?? false,
      'notification': statuses[Permission.notification]?.isGranted ?? false,
    };
  }
}
