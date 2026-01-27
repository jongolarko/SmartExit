import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = ConfigService.baseUrl;

  // Helper to get auth headers
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await StorageService.getAccessToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // Helper to handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    return {"success": false, "error": body["error"] ?? "Request failed"};
  }

  /* =======================
        AUTH ENDPOINTS
  ======================= */

  /// Register a new user - sends OTP
  static Future<Map<String, dynamic>> register({
    required String phone,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "name": name}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Send OTP for existing user login
  static Future<Map<String, dynamic>> sendOtp({required String phone}) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Verify OTP and complete login/registration
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "otp": otp}),
      );

      final result = _handleResponse(response);

      // Save tokens and user data on successful verification
      if (result["success"] == true) {
        await StorageService.saveTokens(
          accessToken: result["token"],
          refreshToken: result["refresh_token"],
        );

        final user = result["user"];
        await StorageService.saveUser(
          id: user["id"],
          name: user["name"],
          phone: user["phone"],
          role: user["role"],
        );
      }

      return result;
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Refresh access token
  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        return {"success": false, "error": "No refresh token"};
      }

      final response = await http.post(
        Uri.parse("$baseUrl/auth/refresh-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}),
      );

      final result = _handleResponse(response);

      if (result["success"] == true) {
        await StorageService.saveTokens(
          accessToken: result["token"],
          refreshToken: result["refresh_token"],
        );
      }

      return result;
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Logout
  static Future<Map<String, dynamic>> logout({bool allDevices = false}) async {
    try {
      final headers = await _getAuthHeaders();
      final refreshToken = await StorageService.getRefreshToken();

      final response = await http.post(
        Uri.parse("$baseUrl/auth/logout"),
        headers: headers,
        body: jsonEncode({
          "refresh_token": refreshToken,
          "all_devices": allDevices,
        }),
      );

      // Clear local storage regardless of response
      await StorageService.clearAll();

      return _handleResponse(response);
    } catch (e) {
      await StorageService.clearAll();
      return {"success": true, "error": "Logged out locally"};
    }
  }

  /// Get current user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/auth/me"),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /* =======================
        CART ENDPOINTS
  ======================= */

  /// Get cart
  static Future<Map<String, dynamic>> getCart() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/cart"),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Add product to cart
  static Future<Map<String, dynamic>> addToCart({
    required String barcode,
    int quantity = 1,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/cart/add"),
        headers: headers,
        body: jsonEncode({"barcode": barcode, "quantity": quantity}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Update cart item quantity
  static Future<Map<String, dynamic>> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse("$baseUrl/cart/item/$itemId"),
        headers: headers,
        body: jsonEncode({"quantity": quantity}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Remove item from cart
  static Future<Map<String, dynamic>> removeCartItem({
    required String itemId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse("$baseUrl/cart/item/$itemId"),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Clear cart
  static Future<Map<String, dynamic>> clearCart() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse("$baseUrl/cart"),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /* =======================
      PAYMENT ENDPOINTS
  ======================= */

  /// Create payment order
  static Future<Map<String, dynamic>> createPaymentOrder() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/payment/create-order"),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Verify payment
  static Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/payment/verify"),
        headers: headers,
        body: jsonEncode({
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
          "order_id": orderId,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /* =======================
        EXIT ENDPOINTS
  ======================= */

  /// Generate exit QR token
  static Future<Map<String, dynamic>> generateExitQR({
    required String orderId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/exit/generate"),
        headers: headers,
        body: jsonEncode({"order_id": orderId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Get exit token status
  static Future<Map<String, dynamic>> getExitStatus({
    required String token,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/exit/status/$token"),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /* =======================
      SECURITY ENDPOINTS
  ======================= */

  /// Verify exit QR code
  static Future<Map<String, dynamic>> verifyExitQR({
    required String exitToken,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/security/verify-qr"),
        headers: headers,
        body: jsonEncode({"exit_token": exitToken}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Allow or deny exit
  static Future<Map<String, dynamic>> allowExit({
    required String exitToken,
    required String decision,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/security/allow-exit"),
        headers: headers,
        body: jsonEncode({"exit_token": exitToken, "decision": decision}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Get pending exits
  static Future<Map<String, dynamic>> getPendingExits() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/security/pending"),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /* =======================
        ADMIN ENDPOINTS
  ======================= */

  /// Get dashboard stats
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/admin/dashboard"),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Get orders list
  static Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      var url = "$baseUrl/admin/orders?page=$page&limit=$limit";
      if (status != null) url += "&status=$status";

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Get users list
  static Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      var url = "$baseUrl/admin/users?page=$page&limit=$limit";
      if (role != null) url += "&role=$role";

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }
}
