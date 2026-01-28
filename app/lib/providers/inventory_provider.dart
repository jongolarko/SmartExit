import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Stock audit log entry model
class StockAuditLog {
  final String id;
  final String productId;
  final String productName;
  final String? barcode;
  final String changeType;
  final int quantityChange;
  final int? quantityBefore;
  final int? quantityAfter;
  final String? reason;
  final String? performedByName;
  final DateTime createdAt;

  StockAuditLog({
    required this.id,
    required this.productId,
    required this.productName,
    this.barcode,
    required this.changeType,
    required this.quantityChange,
    this.quantityBefore,
    this.quantityAfter,
    this.reason,
    this.performedByName,
    required this.createdAt,
  });

  factory StockAuditLog.fromJson(Map<String, dynamic> json) {
    return StockAuditLog(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      barcode: json['barcode'],
      changeType: json['change_type'] ?? '',
      quantityChange: json['quantity_change'] ?? 0,
      quantityBefore: json['quantity_before'],
      quantityAfter: json['quantity_after'],
      reason: json['reason'],
      performedByName: json['performed_by_name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get changeTypeDisplay {
    switch (changeType) {
      case 'sale':
        return 'Sale';
      case 'adjustment':
        return 'Adjustment';
      case 'receipt':
        return 'Receipt';
      case 'damage':
        return 'Damage';
      case 'return':
        return 'Return';
      case 'correction':
        return 'Correction';
      default:
        return changeType;
    }
  }

  bool get isAddition => quantityChange > 0;
}

// Low stock product model
class LowStockProduct {
  final String id;
  final String barcode;
  final String name;
  final int stock;
  final int reorderLevel;
  final int maxStock;
  final double price;
  final int recentMovements;

  LowStockProduct({
    required this.id,
    required this.barcode,
    required this.name,
    required this.stock,
    required this.reorderLevel,
    required this.maxStock,
    required this.price,
    required this.recentMovements,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      id: json['id'] ?? '',
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      stock: json['stock'] ?? 0,
      reorderLevel: json['reorder_level'] ?? 10,
      maxStock: json['max_stock'] ?? 1000,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      recentMovements: json['recent_movements'] ?? 0,
    );
  }

  bool get isOutOfStock => stock == 0;
  bool get isCritical => stock <= reorderLevel / 2;
  double get stockPercentage => maxStock > 0 ? (stock / maxStock).clamp(0, 1) : 0;
}

// Inventory summary model
class InventorySummary {
  final int lowStockCount;
  final int outOfStockCount;
  final int healthyStockCount;
  final int totalProducts;
  final double totalInventoryValue;

  InventorySummary({
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.healthyStockCount,
    required this.totalProducts,
    required this.totalInventoryValue,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      lowStockCount: json['low_stock_count'] ?? 0,
      outOfStockCount: json['out_of_stock_count'] ?? 0,
      healthyStockCount: json['healthy_stock_count'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      totalInventoryValue:
          double.tryParse(json['total_inventory_value']?.toString() ?? '0') ?? 0,
    );
  }
}

// Report summary model
class ReportSummary {
  final int totalSold;
  final int totalReceived;
  final int totalDamaged;
  final int totalReturned;

  ReportSummary({
    required this.totalSold,
    required this.totalReceived,
    required this.totalDamaged,
    required this.totalReturned,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalSold: json['total_sold'] ?? 0,
      totalReceived: json['total_received'] ?? 0,
      totalDamaged: json['total_damaged'] ?? 0,
      totalReturned: json['total_returned'] ?? 0,
    );
  }
}

// Inventory state
class InventoryState {
  final bool isLoading;
  final List<LowStockProduct> lowStockProducts;
  final InventorySummary? summary;
  final List<StockAuditLog> stockMovements;
  final ReportSummary? reportSummary;
  final String? error;
  final bool isAdjusting;

  const InventoryState({
    this.isLoading = false,
    this.lowStockProducts = const [],
    this.summary,
    this.stockMovements = const [],
    this.reportSummary,
    this.error,
    this.isAdjusting = false,
  });

  InventoryState copyWith({
    bool? isLoading,
    List<LowStockProduct>? lowStockProducts,
    InventorySummary? summary,
    List<StockAuditLog>? stockMovements,
    ReportSummary? reportSummary,
    String? error,
    bool? isAdjusting,
  }) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      summary: summary ?? this.summary,
      stockMovements: stockMovements ?? this.stockMovements,
      reportSummary: reportSummary ?? this.reportSummary,
      error: error,
      isAdjusting: isAdjusting ?? this.isAdjusting,
    );
  }
}

// Inventory notifier
class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier() : super(const InventoryState());

  /// Fetch low stock products and summary
  Future<void> fetchLowStock() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.getLowStockProducts();

    if (result['success'] == true) {
      final productsData = result['products'] as List? ?? [];
      final summaryData = result['summary'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        lowStockProducts:
            productsData.map((p) => LowStockProduct.fromJson(p)).toList(),
        summary: InventorySummary.fromJson(summaryData),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch low stock products',
      );
    }
  }

  /// Fetch stock movement report
  Future<void> fetchStockReport({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.getInventoryReport(
      startDate: startDate,
      endDate: endDate,
      productId: productId,
    );

    if (result['success'] == true) {
      final movementsData = result['movements'] as List? ?? [];
      final summaryData = result['summary'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        stockMovements:
            movementsData.map((m) => StockAuditLog.fromJson(m)).toList(),
        reportSummary: ReportSummary.fromJson(summaryData),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch stock report',
      );
    }
  }

  /// Adjust stock for a product
  Future<bool> adjustStock({
    required String productId,
    required int quantity,
    required String changeType,
    String? reason,
  }) async {
    state = state.copyWith(isAdjusting: true, error: null);

    final result = await ApiService.adjustStock(
      productId: productId,
      quantity: quantity,
      changeType: changeType,
      reason: reason,
    );

    if (result['success'] == true) {
      // Refresh low stock data
      await fetchLowStock();
      state = state.copyWith(isAdjusting: false);
      return true;
    }

    state = state.copyWith(
      isAdjusting: false,
      error: result['error'] ?? 'Failed to adjust stock',
    );
    return false;
  }

  /// Refresh all inventory data
  Future<void> refresh() async {
    await fetchLowStock();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  return InventoryNotifier();
});
