import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartexit_services/smartexit_services.dart';

// Product search result model
class ProductSearchResult {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final String? category;
  final String? description;
  final String? imageUrl;
  final int? stock;
  final double? rank;

  ProductSearchResult({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.category,
    this.description,
    this.imageUrl,
    this.stock,
    this.rank,
  });

  factory ProductSearchResult.fromJson(Map<String, dynamic> json) {
    return ProductSearchResult(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      category: json['category'],
      description: json['description'],
      imageUrl: json['image_url'],
      stock: json['stock'],
      rank: double.tryParse(json['rank']?.toString() ?? '0'),
    );
  }
}

// Category model
class ProductCategory {
  final String name;
  final int productCount;

  ProductCategory({required this.name, required this.productCount});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      name: json['category'] ?? '',
      productCount: int.tryParse(json['product_count']?.toString() ?? '0') ?? 0,
    );
  }
}

// Search state
class SearchState {
  final bool isLoading;
  final List<ProductSearchResult> results;
  final String query;
  final String? category;
  final String? error;
  final bool fuzzyMatch;
  final List<String> recentSearches;

  const SearchState({
    this.isLoading = false,
    this.results = const [],
    this.query = '',
    this.category,
    this.error,
    this.fuzzyMatch = false,
    this.recentSearches = const [],
  });

  SearchState copyWith({
    bool? isLoading,
    List<ProductSearchResult>? results,
    String? query,
    String? category,
    String? error,
    bool? fuzzyMatch,
    List<String>? recentSearches,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      query: query ?? this.query,
      category: category ?? this.category,
      error: error,
      fuzzyMatch: fuzzyMatch ?? this.fuzzyMatch,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

// Search provider
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState()) {
    _loadRecentSearches();
  }

  Timer? _debounceTimer;

  // Load recent searches from storage
  Future<void> _loadRecentSearches() async {
    final searches = await StorageService.getRecentSearches();
    state = state.copyWith(recentSearches: searches);
  }

  // Save search to recent searches
  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    final searches = List<String>.from(state.recentSearches);
    searches.remove(query); // Remove if exists
    searches.insert(0, query); // Add to front
    if (searches.length > 10) {
      searches.removeRange(10, searches.length); // Keep only 10
    }

    await StorageService.saveRecentSearches(searches);
    state = state.copyWith(recentSearches: searches);
  }

  // Clear recent searches
  Future<void> clearRecentSearches() async {
    await StorageService.clearRecentSearches();
    state = state.copyWith(recentSearches: []);
  }

  // Search products (with debounce)
  void searchProducts(String query, {String? category}) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update query immediately
    state = state.copyWith(query: query, category: category);

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], error: null);
      return;
    }

    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query, category: category);
    });
  }

  // Perform actual search
  Future<void> _performSearch(String query, {String? category}) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.searchProducts(
        query: query,
        category: category,
        limit: 20,
      );

      if (response['success'] == true) {
        final products = (response['products'] as List?)
            ?.map((json) => ProductSearchResult.fromJson(json))
            .toList() ??
            [];

        final fuzzyMatch = response['fuzzy_match'] ?? false;

        state = state.copyWith(
          isLoading: false,
          results: products,
          fuzzyMatch: fuzzyMatch,
        );

        // Save to recent searches
        await _saveRecentSearch(query);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['error'] ?? 'Search failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: $e',
      );
    }
  }

  // Search immediately (without debounce)
  Future<void> searchImmediate(String query, {String? category}) async {
    _debounceTimer?.cancel();
    state = state.copyWith(query: query, category: category);
    await _performSearch(query, category: category);
  }

  // Clear search
  void clearSearch() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }

  // Set category filter
  void setCategory(String? category) {
    final query = state.query;
    if (query.isNotEmpty) {
      searchImmediate(query, category: category);
    } else {
      state = state.copyWith(category: category);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

// Categories provider
final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final response = await ApiService.getCategories();

  if (response['success'] == true) {
    return (response['categories'] as List?)
        ?.map((json) => ProductCategory.fromJson(json))
        .toList() ??
        [];
  }

  return [];
});

// Popular products provider
final popularProductsProvider = FutureProvider<List<ProductSearchResult>>((ref) async {
  final response = await ApiService.getPopularProducts(limit: 10);

  if (response['success'] == true) {
    return (response['products'] as List?)
        ?.map((json) => ProductSearchResult.fromJson(json))
        .toList() ??
        [];
  }

  return [];
});
