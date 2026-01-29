import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartexit_services/smartexit_services.dart';

// Product model
class Product {
  final String id;
  final String barcode;
  final String name;
  final double price;
  final String? description;
  final int? stock;
  final int? reorderLevel;
  final int? maxStock;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    this.description,
    this.stock,
    this.reorderLevel,
    this.maxStock,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      description: json['description'],
      stock: json['stock'] != null ? int.tryParse(json['stock'].toString()) : null,
      reorderLevel: json['reorder_level'] != null ? int.tryParse(json['reorder_level'].toString()) : 10,
      maxStock: json['max_stock'] != null ? int.tryParse(json['max_stock'].toString()) : 1000,
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    double? price,
    String? description,
    int? stock,
    int? reorderLevel,
    int? maxStock,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      maxStock: maxStock ?? this.maxStock,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if stock is below reorder level
  bool get isLowStock => stock != null && reorderLevel != null && stock! < reorderLevel! && stock! > 0;

  /// Check if product is out of stock
  bool get isOutOfStock => stock != null && stock! == 0;

  /// Stock percentage for visual indicators
  double get stockPercentage =>
      (stock != null && maxStock != null && maxStock! > 0)
          ? (stock! / maxStock!).clamp(0, 1)
          : 0;
}

// Products state
class ProductsState {
  final bool isLoading;
  final List<Product> products;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final String searchQuery;
  final bool isSaving;

  const ProductsState({
    this.isLoading = false,
    this.products = const [],
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.searchQuery = '',
    this.isSaving = false,
  });

  ProductsState copyWith({
    bool? isLoading,
    List<Product>? products,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    String? searchQuery,
    bool? isSaving,
  }) {
    return ProductsState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// Products notifier
class ProductsNotifier extends StateNotifier<ProductsState> {
  ProductsNotifier() : super(const ProductsState());

  /// Fetch products (first page)
  Future<void> fetchProducts({String? search}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: search ?? state.searchQuery,
    );

    final result = await ApiService.getProducts(
      page: 1,
      limit: 20,
      search: search ?? state.searchQuery,
    );

    if (result['success'] == true) {
      final productsData = result['data'] as List? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        products: productsData.map((p) => Product.fromJson(p)).toList(),
        currentPage: pagination['page'] ?? 1,
        totalPages: pagination['total_pages'] ?? 1,
        hasMore: (pagination['page'] ?? 1) < (pagination['total_pages'] ?? 1),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch products',
      );
    }
  }

  /// Load more products
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    final nextPage = state.currentPage + 1;
    final result = await ApiService.getProducts(
      page: nextPage,
      limit: 20,
      search: state.searchQuery,
    );

    if (result['success'] == true) {
      final productsData = result['data'] as List? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        products: [...state.products, ...productsData.map((p) => Product.fromJson(p))],
        currentPage: pagination['page'] ?? nextPage,
        totalPages: pagination['total_pages'] ?? 1,
        hasMore: (pagination['page'] ?? nextPage) < (pagination['total_pages'] ?? 1),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Search products
  Future<void> search(String query) async {
    await fetchProducts(search: query);
  }

  /// Create product
  Future<bool> createProduct({
    required String barcode,
    required String name,
    required double price,
    String? description,
    int? stock,
    String? imageUrl,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await ApiService.createProduct(
      barcode: barcode,
      name: name,
      price: price,
      description: description,
      stock: stock,
      imageUrl: imageUrl,
    );

    if (result['success'] == true) {
      // Refresh products list
      await fetchProducts();
      state = state.copyWith(isSaving: false);
      return true;
    }

    state = state.copyWith(
      isSaving: false,
      error: result['error'] ?? 'Failed to create product',
    );
    return false;
  }

  /// Update product
  Future<bool> updateProduct({
    required String productId,
    String? name,
    double? price,
    String? description,
    int? stock,
    String? imageUrl,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await ApiService.updateProduct(
      productId: productId,
      name: name,
      price: price,
      description: description,
      stock: stock,
      imageUrl: imageUrl,
    );

    if (result['success'] == true) {
      // Update product in local list
      final updatedProduct = Product.fromJson(result['product']);
      final updatedProducts = state.products.map((p) {
        return p.id == productId ? updatedProduct : p;
      }).toList();

      state = state.copyWith(
        isSaving: false,
        products: updatedProducts,
      );
      return true;
    }

    state = state.copyWith(
      isSaving: false,
      error: result['error'] ?? 'Failed to update product',
    );
    return false;
  }

  /// Refresh products
  Future<void> refresh() async {
    await fetchProducts();
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    fetchProducts();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier();
});
