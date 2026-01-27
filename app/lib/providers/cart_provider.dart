import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

// Cart item model
class CartItem {
  final String itemId;
  final String productId;
  final String barcode;
  final String name;
  final String? description;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  CartItem({
    required this.itemId,
    required this.productId,
    required this.barcode,
    required this.name,
    this.description,
    this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      itemId: json['item_id'] ?? '',
      productId: json['product_id'] ?? '',
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      quantity: json['quantity'] ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
    );
  }
}

// Cart state
class CartState {
  final bool isLoading;
  final List<CartItem> items;
  final double total;
  final int itemCount;
  final String? error;
  final String? lastAddedProduct;

  const CartState({
    this.isLoading = false,
    this.items = const [],
    this.total = 0,
    this.itemCount = 0,
    this.error,
    this.lastAddedProduct,
  });

  CartState copyWith({
    bool? isLoading,
    List<CartItem>? items,
    double? total,
    int? itemCount,
    String? error,
    String? lastAddedProduct,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      total: total ?? this.total,
      itemCount: itemCount ?? this.itemCount,
      error: error,
      lastAddedProduct: lastAddedProduct,
    );
  }
}

// Cart notifier
class CartNotifier extends StateNotifier<CartState> {
  StreamSubscription? _socketSubscription;

  CartNotifier() : super(const CartState()) {
    _listenToSocketUpdates();
  }

  void _listenToSocketUpdates() {
    _socketSubscription = SocketService.instance.cartUpdates.listen((data) {
      _updateFromSocketData(data);
    });
  }

  void _updateFromSocketData(Map<String, dynamic> data) {
    final items = (data['items'] as List?)
            ?.map((item) => CartItem.fromJson(item))
            .toList() ??
        [];

    state = state.copyWith(
      items: items,
      total: double.tryParse(data['total']?.toString() ?? '0') ?? 0,
      itemCount: data['item_count'] ?? 0,
    );
  }

  /// Fetch cart from API
  Future<void> fetchCart() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.getCart();

    if (result['success'] == true) {
      final items = (result['items'] as List?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [];

      state = state.copyWith(
        isLoading: false,
        items: items,
        total: double.tryParse(result['total']?.toString() ?? '0') ?? 0,
        itemCount: result['item_count'] ?? 0,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch cart',
      );
    }
  }

  /// Add product to cart
  Future<bool> addToCart(String barcode, {int quantity = 1}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.addToCart(
      barcode: barcode,
      quantity: quantity,
    );

    if (result['success'] == true) {
      final items = (result['items'] as List?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          state.items;

      state = state.copyWith(
        isLoading: false,
        items: items,
        total: double.tryParse(result['total']?.toString() ?? '0') ?? state.total,
        itemCount: result['item_count'] ?? state.itemCount,
        lastAddedProduct: barcode,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] ?? 'Failed to add to cart',
    );
    return false;
  }

  /// Update cart item quantity
  Future<bool> updateQuantity(String itemId, int quantity) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.updateCartItem(
      itemId: itemId,
      quantity: quantity,
    );

    if (result['success'] == true) {
      final items = (result['items'] as List?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          state.items;

      state = state.copyWith(
        isLoading: false,
        items: items,
        total: double.tryParse(result['total']?.toString() ?? '0') ?? state.total,
        itemCount: result['item_count'] ?? state.itemCount,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] ?? 'Failed to update cart',
    );
    return false;
  }

  /// Remove item from cart
  Future<bool> removeItem(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.removeCartItem(itemId: itemId);

    if (result['success'] == true) {
      final items = (result['items'] as List?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [];

      state = state.copyWith(
        isLoading: false,
        items: items,
        total: double.tryParse(result['total']?.toString() ?? '0') ?? 0,
        itemCount: result['item_count'] ?? 0,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] ?? 'Failed to remove item',
    );
    return false;
  }

  /// Clear cart
  Future<bool> clearCart() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.clearCart();

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        items: [],
        total: 0,
        itemCount: 0,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] ?? 'Failed to clear cart',
    );
    return false;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear last added product notification
  void clearLastAdded() {
    state = state.copyWith(lastAddedProduct: null);
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }
}

// Provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
