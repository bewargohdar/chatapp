import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:chatapp/core/services/google_auth_service.dart';
import 'package:chatapp/firebase_options.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Get Firebase project ID from Firebase options
  static final String _projectId =
      DefaultFirebaseOptions.currentPlatform.projectId;

  // Create notification channels
  static const String _mainChannelId = 'chat_channel';
  static const String _mainChannelName = 'Chat Notifications';
  static const String _highPriorityChannelId = 'important_channel';
  static const String _highPriorityChannelName = 'Important Notifications';

  // HTTP client for API requests
  final http.Client _httpClient = http.Client();

  // Service for Google authentication
  final GoogleAuthService _authService;

  // Server key for Firebase Cloud Messaging
  String? _serverKey;

  // Constructor with dependency injection
  NotificationService(this._authService);

  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when user taps on notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Set up foreground notification presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('NotificationService initialized with project ID: $_projectId');
    }
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true, // For important notifications
    );

    if (kDebugMode) {
      print(
          'User granted notification permission: ${settings.authorizationStatus}');
    }

    // Request precise alarm permission (for scheduled notifications) on Android
    if (Platform.isAndroid) {
      final permissionStatus = await ph.Permission.notification.request();
      if (kDebugMode) {
        print('Android notification permission status: $permissionStatus');
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    // Set up Android notification channels
    final AndroidInitializationSettings androidSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    // Set up Android notification channels
    if (Platform.isAndroid) {
      final List<AndroidNotificationChannel> channels = [
        AndroidNotificationChannel(
          _mainChannelId,
          _mainChannelName,
          importance: Importance.high,
          playSound: true,
          enableLights: true,
        ),
        AndroidNotificationChannel(
          _highPriorityChannelId,
          _highPriorityChannelName,
          importance: Importance.max,
          playSound: true,
          enableLights: true,
          enableVibration: true,
        ),
      ];

      // Create the Android notification channels
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannelGroup(
            AndroidNotificationChannelGroup(
              'chat_app_group',
              'Chat App Notifications',
            ),
          );

      // Register each channel
      for (var channel in channels) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    }

    // Set up iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        _handleLocalNotificationTap(details);
      },
    );

    // Set up notification categories for iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    }
  }

  void _handleLocalNotificationTap(NotificationResponse details) {
    if (kDebugMode) {
      print('Local notification tapped: ${details.payload}');
    }

    // If there's a specific action, handle it
    if (details.actionId != null) {
      if (kDebugMode) {
        print('Action tapped: ${details.actionId}');
      }

      // Handle different actions based on the actionId
      switch (details.actionId) {
        case 'reply':
          // Handle reply action
          break;
        case 'view':
          // Handle view action
          break;
        default:
          // Default action
          break;
      }
    } else {
      // Regular notification tap - navigate based on payload
      if (details.payload != null) {
        try {
          final data = jsonDecode(details.payload!);

          // Example: navigate based on notification type
          if (data['type'] == 'chat') {
            // Navigate to chat screen with the chatId
            final String? chatId = data['chatId'];
            if (chatId != null) {
              // Navigation will be handled by the app
            }
          } else if (data['type'] == 'announcement') {
            // Navigate to announcements screen
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing notification payload: $e');
          }
        }
      }
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Save token to Firestore for the current user
  Future<void> saveToken(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': token,
        });
        if (kDebugMode) {
          print('FCM token saved to Firestore for user: $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  // Send notification to a specific device using FCM HTTP v1 API
  Future<bool> sendNotification({
    required String recipientToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    bool highPriority = false,
    List<NotificationAction>? actions,
    String? imageUrl,
  }) async {
    try {
      // We'll just forward to the server key method since the JWT method is not working
      return sendNotificationWithServerKey(
        recipientToken: recipientToken,
        title: title,
        body: body,
        data: data,
        highPriority: highPriority,
        actions: actions,
        imageUrl: imageUrl,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
      return false;
    }
  }

  // Show a local notification with action buttons
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
    String? imageUrl,
    bool highPriority = false,
  }) async {
    try {
      // Configure android-specific details
      final androidNotificationDetails = AndroidNotificationDetails(
        highPriority ? _highPriorityChannelId : _mainChannelId,
        highPriority ? _highPriorityChannelName : _mainChannelName,
        importance: highPriority ? Importance.max : Importance.high,
        priority: highPriority ? Priority.max : Priority.high,
        styleInformation: imageUrl != null && Platform.isAndroid
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(imageUrl),
                hideExpandedLargeIcon: false,
              )
            : null,
        actions: actions
            ?.map((action) => AndroidNotificationAction(
                  action.id,
                  action.title,
                  showsUserInterface: action.foreground,
                  cancelNotification: false,
                ))
            .toList(),
      );

      // Configure iOS-specific details
      final darwinNotificationDetails = DarwinNotificationDetails(
        categoryIdentifier: 'chat',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        attachments: imageUrl != null && Platform.isIOS
            ? [DarwinNotificationAttachment(imageUrl)]
            : null,
      );

      final notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload != null ? jsonEncode(payload) : null,
      );

      if (kDebugMode) {
        print('Local notification displayed: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing local notification: $e');
      }
      rethrow;
    }
  }

  // Subscribe to a topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    if (kDebugMode) {
      print('Subscribed to topic: $topic');
    }
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('Unsubscribed from topic: $topic');
    }
  }

  // Clean up resources
  void dispose() {
    _httpClient.close();
    _authService.dispose();
  }

  // Send notification using FCM Legacy HTTP API with server key
  Future<bool> sendNotificationWithServerKey({
    required String recipientToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    bool highPriority = false,
    List<NotificationAction>? actions,
    String? imageUrl,
  }) async {
    try {
      // Load the server key if not already loaded
      if (_serverKey == null) {
        try {
          _serverKey = await rootBundle.loadString(
            'assets/credentials/server-key.txt',
          );
          _serverKey = _serverKey!.trim();
        } catch (e) {
          throw Exception(
              'Server key not found. Make sure to add your FCM server key to assets/credentials/server-key.txt');
        }
      }

      // Prepare FCM message payload
      final message = {
        'to': recipientToken,
        'priority': highPriority ? 'high' : 'normal',
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': {
          ...?data,
          if (actions != null && actions.isNotEmpty)
            'actions': jsonEncode(actions.map((a) => a.toMap()).toList()),
        },
        'android': {
          'priority': highPriority ? 'high' : 'normal',
          'notification': {
            'channel_id':
                highPriority ? _highPriorityChannelId : _mainChannelId,
            'sound': 'default',
            if (imageUrl != null) 'image': imageUrl,
          },
        },
        'apns': {
          'headers': {
            'apns-priority': highPriority ? '10' : '5',
          },
          'payload': {
            'aps': {
              'sound': 'default',
              'content-available': 1,
              'mutable-content': 1,
              if (highPriority) 'interruption-level': 'critical',
            },
          },
        },
      };

      // Send request to FCM legacy API
      final response = await _httpClient.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Notification sent successfully via Legacy FCM API');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to send notification: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification with server key: $e');
      }
      return false;
    }
  }
}

// Action button class for notifications
class NotificationAction {
  final String id;
  final String title;
  final bool foreground; // Whether action should open the app

  NotificationAction({
    required this.id,
    required this.title,
    this.foreground = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'foreground': foreground,
    };
  }
}

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
    print('Notification: ${message.notification?.title}');
    print('Data: ${message.data}');
  }

  // Check if there are any actions defined
  if (message.data.containsKey('actions')) {
    try {
      final actions = jsonDecode(message.data['actions'] as String);
      if (kDebugMode) {
        print('Message contains actions: $actions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing actions: $e');
      }
    }
  }
}

// Handle foreground messages
void _handleForegroundMessage(RemoteMessage message) {
  if (kDebugMode) {
    print('Received foreground message: ${message.messageId}');
    print('Data: ${message.data}');
  }

  // Extract notification details
  final String? title = message.notification?.title;
  final String? body = message.notification?.body;
  final String? imageUrl = message.notification?.android?.imageUrl ??
      message.notification?.apple?.imageUrl;

  // Check if there are actions in the data payload
  List<AndroidNotificationAction>? androidActions;
  if (message.data.containsKey('actions')) {
    try {
      final List<dynamic> actionsList =
          jsonDecode(message.data['actions'] as String);
      androidActions = actionsList.map((action) {
        final Map<String, dynamic> actionMap = action as Map<String, dynamic>;
        return AndroidNotificationAction(
          actionMap['id'] as String,
          actionMap['title'] as String,
          showsUserInterface: actionMap['foreground'] as bool? ?? true,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing actions: $e');
      }
    }
  }

  // Determine priority
  final bool isHighPriority = message.data['priority'] == 'high';

  if (title != null && body != null) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Configure platform-specific notification details
    final androidDetails = AndroidNotificationDetails(
      isHighPriority ? 'important_channel' : 'chat_channel',
      isHighPriority ? 'Important Notifications' : 'Chat Notifications',
      importance: isHighPriority ? Importance.max : Importance.high,
      priority: isHighPriority ? Priority.max : Priority.high,
      actions: androidActions,
      styleInformation: imageUrl != null && Platform.isAndroid
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imageUrl),
              hideExpandedLargeIcon: false,
            )
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      attachments: imageUrl != null && Platform.isIOS
          ? [DarwinNotificationAttachment(imageUrl)]
          : null,
    );

    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: jsonEncode(message.data),
    );
  }
}

// Handle when user taps on notification
void _handleNotificationTap(RemoteMessage message) {
  if (kDebugMode) {
    print('Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');
  }

  // Navigation will be handled by the app based on the data payload
  // This could involve routing to a specific screen
  // Example: Using a global navigation key to navigate to the chat screen

  // Extract relevant information from the message
  final type = message.data['type'];

  if (type == 'chat') {
    final chatId = message.data['chatId'];
    if (chatId != null) {
      // Navigate to the chat screen with this chatId
      // This would typically be handled by a navigation service or global key
    }
  } else if (type == 'announcement') {
    // Navigate to the announcements screen
  }
}
