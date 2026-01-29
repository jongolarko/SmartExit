import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartexit_services/smartexit_services.dart';

// Auth state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? userId;
  final String? userName;
  final String? userPhone;
  final String? userRole;
  final String? error;
  final bool otpSent;
  final String? pendingPhone;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.userId,
    this.userName,
    this.userPhone,
    this.userRole,
    this.error,
    this.otpSent = false,
    this.pendingPhone,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? userId,
    String? userName,
    String? userPhone,
    String? userRole,
    String? error,
    bool? otpSent,
    String? pendingPhone,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userRole: userRole ?? this.userRole,
      error: error,
      otpSent: otpSent ?? this.otpSent,
      pendingPhone: pendingPhone ?? this.pendingPhone,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    state = state.copyWith(isLoading: true);

    try {
      final token = await StorageService.getAccessToken();
      if (token != null) {
        final user = await StorageService.getUser();
        if (user['id'] != null) {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            userId: user['id'],
            userName: user['name'],
            userPhone: user['phone'],
            userRole: user['role'],
          );

          // Connect to Socket.io
          await SocketService.instance.connect();

          // Initialize and register push notifications
          _initializeNotifications();
          return;
        }
      }
    } catch (e) {
      // Ignore errors
    }

    state = state.copyWith(isLoading: false);
  }

  /// Initialize push notifications and register token
  Future<void> _initializeNotifications() async {
    try {
      final initialized = await NotificationService.instance.initialize();
      if (initialized) {
        await NotificationService.instance.registerToken();
      }
    } catch (e) {
      // Notifications are optional, don't fail auth
    }
  }

  /// Register a new user (sends OTP)
  Future<bool> register(String phone, String name) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.register(phone: phone, name: name);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        otpSent: true,
        pendingPhone: phone,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] ?? 'Registration failed',
    );
    return false;
  }

  /// Send OTP for existing user
  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.sendOtp(phone: phone);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        otpSent: true,
        pendingPhone: phone,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] ?? 'Failed to send OTP',
    );
    return false;
  }

  /// Verify OTP and complete authentication
  /// If [expectedRole] is provided, validates that the user's role matches.
  Future<bool> verifyOtp(String otp, {String? expectedRole}) async {
    if (state.pendingPhone == null) {
      state = state.copyWith(error: 'No phone number pending');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.verifyOtp(
      phone: state.pendingPhone!,
      otp: otp,
      expectedRole: expectedRole,
    );

    if (result['success'] == true) {
      final user = result['user'];
      final actualRole = user['role'] as String?;

      // Validate role if expectedRole is provided
      if (expectedRole != null && actualRole != expectedRole) {
        // Clear tokens since we don't want to keep this session
        await ApiService.logout();
        state = state.copyWith(
          isLoading: false,
          error: 'This account is registered as $actualRole. Please use the correct login option.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userId: user['id'],
        userName: user['name'],
        userPhone: user['phone'],
        userRole: user['role'],
        otpSent: false,
        pendingPhone: null,
      );

      // Connect to Socket.io
      await SocketService.instance.connect();

      // Initialize and register push notifications
      _initializeNotifications();

      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] ?? 'Invalid OTP',
    );
    return false;
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    // Unregister push notification token
    try {
      await NotificationService.instance.unregisterToken();
    } catch (e) {
      // Ignore errors
    }

    await ApiService.logout();
    SocketService.instance.disconnect();

    state = const AuthState();
  }

  /// Refresh token
  Future<bool> refreshToken() async {
    final result = await ApiService.refreshToken();
    if (result['success'] == true) {
      await SocketService.instance.reconnect();
      return true;
    }
    return false;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset OTP state (go back to phone input)
  void resetOtpState() {
    state = state.copyWith(otpSent: false, pendingPhone: null);
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
