import 'dart:convert';
import 'dart:io';

import 'package:chatapp/server_injection.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/core/services/google_auth_service.dart';
import 'package:chatapp/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/features/notifications/presentation/screens/notification_details_screen.dart';

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

  // Server key for legacy notifications
  String? _serverKey;

  // For navigation
  final GlobalKey<NavigatorState>? navigatorKey;

  // Constructor with dependency injection
  NotificationService(this._authService, {this.navigatorKey});

  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize the auth service
    await _authService.initialize();

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
      criticalAlert: true,
    );

    if (Platform.isAndroid) {
      await ph.Permission.notification.request();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    // Set up Android notification channels
    AndroidInitializationSettings androidSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    if (Platform.isAndroid) {
      List<AndroidNotificationChannel> channels = const [
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
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
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

  // Send notification using FCM HTTP v1 API with JWT authentication
  Future<bool> sendNotification({
    required String recipientToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    bool highPriority = false,
    String? imageUrl,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientToken)
          .get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        if (kDebugMode) {
          print('User does not have an FCM token');
        }
        return true;
      }

      // Get access token using GoogleAuthService
      final accessToken = await _authService.getAccessToken([
        'https://www.googleapis.com/auth/firebase.messaging',
      ]);

      // Prepare the notification payload
      final Map<String, dynamic> payload = {
        "message": {
          "token": fcmToken,
          "notification": {
            "title": title,
            "body": body,
          },
          "android": {
            "priority": "high",
          },
          "apns": {
            "headers": {
              "apns-priority": "10",
            },
            "payload": {
              "aps": {
                "alert": {
                  "title": title,
                  "body": body,
                },
                "sound": "default",
              },
            },
          },
        }
      };

      // Send POST request to FCM HTTP v1 API
      final response = await _httpClient.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Notification sent successfully');
        }
      } else {
        if (kDebugMode) {
          print(
              'Failed to send notification: ${response.statusCode} ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    }
    return true;
  }

  // Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
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
        styleInformation: imageUrl != null
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(imageUrl),
                contentTitle: title,
                summaryText: body,
              )
            : null,
      );

      const iosNotificationDetails = DarwinNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // Create payload with notification data
      final notificationPayload = {
        'notificationTitle': title, // Store title as notificationTitle
        'messageContent': body, // Store body as messageContent
        ...?payload,
      };

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
        title,
        body,
        notificationDetails,
        payload: jsonEncode(notificationPayload),
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

  // Handle local notification taps
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final payloadData =
            json.decode(response.payload!) as Map<String, dynamic>;

        // Extract the sender name/title and message content
        final title = payloadData['notificationTitle'] as String? ??
            payloadData['title'] as String? ??
            'Unknown Sender';

        final body = payloadData['messageContent'] as String? ??
            payloadData['body'] as String? ??
            '';

        _navigateToNotificationDetails(title, body);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing notification payload: $e');
        }
      }
    }
  }

  // Navigate to notification details screen
  void _navigateToNotificationDetails(String title, String body) {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => NotificationDetailsScreen(
            title: title,
            body: body,
          ),
        ),
      );
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

  if (title != null && body != null) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Configure platform-specific notification details
    final androidDetails = AndroidNotificationDetails(
      message.data['priority'] == 'high' ? 'important_channel' : 'chat_channel',
      message.data['priority'] == 'high'
          ? 'Important Notifications'
          : 'Chat Notifications',
      importance:
          message.data['priority'] == 'high' ? Importance.max : Importance.high,
      priority:
          message.data['priority'] == 'high' ? Priority.max : Priority.high,
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

    // Add both notification title and message content to payload
    final payload = {
      'notificationTitle': title,
      'messageContent': body,
      ...message.data,
    };

    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: jsonEncode(payload),
    );
  }
}

// Handle when user taps on notification
void _handleNotificationTap(RemoteMessage message) {
  if (kDebugMode) {
    print('Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');
  }

  // Get the notification service instance from service locator
  final notificationService = sl<NotificationService>();

  // Extract notification details - use the title as sender name
  final title = message.notification?.title ?? 'Unknown Sender';
  final body = message.notification?.body ?? '';

  // Navigate to notification details screen
  notificationService._navigateToNotificationDetails(title, body);
}
