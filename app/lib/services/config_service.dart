class ConfigService {
  // Change this to your backend server IP/URL
  // For emulator: 10.0.2.2
  // For real device: your LAN IP (e.g., 192.168.0.116)
  // For production: your server URL
  static const String baseUrl = "http://localhost:5000/api";
  static const String socketUrl = "http://localhost:5000";

  // Token expiry buffer (refresh before actual expiry)
  static const int tokenExpiryBufferSeconds = 60;
}
