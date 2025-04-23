# Chat App with FCM Notifications

A Flutter chat application with real-time messaging and Firebase Cloud Messaging (FCM) notifications.

## Setup

Follow these steps to set up the application:

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Set up Firebase (see below)
4. Run the app with `flutter run`

## Firebase Setup

### Firebase Project

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your project
3. Download and add the configuration files:
   - For Android: `google-services.json` to `android/app/`
   - For iOS: `GoogleService-Info.plist` to `ios/Runner/`

### FCM V1 API Setup

To use the FCM V1 HTTP API with OAuth2 authentication:

1. Create a service account:
   - Go to Firebase Console → Project Settings → Service accounts
   - Click "Generate new private key"
   - Save the JSON file securely

2. Add the service account file to your app:
   - Place the downloaded JSON file in the `assets/` directory
   - Add it to your `pubspec.yaml` assets section:
     ```yaml
     assets:
       - assets/your-service-account-file.json
     ```
   - Update the file path constant in `NotificationService.dart`:
     ```dart
     static const String _serviceAccountJsonPath = 'assets/your-service-account-file.json';
     ```

3. Security warning:
   - This implementation is for development and testing purposes
   - For production, implement token generation on a secure server
   - Never include service account credentials in production apps

## Using FCM Notifications

The app automatically:
1. Requests notification permissions on startup
2. Initializes FCM and local notifications
3. Registers device tokens to Firebase
4. Sends notifications when messages are sent

To manually send notifications:

```dart
final notificationService = GetIt.instance<NotificationService>();

// Send by user ID (looks up FCM token in Firestore)
await notificationService.sendNotificationToUser(
  recipientId: 'USER_ID',
  title: 'Message Title',
  body: 'Message content',
  data: {
    'customKey': 'customValue',
  },
  imageUrl: 'https://example.com/image.jpg', // Optional
);

// Send directly by FCM token
await notificationService.sendNotification(
  recipientToken: 'FCM_TOKEN',
  title: 'Message Title',
  body: 'Message content',
  data: {
    'customKey': 'customValue',
  }
);
```

## Troubleshooting FCM Notifications

If notifications aren't working:

1. Check debug logs for:
   - "FCM Token: <token>" - Confirms token registration
   - "Service account file prepared" - Confirms service file loading
   - "Got new FCM access token" - Confirms OAuth authentication
   - "FCM Response Status: 200" - Confirms successful delivery

2. Android-specific checks:
   - Verify notification channel creation
   - Check Android Manifest for notification permissions

3. iOS-specific checks:
   - Verify APNs setup in Firebase Console
   - Check app notification permissions

## License

[Insert your license information here]
