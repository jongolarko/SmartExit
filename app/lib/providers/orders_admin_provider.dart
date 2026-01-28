import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Admin Order model with full details
class AdminOrder {
  final String id;
  final String? userId;
  final String? customerName;
  final String? customerPhone;
  final double totalAmount;
  final String status;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? refundId;
  final double? refundAmount;
  final DateTime? refundedAt;
  final String? refundReason;
  final DateTime createdAt;
  final DateTime? paidAt;

  AdminOrder({
    required this.id,
    this.userId,
    this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.status,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.refundId,
    this.refundAmount,
    this.refundedAt,
    this.refundReason,
    required this.createdAt,
    this.paidAt,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: json['id'] ?? '',
      userId: json['user_id'],
      customerName: json['name'],
      customerPhone: json['phone'],
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'created',
      razorpayOrderId: json['razorpay_order_id'],
      razorpayPaymentId: json['razorpay_payment_id'],
      refundId: json['refund_id'],
      refundAmount: json['refund_amount'] != null
          ? double.tryParse(json['refund_amount'].toString())
          : null,
      refundedAt: json['refunded_at'] != null
          ? DateTime.tryParse(json['refunded_at'])
          : null,
      refundReason: json['refund_reason'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
    );
  }

  bool get canRefund => status == 'paid';
  bool get canCancel => status == 'created';
  bool get isRefunded => status == 'refunded';
  bool get isCancelled => status == 'cancelled';
}

// Order item model
class OrderItem {
  final String name;
  final String barcode;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.barcode,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }

  double get subtotal => price * quantity;
}

// Exit info model
class ExitInfo {
  final String token;
  final bool verified;
  final bool? allowed;
  final DateTime expiresAt;
  final DateTime? verifiedAt;

  ExitInfo({
    required this.token,
    required this.verified,
    this.allowed,
    required this.expiresAt,
    this.verifiedAt,
  });

  factory ExitInfo.fromJson(Map<String, dynamic> json) {
    return ExitInfo(
      token: json['exit_token'] ?? '',
      verified: json['verified'] ?? false,
      allowed: json['allowed'],
      expiresAt: DateTime.tryParse(json['expires_at'] ?? '') ?? DateTime.now(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'])
          : null,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  String get statusText {
    if (!verified) {
      return isExpired ? 'Expired' : 'Pending';
    }
    return allowed == true ? 'Allowed' : 'Denied';
  }
}

// Full order details model
class AdminOrderDetails {
  final AdminOrder order;
  final List<OrderItem> items;
  final ExitInfo? exit;

  AdminOrderDetails({
    required this.order,
    required this.items,
    this.exit,
  });

  factory AdminOrderDetails.fromJson(Map<String, dynamic> json) {
    final orderData = json['order'] as Map<String, dynamic>? ?? {};
    final itemsData = json['items'] as List? ?? [];
    final exitData = json['exit'] as Map<String, dynamic>?;

    return AdminOrderDetails(
      order: AdminOrder.fromJson(orderData),
      items: itemsData.map((i) => OrderItem.fromJson(i)).toList(),
      exit: exitData != null ? ExitInfo.fromJson(exitData) : null,
    );
  }
}

// Orders admin state
class OrdersAdminState {
  final bool isLoading;
  final List<AdminOrder> orders;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final String? statusFilter;
  final bool isProcessing;
  final AdminOrderDetails? selectedOrderDetails;

  const OrdersAdminState({
    this.isLoading = false,
    this.orders = const [],
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.statusFilter,
    this.isProcessing = false,
    this.selectedOrderDetails,
  });

  OrdersAdminState copyWith({
    bool? isLoading,
    List<AdminOrder>? orders,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    String? statusFilter,
    bool? isProcessing,
    AdminOrderDetails? selectedOrderDetails,
    bool clearSelectedOrderDetails = false,
  }) {
    return OrdersAdminState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      statusFilter: statusFilter ?? this.statusFilter,
      isProcessing: isProcessing ?? this.isProcessing,
      selectedOrderDetails: clearSelectedOrderDetails
          ? null
          : (selectedOrderDetails ?? this.selectedOrderDetails),
    );
  }
}

// Orders admin notifier
class OrdersAdminNotifier extends StateNotifier<OrdersAdminState> {
  OrdersAdminNotifier() : super(const OrdersAdminState());

  /// Fetch orders (first page)
  Future<void> fetchOrders({String? status}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      statusFilter: status,
    );

    final result = await ApiService.getOrders(
      page: 1,
      limit: 20,
      status: status,
    );

    if (result['success'] == true) {
      final ordersData = result['data'] as List? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        orders: ordersData.map((o) => AdminOrder.fromJson(o)).toList(),
        currentPage: pagination['page'] ?? 1,
        totalPages: pagination['totalPages'] ?? 1,
        hasMore: (pagination['page'] ?? 1) < (pagination['totalPages'] ?? 1),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch orders',
      );
    }
  }

  /// Load more orders
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    final nextPage = state.currentPage + 1;
    final result = await ApiService.getOrders(
      page: nextPage,
      limit: 20,
      status: state.statusFilter,
    );

    if (result['success'] == true) {
      final ordersData = result['data'] as List? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        orders: [...state.orders, ...ordersData.map((o) => AdminOrder.fromJson(o))],
        currentPage: pagination['page'] ?? nextPage,
        totalPages: pagination['totalPages'] ?? 1,
        hasMore: (pagination['page'] ?? nextPage) < (pagination['totalPages'] ?? 1),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Set status filter
  Future<void> setStatusFilter(String? status) async {
    await fetchOrders(status: status);
  }

  /// Fetch order details
  Future<void> fetchOrderDetails(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.getAdminOrderDetails(orderId: orderId);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        selectedOrderDetails: AdminOrderDetails.fromJson(result),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch order details',
      );
    }
  }

  /// Refund order
  Future<bool> refundOrder({
    required String orderId,
    double? amount,
    String? reason,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await ApiService.refundOrder(
      orderId: orderId,
      amount: amount,
      reason: reason,
    );

    if (result['success'] == true) {
      // Update order in list
      final updatedOrders = state.orders.map((o) {
        if (o.id == orderId) {
          return AdminOrder(
            id: o.id,
            userId: o.userId,
            customerName: o.customerName,
            customerPhone: o.customerPhone,
            totalAmount: o.totalAmount,
            status: 'refunded',
            razorpayOrderId: o.razorpayOrderId,
            razorpayPaymentId: o.razorpayPaymentId,
            refundId: result['refund']?['id'],
            refundAmount: amount ?? o.totalAmount,
            refundedAt: DateTime.now(),
            refundReason: reason,
            createdAt: o.createdAt,
            paidAt: o.paidAt,
          );
        }
        return o;
      }).toList();

      state = state.copyWith(
        isProcessing: false,
        orders: updatedOrders,
        clearSelectedOrderDetails: true,
      );

      // Refresh order details if viewing
      if (state.selectedOrderDetails?.order.id == orderId) {
        await fetchOrderDetails(orderId);
      }

      return true;
    }

    state = state.copyWith(
      isProcessing: false,
      error: result['error'] ?? 'Failed to process refund',
    );
    return false;
  }

  /// Cancel order
  Future<bool> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await ApiService.cancelOrder(
      orderId: orderId,
      reason: reason,
    );

    if (result['success'] == true) {
      // Update order in list
      final updatedOrders = state.orders.map((o) {
        if (o.id == orderId) {
          return AdminOrder(
            id: o.id,
            userId: o.userId,
            customerName: o.customerName,
            customerPhone: o.customerPhone,
            totalAmount: o.totalAmount,
            status: 'cancelled',
            razorpayOrderId: o.razorpayOrderId,
            razorpayPaymentId: o.razorpayPaymentId,
            refundId: o.refundId,
            refundAmount: o.refundAmount,
            refundedAt: o.refundedAt,
            refundReason: o.refundReason,
            createdAt: o.createdAt,
            paidAt: o.paidAt,
          );
        }
        return o;
      }).toList();

      state = state.copyWith(
        isProcessing: false,
        orders: updatedOrders,
        clearSelectedOrderDetails: true,
      );

      return true;
    }

    state = state.copyWith(
      isProcessing: false,
      error: result['error'] ?? 'Failed to cancel order',
    );
    return false;
  }

  /// Clear selected order
  void clearSelectedOrder() {
    state = state.copyWith(clearSelectedOrderDetails: true);
  }

  /// Refresh orders
  Future<void> refresh() async {
    await fetchOrders(status: state.statusFilter);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final ordersAdminProvider = StateNotifierProvider<OrdersAdminNotifier, OrdersAdminState>((ref) {
  return OrdersAdminNotifier();
});
