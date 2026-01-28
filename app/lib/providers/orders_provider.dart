import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Order model
class Order {
  final String id;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final int itemCount;

  Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.paidAt,
    required this.itemCount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
      itemCount: int.tryParse(json['item_count']?.toString() ?? '0') ?? 0,
    );
  }
}

// Order item model
class OrderItem {
  final String id;
  final int quantity;
  final double price;
  final String name;
  final String barcode;
  final String? description;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.quantity,
    required this.price,
    required this.name,
    required this.barcode,
    this.description,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
    );
  }

  double get totalPrice => quantity * price;
}

// Exit status model
class ExitStatus {
  final String exitToken;
  final bool verified;
  final bool? allowed;
  final DateTime expiresAt;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  ExitStatus({
    required this.exitToken,
    required this.verified,
    this.allowed,
    required this.expiresAt,
    this.verifiedAt,
    required this.createdAt,
  });

  factory ExitStatus.fromJson(Map<String, dynamic> json) {
    return ExitStatus(
      exitToken: json['exit_token'] ?? '',
      verified: json['verified'] ?? false,
      allowed: json['allowed'],
      expiresAt: DateTime.tryParse(json['expires_at'] ?? '') ?? DateTime.now(),
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at']) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get statusText {
    if (verified) {
      return allowed == true ? 'Exit Approved' : 'Exit Denied';
    }
    if (isExpired) {
      return 'Token Expired';
    }
    return 'Pending Verification';
  }
}

// Order detail model
class OrderDetail {
  final Order order;
  final List<OrderItem> items;
  final ExitStatus? exitStatus;

  OrderDetail({
    required this.order,
    required this.items,
    this.exitStatus,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final orderData = json['order'] as Map<String, dynamic>? ?? {};
    final itemsData = json['items'] as List? ?? [];
    final exitData = json['exit'] as Map<String, dynamic>?;

    return OrderDetail(
      order: Order.fromJson({
        ...orderData,
        'item_count': itemsData.length,
      }),
      items: itemsData.map((item) => OrderItem.fromJson(item)).toList(),
      exitStatus: exitData != null ? ExitStatus.fromJson(exitData) : null,
    );
  }
}

// Orders state
class OrdersState {
  final bool isLoading;
  final List<Order> orders;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const OrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
  });

  OrdersState copyWith({
    bool? isLoading,
    List<Order>? orders,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Orders notifier
class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier() : super(const OrdersState());

  /// Fetch orders (first page)
  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.getMyOrders(page: 1, limit: 20);

    if (result['success'] == true) {
      final ordersData = result['data'] as List? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        orders: ordersData.map((o) => Order.fromJson(o)).toList(),
        currentPage: pagination['page'] ?? 1,
        totalPages: pagination['total_pages'] ?? 1,
        hasMore: (pagination['page'] ?? 1) < (pagination['total_pages'] ?? 1),
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
    final result = await ApiService.getMyOrders(page: nextPage, limit: 20);

    if (result['success'] == true) {
      final ordersData = result['data'] as List? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        orders: [...state.orders, ...ordersData.map((o) => Order.fromJson(o))],
        currentPage: pagination['page'] ?? nextPage,
        totalPages: pagination['total_pages'] ?? 1,
        hasMore: (pagination['page'] ?? nextPage) < (pagination['total_pages'] ?? 1),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh orders
  Future<void> refresh() async {
    await fetchOrders();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier();
});

// Order detail state
class OrderDetailState {
  final bool isLoading;
  final OrderDetail? detail;
  final String? error;

  const OrderDetailState({
    this.isLoading = false,
    this.detail,
    this.error,
  });

  OrderDetailState copyWith({
    bool? isLoading,
    OrderDetail? detail,
    String? error,
  }) {
    return OrderDetailState(
      isLoading: isLoading ?? this.isLoading,
      detail: detail ?? this.detail,
      error: error,
    );
  }
}

// Order detail notifier
class OrderDetailNotifier extends StateNotifier<OrderDetailState> {
  OrderDetailNotifier() : super(const OrderDetailState());

  /// Fetch order details
  Future<void> fetchOrderDetails(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.getOrderDetails(orderId: orderId);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        detail: OrderDetail.fromJson(result),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch order details',
      );
    }
  }

  /// Clear state
  void clear() {
    state = const OrderDetailState();
  }
}

// Provider
final orderDetailProvider = StateNotifierProvider<OrderDetailNotifier, OrderDetailState>((ref) {
  return OrderDetailNotifier();
});
