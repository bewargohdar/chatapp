import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatapp/core/services/notification_service.dart';
import 'package:chatapp/server_injection.dart';
import 'package:chatapp/core/helper/notification_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = sl<NotificationService>();
  bool _isGeneralNotificationsEnabled = true;
  bool _isChatNotificationsEnabled = true;
  bool _isChecking = false;
  final TextEditingController _targetTokenController = TextEditingController();

  bool _showGoogleAuthHelp = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _targetTokenController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isChecking = true;
    });

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      _isGeneralNotificationsEnabled = status.isGranted;
    }

    setState(() {
      _isChecking = false;
    });
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  // Function to show FCM token
  void _showFCMToken() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('FCM Token'),
          content: SingleChildScrollView(
            child: SelectableText(token ?? 'Unable to get token'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                if (token != null) {
                  Clipboard.setData(ClipboardData(text: token));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token copied to clipboard')),
                  );
                }
              },
              child: const Text('Copy'),
            ),
          ],
        ),
      );
    }
  }

  // Function to send notification to another device
  void _showSendToDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send to Another Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _targetTokenController,
              decoration: const InputDecoration(
                labelText: 'Target Device FCM Token',
                hintText: 'Paste the FCM token here',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This feature requires additional setup'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // Function to show Google Auth help
  void _toggleGoogleAuthHelp() {
    setState(() {
      _showGoogleAuthHelp = !_showGoogleAuthHelp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Notification Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (Platform.isAndroid)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: _openAppSettings,
                      child: const Text('Open System Notification Settings'),
                    ),
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable All Notifications'),
                  subtitle: const Text('Get all app notifications'),
                  value: _isGeneralNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isGeneralNotificationsEnabled = value;
                      if (!value) {
                        _isChatNotificationsEnabled = false;
                        _notificationService.unsubscribeFromTopic('general');
                        _notificationService.unsubscribeFromTopic('chat');
                      } else {
                        _notificationService.subscribeToTopic('general');
                      }
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Chat Notifications'),
                  subtitle: const Text('Get notified about new messages'),
                  value: _isChatNotificationsEnabled,
                  onChanged: _isGeneralNotificationsEnabled
                      ? (value) {
                          setState(() {
                            _isChatNotificationsEnabled = value;
                            if (value) {
                              _notificationService.subscribeToTopic('chat');
                            } else {
                              _notificationService.unsubscribeFromTopic('chat');
                            }
                          });
                        }
                      : null,
                ),
                const Divider(),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Note: You can also manage notifications in your device settings.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Preferences saved!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Save Preferences'),
                  ),
                ),
                if (_isGeneralNotificationsEnabled) ...[
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Test Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              NotificationHelper.showTestNotification(
                            context: context,
                            title: 'Test Notification',
                            body: 'This is a test notification',
                          ),
                          child: const Text('Send Test Notification'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () =>
                              NotificationHelper.showTestNotification(
                            context: context,
                            title: 'New Message',
                            body: 'You received a new message from John',
                          ),
                          child: const Text('Test Chat Notification'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Developer Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: OutlinedButton(
                    onPressed: _showFCMToken,
                    child: const Text('Show FCM Token'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: OutlinedButton(
                    onPressed: _showSendToDeviceDialog,
                    child: const Text('Send to Another Device'),
                  ),
                ),

                // Add the Google Auth help section
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Advanced Configuration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: OutlinedButton.icon(
                    icon: Icon(_showGoogleAuthHelp
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down),
                    onPressed: _toggleGoogleAuthHelp,
                    label: const Text('Google Auth for FCM'),
                  ),
                ),

                if (_showGoogleAuthHelp) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set up Google Auth for secure device-to-device messaging:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            const Text('1. Create a Firebase service account'),
                            const Text('2. Download service account JSON'),
                            const Text('3. Place in assets/credentials/'),
                            const Text('4. Update project ID in code'),
                            const SizedBox(height: 16),
                            const Text(
                              'For details, check the Firebase documentation.',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
