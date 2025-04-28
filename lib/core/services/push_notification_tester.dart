// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:chatapp/core/services/notification_service.dart';
// import 'package:chatapp/server_injection.dart';

// class PushNotificationTester {
//   /// Test sending a notification to the current device
//   static Future<void> testSendSelfNotification(BuildContext context) async {
//     try {
//       // Show a loading indicator
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const AlertDialog(
//           title: Text('Testing Notification'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text('Sending notification to this device...'),
//             ],
//           ),
//         ),
//       );

//       // Get the current device FCM token using our NotificationService
//       final notificationService = sl<NotificationService>();
//       final token = await notificationService.getToken();

//       if (token == null) {
//         if (context.mounted) {
//           Navigator.of(context).pop(); // Close loading dialog
//         }
//         if (context.mounted) {
//           _showResultDialog(
//             context: context,
//             success: false,
//             message:
//                 'Failed to get device token. Make sure Firebase is properly configured.',
//           );
//         }
//         return;
//       }

//       // Send a test notification using the server key method instead of JWT
//       final success = await notificationService.sendNotificationWithServerKey(
//         recipientToken: token,
//         title: 'Self Test Notification',
//         body: 'This notification was sent from this device to itself',
//         data: {
//           'type': 'test',
//           'timestamp': DateTime.now().toString(),
//         },
//       );

//       // Close loading dialog
//       if (context.mounted) Navigator.of(context).pop();

//       // Show result
//       if (context.mounted) {
//         _showResultDialog(
//           context: context,
//           success: success,
//           message: success
//               ? 'Notification sent successfully! You should receive it shortly.'
//               : 'Failed to send notification. Check that your server key is valid and properly configured.',
//         );
//       }
//     } catch (e) {
//       // Close loading dialog if open
//       if (context.mounted) {
//         Navigator.of(context).pop();
//       }

//       // Parse error for better user feedback
//       String errorMessage = e.toString();

//       if (errorMessage.contains('server-key.txt')) {
//         errorMessage =
//             'Server key file missing or invalid. Make sure to place the server-key.txt file in your assets/credentials folder.';
//       }

//       // Show error
//       if (context.mounted) {
//         _showResultDialog(
//           context: context,
//           success: false,
//           message: 'Error: $errorMessage',
//         );
//       }
//     }
//   }

//   /// Test sending a rich notification with image and actions
//   static Future<void> testSendRichNotification(BuildContext context) async {
//     try {
//       // Show loading indicator
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const AlertDialog(
//           title: Text('Testing Rich Notification'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text('Sending rich notification with image and actions...'),
//             ],
//           ),
//         ),
//       );

//       // Get the current device token
//       final notificationService = sl<NotificationService>();
//       final token = await notificationService.getToken();

//       if (token == null) {
//         if (context.mounted) Navigator.of(context).pop();
//         if (context.mounted) {
//           _showResultDialog(
//             context: context,
//             success: false,
//             message: 'Failed to get device token',
//           );
//         }
//         return;
//       }

//       // Define action buttons for the notification
//       final actions = [
//         NotificationAction(
//           id: 'view',
//           title: 'View',
//           foreground: true,
//         ),
//         NotificationAction(
//           id: 'dismiss',
//           title: 'Dismiss',
//           foreground: false,
//         ),
//       ];

//       // Send a rich notification with image and actions using server key
//       final success = await notificationService.sendNotificationWithServerKey(
//         recipientToken: token,
//         title: 'Rich Notification',
//         body: 'This notification includes an image and action buttons',
//         imageUrl: 'https://picsum.photos/512', // Placeholder image URL
//         highPriority: true,
//         actions: actions,
//         data: {
//           'type': 'rich_test',
//           'timestamp': DateTime.now().toString(),
//         },
//       );

//       // Close loading dialog
//       if (context.mounted) Navigator.of(context).pop();

//       // Show result
//       if (context.mounted) {
//         _showResultDialog(
//           context: context,
//           success: success,
//           message: success
//               ? 'Rich notification sent successfully!'
//               : 'Failed to send rich notification.',
//         );
//       }
//     } catch (e) {
//       if (context.mounted) Navigator.of(context).pop();
//       if (context.mounted) {
//         _showResultDialog(
//           context: context,
//           success: false,
//           message: 'Error: ${e.toString()}',
//         );
//       }
//     }
//   }

//   /// Test showing a local notification directly
//   static Future<void> testLocalNotification(BuildContext context) async {
//     try {
//       final notificationService = sl<NotificationService>();

//       await notificationService.showLocalNotification(
//         title: 'Local Notification Test',
//         body: 'This is a local notification shown without using FCM',
//         payload: {'type': 'local_test', 'timestamp': DateTime.now().toString()},
//       );

//       // Show confirmation
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Local notification displayed'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       if (context.mounted) {
//         _showResultDialog(
//           context: context,
//           success: false,
//           message: 'Error showing local notification: ${e.toString()}',
//         );
//       }
//     }
//   }

//   /// Display the test result
//   static void _showResultDialog({
//     required BuildContext context,
//     required bool success,
//     required String message,
//   }) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(success ? 'Success' : 'Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Check if service account file exists
//   static Future<bool> isServiceAccountConfigured() async {
//     try {
//       // Try to access the assets file
//       await rootBundle.load('assets/credentials/service-account.json');
//       return true;
//     } catch (e) {
//       debugPrint('Service account not configured: $e');
//       return false;
//     }
//   }

//   /// Print the FCM token to the console
//   static Future<void> printToken() async {
//     try {
//       final notificationService = sl<NotificationService>();
//       final token = await notificationService.getToken();
//       debugPrint('FCM Token: $token');
//     } catch (e) {
//       debugPrint('Error getting FCM token: $e');
//     }
//   }
// }
