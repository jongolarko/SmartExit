import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Callback types for payment events
typedef PaymentSuccessCallback = void Function(PaymentSuccessResponse response);
typedef PaymentFailureCallback = void Function(PaymentFailureResponse response);
typedef ExternalWalletCallback = void Function(ExternalWalletResponse response);

/// Service to handle Razorpay payment integration
class PaymentService {
  static PaymentService? _instance;
  Razorpay? _razorpay;

  // Private constructor
  PaymentService._();

  /// Get singleton instance
  static PaymentService get instance {
    _instance ??= PaymentService._();
    return _instance!;
  }

  /// Initialize Razorpay with callbacks
  void initialize({
    required PaymentSuccessCallback onSuccess,
    required PaymentFailureCallback onFailure,
    required ExternalWalletCallback onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  /// Open Razorpay checkout with the given options
  ///
  /// Required options:
  /// - key: Razorpay API key
  /// - amount: Amount in paise (e.g., 10000 for Rs. 100)
  /// - order_id: Razorpay order ID from backend
  /// - name: Business/App name
  /// - description: Payment description
  /// - prefill: Map with 'contact' and 'email' for prefilling user details
  void openCheckout({
    required String razorpayKey,
    required int amountInPaise,
    required String razorpayOrderId,
    required String businessName,
    required String description,
    String? userPhone,
    String? userEmail,
    String? userName,
  }) {
    if (_razorpay == null) {
      throw Exception('PaymentService not initialized. Call initialize() first.');
    }

    final options = {
      'key': razorpayKey,
      'amount': amountInPaise,
      'order_id': razorpayOrderId,
      'name': businessName,
      'description': description,
      'prefill': {
        if (userPhone != null) 'contact': userPhone,
        if (userEmail != null) 'email': userEmail,
        if (userName != null) 'name': userName,
      },
      'theme': {
        'color': '#10B981', // Accent green color matching app theme
      },
    };

    _razorpay!.open(options);
  }

  /// Dispose Razorpay resources
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
