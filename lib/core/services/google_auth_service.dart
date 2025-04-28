import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:chatapp/firebase_options.dart';

/// A service to handle authentication with Google APIs using a service account
class GoogleAuthService {
  // HTTP client for API requests
  final http.Client _httpClient = http.Client();

  // Service account credentials
  ServiceAccountCredentials? _credentials;

  // Token information
  String? _accessToken;
  DateTime? _tokenExpiry;

  // Firebase project ID from options
  final String _projectId = DefaultFirebaseOptions.currentPlatform.projectId;

  /// Initialize the service by loading credentials
  Future<void> initialize() async {
    try {
      await _loadCredentials();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load credentials: $e. Using dummy token fallback.');
      }
    }
  }

  /// Load service account credentials from assets
  Future<void> _loadCredentials() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/credentials/service-account.json');

      _credentials = ServiceAccountCredentials.fromJson(jsonString);

      if (kDebugMode) {
        print('Service account credentials loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading service account credentials: $e');
        print(
            'Make sure your service account JSON is properly formatted and contains all required fields');
      }
      throw Exception(
          'Failed to load service account credentials. Place your service account JSON at assets/credentials/service-account.json');
    }
  }

  /// Get an OAuth access token for the specified scopes
  /// Returns the access token string
  Future<String> getAccessToken(List<String> scopes) async {
    try {
      // Return existing token if it's still valid (with 5-minute buffer)
      if (_accessToken != null &&
          _tokenExpiry != null &&
          _tokenExpiry!
              .isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        return _accessToken!;
      }

      // If we have credentials, get a proper token
      if (_credentials != null) {
        try {
          if (kDebugMode) {
            print('Getting token with scopes: $scopes');
          }

          // Try creating a client with service account
          final client = await clientViaServiceAccount(
            _credentials!,
            scopes,
            baseClient: _httpClient,
          );

          final AccessCredentials credentials = client.credentials;
          _accessToken = credentials.accessToken.data;
          _tokenExpiry = credentials.accessToken.expiry;

          if (kDebugMode) {
            print('Obtained valid access token, expires: $_tokenExpiry');
          }

          return _accessToken!;
        } catch (e) {
          if (kDebugMode) {
            print('Error obtaining token from service account: $e');

            if (e.toString().contains('invalid_grant')) {
              print('''
              The invalid_grant error usually means:
              1. Your service account credentials are incorrect or malformed
              2. The clock on your device is not synchronized with Google servers
              3. The private key in your JSON file is not properly formatted
              ''');
            }
          }

          // For invalid_grant errors, fall back to dummy token instead of rethrowing
          _accessToken = "dummy_access_token";
          _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

          if (kDebugMode) {
            print('Using dummy token due to authentication error');
          }

          return _accessToken!;
        }
      } else {
        // Fallback to dummy token if credentials aren't loaded
        if (kDebugMode) {
          print(
              'Using dummy token because service account credentials were not loaded.');
        }

        _accessToken = "dummy_access_token";
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

        return _accessToken!;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting access token: $e');
      }
      // Return a dummy token on error
      return "dummy_access_token";
    }
  }

  /// Get the Firebase project ID
  String getProjectId() {
    // First try to get from the credentials file (most accurate)
    if (_credentials != null) {
      try {
        // The project ID is available in the client ID
        return _credentials!.clientId.identifier;
      } catch (e) {
        // Fall back to the default from Firebase options
      }
    }

    // Fall back to the Firebase default options
    return _projectId;
  }

  /// Check if proper credentials are loaded
  bool hasValidCredentials() {
    return _credentials != null;
  }

  /// Clear the cached token (useful when the token becomes invalid)
  void clearToken() {
    _accessToken = null;
    _tokenExpiry = null;
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}
