// import 'package:flutter/material.dart';
// import 'package:chatapp/core/services/push_notification_tester.dart';

// class NotificationTestScreen extends StatelessWidget {
//   const NotificationTestScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Push Notification Testing'),
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const SizedBox(height: 20),
//             const Text(
//               'Test Push Notification Features',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 40),

//             const SizedBox(height: 16),
//             _buildTestCard(
//               context,
//               title: 'Rich Notification',
//               description: 'Send a notification with image and action buttons',
//               icon: Icons.notifications_active,
//               onTap: () =>
//                   PushNotificationTester.testSendRichNotification(context),
//             ),
//             const SizedBox(height: 16),
//             _buildTestCard(
//               context,
//               title: 'Local Notification',
//               description: 'Show a notification directly without FCM',
//               icon: Icons.notification_important,
//               onTap: () =>
//                   PushNotificationTester.testLocalNotification(context),
//             ),
//             const Spacer(),
//             const Text(
//               'Note: Make sure you have properly configured the Firebase credentials and service account',
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontSize: 12,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTestCard(
//     BuildContext context, {
//     required String title,
//     required String description,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               Icon(
//                 icon,
//                 size: 40,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       description,
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(
//                 Icons.arrow_forward_ios,
//                 color: Colors.grey[400],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
