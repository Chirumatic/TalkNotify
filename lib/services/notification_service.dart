import 'package:flutter/services.dart';

/// Service for handling alerts and notification listener access.
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  static const _platform = MethodChannel('com.example.talknotify/notifications');

  NotificationService._init();

  Future<void> initialize() async {}

  Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  Future<void> showNotification({
    required String title,
    required String body,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    if (vibrate) await HapticFeedback.vibrate();
  }

  /// Open Android notification listener settings
  Future<bool> requestNotificationListenerPermission() async {
    try {
      final bool result = await _platform.invokeMethod('requestNotificationAccess');
      return result;
    } catch (e) {
      print('Error requesting notification access: $e');
      return false;
    }
  }

  /// Check if notification listener is enabled
  Future<bool> isNotificationListenerEnabled() async {
    try {
      final bool result = await _platform.invokeMethod('isNotificationAccessGranted');
      return result;
    } catch (e) {
      print('Error checking notification access: $e');
      return false;
    }
  }

  /// Sync settings to Android native SharedPreferences so Java services can read them
  Future<void> syncSettings(Map<String, dynamic> settings) async {
    try {
      await _platform.invokeMethod('syncSettings', settings);
    } catch (e) {
      print('Error syncing settings: $e');
    }
  }
}
