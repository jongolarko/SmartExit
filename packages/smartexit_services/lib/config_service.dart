/// Configuration service supporting multiple apps (Customer, Store)
class ConfigService {
  static AppConfig? _config;

  /// Initialize with app-specific configuration
  static void initialize(AppConfig config) {
    _config = config;
  }

  /// Get base API URL
  static String get baseUrl => _config?.baseUrl ?? 'http://localhost:5000/api';

  /// Get Socket.io URL
  static String get socketUrl => _config?.socketUrl ?? 'http://localhost:5000';

  /// Token expiry buffer (refresh before actual expiry)
  static const int tokenExpiryBufferSeconds = 60;
}

/// Abstract configuration for different apps
abstract class AppConfig {
  String get baseUrl;
  String get socketUrl;
}

/// Customer app configuration
class CustomerAppConfig implements AppConfig {
  @override
  final String baseUrl;

  @override
  final String socketUrl;

  CustomerAppConfig({
    this.baseUrl = 'http://localhost:5000/api',
    this.socketUrl = 'http://localhost:5000',
  });
}

/// Store app configuration (Security + Admin)
class StoreAppConfig implements AppConfig {
  @override
  final String baseUrl;

  @override
  final String socketUrl;

  StoreAppConfig({
    this.baseUrl = 'http://localhost:5000/api',
    this.socketUrl = 'http://localhost:5000',
  });
}
