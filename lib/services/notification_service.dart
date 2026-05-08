import 'package:flutter/services.dart';

/// Service for handling alerts and notification listener access.
/// Uses Flutter's built-in HapticFeedback — no heavy notification library needed.
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  static const _platform = MethodChannel('com.example.talknotify/notifications');

  NotificationService._init();

  /// No-op initialize (kept for API compatibility)
  Future<void> initialize() async {}

  /// Vibrate the device
  Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Show a system notification via Android MethodChannel
  Future<void> showNotification({
    required String title,
    required String body,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    if (vibrate) await HapticFeedback.vibrate();
    // Native side can be extended to show a system notification if needed
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
}
