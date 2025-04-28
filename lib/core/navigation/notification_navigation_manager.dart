import 'dart:async';
import 'package:flutter/foundation.dart';

class NotificationNavigationEvent {
  final String route;
  final Map<String, dynamic> arguments;

  NotificationNavigationEvent({
    required this.route,
    required this.arguments,
  });
}

class NotificationNavigationManager {
  // Singleton instance
  static final NotificationNavigationManager _instance =
      NotificationNavigationManager._internal();

  factory NotificationNavigationManager() => _instance;

  NotificationNavigationManager._internal();

  // Stream controller for notification navigation events
  final _navigationEventController =
      StreamController<NotificationNavigationEvent>.broadcast();

  // Expose stream for listeners
  Stream<NotificationNavigationEvent> get navigationEvents =>
      _navigationEventController.stream;

  // Method to handle notification navigation
  void handleNotificationNavigation({
    required String route,
    required Map<String, dynamic> arguments,
  }) {
    if (kDebugMode) {
      print('NotificationNavigationManager: Requesting navigation to $route');
      print('Arguments: $arguments');
    }

    _navigationEventController.add(
      NotificationNavigationEvent(
        route: route,
        arguments: arguments,
      ),
    );
  }

  // Clean up resources
  void dispose() {
    _navigationEventController.close();
  }
}
