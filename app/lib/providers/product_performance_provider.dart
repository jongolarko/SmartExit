import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Models
class TopProduct {
  final String id;
  final String name;
  final String barcode;
  final double revenue;
  final int unitsSold;

  TopProduct({
    required this.id,
    required this.name,
    required this.barcode,
    required this.revenue,
    required this.unitsSold,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      revenue: double.parse(json['revenue'].toString()),
      unitsSold: int.parse(json['unitsSold'].toString()),
    );
  }
}

class SlowMover {
  final String id;
  final String name;
  final String barcode;
  final int stock;
  final int daysSinceLastSale;

  SlowMover({
    required this.id,
    required this.name,
    required this.barcode,
    required this.stock,
    required this.daysSinceLastSale,
  });

  factory SlowMover.fromJson(Map<String, dynamic> json) {
    return SlowMover(
      id: json['id'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      stock: int.parse(json['stock'].toString()),
      daysSinceLastSale: int.parse(json['daysSinceLastSale'].toString()),
    );
  }
}

class TurnoverData {
  final String productName;
  final double turnoverRate;

  TurnoverData({
    required this.productName,
    required this.turnoverRate,
  });

  factory TurnoverData.fromJson(Map<String, dynamic> json) {
    return TurnoverData(
      productName: json['productName'] as String,
      turnoverRate: double.parse(json['turnoverRate'].toString()),
    );
  }
}

// State
class ProductPerformanceState {
  final bool isLoading;
  final String selectedMetric;
  final List<TopProduct> topProducts;
  final List<SlowMover> slowMovers;
  final List<TurnoverData> turnoverData;
  final String? error;

  ProductPerformanceState({
    this.isLoading = false,
    this.selectedMetric = 'revenue',
    this.topProducts = const [],
    this.slowMovers = const [],
    this.turnoverData = const [],
    this.error,
  });

  ProductPerformanceState copyWith({
    bool? isLoading,
    String? selectedMetric,
    List<TopProduct>? topProducts,
    List<SlowMover>? slowMovers,
    List<TurnoverData>? turnoverData,
    String? error,
  }) {
    return ProductPerformanceState(
      isLoading: isLoading ?? this.isLoading,
      selectedMetric: selectedMetric ?? this.selectedMetric,
      topProducts: topProducts ?? this.topProducts,
      slowMovers: slowMovers ?? this.slowMovers,
      turnoverData: turnoverData ?? this.turnoverData,
      error: error ?? this.error,
    );
  }
}

// Notifier
class ProductPerformanceNotifier extends StateNotifier<ProductPerformanceState> {
  ProductPerformanceNotifier() : super(ProductPerformanceState());

  Future<void> fetchTopProducts({String metric = 'revenue', int limit = 10}) async {
    state = state.copyWith(isLoading: true, error: null, selectedMetric: metric);
    try {
      final data = await ApiService.getTopProducts(metric: metric, limit: limit);

      final List<TopProduct> topProducts = (data['topProducts'] as List)
          .map((item) => TopProduct.fromJson(item))
          .toList();

      state = state.copyWith(
        isLoading: false,
        topProducts: topProducts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Error fetching top products: $e');
    }
  }

  Future<void> fetchSlowMovers() async {
    try {
      final data = await ApiService.getSlowMovers();

      final List<SlowMover> slowMovers = (data['slowMovers'] as List)
          .map((item) => SlowMover.fromJson(item))
          .toList();

      state = state.copyWith(slowMovers: slowMovers);
    } catch (e) {
      debugPrint('Error fetching slow movers: $e');
    }
  }

  Future<void> fetchStockTurnover() async {
    try {
      final data = await ApiService.getStockTurnover();

      final List<TurnoverData> turnoverData = (data['turnover'] as List)
          .map((item) => TurnoverData.fromJson(item))
          .toList();

      state = state.copyWith(turnoverData: turnoverData);
    } catch (e) {
      debugPrint('Error fetching stock turnover: $e');
    }
  }

  Future<void> fetchAllData({String metric = 'revenue'}) async {
    await Future.wait([
      fetchTopProducts(metric: metric),
      fetchSlowMovers(),
      fetchStockTurnover(),
    ]);
  }

  void setMetric(String metric) {
    if (metric != state.selectedMetric) {
      fetchTopProducts(metric: metric);
    }
  }
}

// Provider
final productPerformanceProvider =
    StateNotifierProvider<ProductPerformanceNotifier, ProductPerformanceState>((ref) {
  return ProductPerformanceNotifier();
});
