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

  // Send notification to another device
  static Future<bool> sendToDevice({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    BuildContext? context,
  }) async {
    try {
      final result = await _notificationService.sendNotificationWithServerKey(
        recipientToken: token,
        title: title,
        body: body,
        data: data,
      );

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result
                ? 'Notification sent successfully'
                : 'Failed to send notification'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return result;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }
}
