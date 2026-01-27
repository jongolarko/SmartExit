import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Keys
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserPhone = 'user_phone';
  static const _keyUserRole = 'user_role';

  // Token methods
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  // User methods
  static Future<void> saveUser({
    required String id,
    required String name,
    required String phone,
    required String role,
  }) async {
    await _storage.write(key: _keyUserId, value: id);
    await _storage.write(key: _keyUserName, value: name);
    await _storage.write(key: _keyUserPhone, value: phone);
    await _storage.write(key: _keyUserRole, value: role);
  }

  static Future<Map<String, String?>> getUser() async {
    return {
      'id': await _storage.read(key: _keyUserId),
      'name': await _storage.read(key: _keyUserName),
      'phone': await _storage.read(key: _keyUserPhone),
      'role': await _storage.read(key: _keyUserRole),
    };
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  static Future<void> clearUser() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserName);
    await _storage.delete(key: _keyUserPhone);
    await _storage.delete(key: _keyUserRole);
  }

  // Clear all
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
