import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}

/// Service for handling Firebase Cloud Messaging push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  FirebaseMessaging? _messaging;
  String? _fcmToken;
  bool _initialized = false;

  /// Get the FCM token
  String? get fcmToken => _fcmToken;

  /// Check if the service is initialized
  bool get isInitialized => _initialized;

  /// Initialize Firebase and notifications
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      _messaging = FirebaseMessaging.instance;

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('Push notification permission granted');

        // Get FCM token
        _fcmToken = await _messaging!.getToken();
        debugPrint('FCM Token: $_fcmToken');

        // Listen for token refresh
        _messaging!.onTokenRefresh.listen(_handleTokenRefresh);

        // Set up foreground notification handling
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification tap when app was terminated
        final initialMessage = await _messaging!.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        // Handle notification tap when app was in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        _initialized = true;
        return true;
      } else {
        debugPrint('Push notification permission denied');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      return false;
    }
  }

  /// Register the current FCM token with the backend
  Future<bool> registerToken() async {
    if (_fcmToken == null) {
      debugPrint('No FCM token available');
      return false;
    }

    // Check if user is logged in
    final token = await StorageService.getAccessToken();
    if (token == null) {
      debugPrint('User not logged in, skipping token registration');
      return false;
    }

    try {
      final platform = _getPlatform();
      final result = await ApiService.registerDeviceToken(
        token: _fcmToken!,
        platform: platform,
      );

      if (result['success'] == true) {
        debugPrint('FCM token registered with backend');
        return true;
      } else {
        debugPrint('Failed to register FCM token: ${result['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
      return false;
    }
  }

  /// Unregister the FCM token from the backend (call on logout)
  Future<bool> unregisterToken() async {
    if (_fcmToken == null) return true;

    try {
      final result = await ApiService.unregisterDeviceToken(token: _fcmToken!);
      debugPrint('FCM token unregistered: ${result['success']}');
      return result['success'] == true;
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
      return false;
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String newToken) {
    debugPrint('FCM Token refreshed: $newToken');
    _fcmToken = newToken;
    // Re-register with backend
    registerToken();
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');

    final notification = message.notification;
    if (notification != null) {
      debugPrint('Notification: ${notification.title} - ${notification.body}');
      // You could show a local notification or in-app toast here
      _onNotificationReceived?.call(
        notification.title ?? '',
        notification.body ?? '',
        message.data,
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');

    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'payment_success':
        _onNotificationTapped?.call('payment_success', data);
        break;
      case 'exit_approved':
        _onNotificationTapped?.call('exit_approved', data);
        break;
      case 'exit_denied':
        _onNotificationTapped?.call('exit_denied', data);
        break;
      default:
        _onNotificationTapped?.call(type ?? 'unknown', data);
    }
  }

  /// Get platform string for API
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'android'; // Default
  }

  // Callback for when notification is received in foreground
  void Function(String title, String body, Map<String, dynamic> data)?
      _onNotificationReceived;

  // Callback for when notification is tapped
  void Function(String type, Map<String, dynamic> data)? _onNotificationTapped;

  /// Set callback for foreground notifications
  void setOnNotificationReceived(
    void Function(String title, String body, Map<String, dynamic> data)? callback,
  ) {
    _onNotificationReceived = callback;
  }

  /// Set callback for notification tap
  void setOnNotificationTapped(
    void Function(String type, Map<String, dynamic> data)? callback,
  ) {
    _onNotificationTapped = callback;
  }
}
