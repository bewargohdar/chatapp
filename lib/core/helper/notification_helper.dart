import 'package:chatapp/core/services/notification_service.dart';
import 'package:chatapp/server_injection.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  static final NotificationService _notificationService =
      sl<NotificationService>();

  // Function to show a local test notification
  static Future<void> showTestNotification({
    required BuildContext context,
    String title = 'Test Notification',
    String body = 'This is a test notification',
  }) async {
    try {
      // Show a local notification
      await _notificationService.showLocalNotification(
        title: "📱 $title",
        body: "$body - ${DateTime.now().toString().substring(11, 19)}",
        payload: {
          'type': 'test',
          'timestamp': DateTime.now().toString(),
          'action': 'open_settings'
        },
      );

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent! Check notification panel.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
