import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartexit_services/smartexit_services.dart';

// Spending insights models
class SpendingSummary {
  final double totalSpent;
  final int orderCount;
  final double avgOrderValue;
  final double? maxOrderValue;
  final double? minOrderValue;

  SpendingSummary({
    required this.totalSpent,
    required this.orderCount,
    required this.avgOrderValue,
    this.maxOrderValue,
    this.minOrderValue,
  });

  factory SpendingSummary.fromJson(Map<String, dynamic> json) {
    return SpendingSummary(
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0,
      orderCount: int.tryParse(json['order_count']?.toString() ?? '0') ?? 0,
      avgOrderValue: double.tryParse(json['avg_order_value']?.toString() ?? '0') ?? 0,
      maxOrderValue: double.tryParse(json['max_order_value']?.toString() ?? '0'),
      minOrderValue: double.tryParse(json['min_order_value']?.toString() ?? '0'),
    );
  }
}

class CategorySpending {
  final String category;
  final double total;
  final int orderCount;
  final int itemCount;
  final double percentage;

  CategorySpending({
    required this.category,
    required this.total,
    required this.orderCount,
    required this.itemCount,
    required this.percentage,
  });

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      category: json['category'] ?? 'Uncategorized',
      total: double.tryParse(json['category_total']?.toString() ?? '0') ?? 0,
      orderCount: int.tryParse(json['order_count']?.toString() ?? '0') ?? 0,
      itemCount: int.tryParse(json['item_count']?.toString() ?? '0') ?? 0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0,
    );
  }
}

class SpendingTrend {
  final double currentTotal;
  final double previousTotal;
  final double? changePercent;
  final String trend; // 'increasing', 'decreasing', 'stable'

  SpendingTrend({
    required this.currentTotal,
    required this.previousTotal,
    this.changePercent,
    required this.trend,
  });

  factory SpendingTrend.fromJson(Map<String, dynamic> json) {
    return SpendingTrend(
      currentTotal: double.tryParse(json['current_total']?.toString() ?? '0') ?? 0,
      previousTotal: double.tryParse(json['previous_total']?.toString() ?? '0') ?? 0,
      changePercent: double.tryParse(json['change_percent']?.toString() ?? '0'),
      trend: json['trend'] ?? 'stable',
    );
  }
}

class TopProduct {
  final String id;
  final String name;
  final String barcode;
  final String? category;
  final int totalQuantity;
  final double totalSpent;
  final int orderCount;

  TopProduct({
    required this.id,
    required this.name,
    required this.barcode,
    this.category,
    required this.totalQuantity,
    required this.totalSpent,
    required this.orderCount,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      category: json['category'],
      totalQuantity: int.tryParse(json['total_quantity']?.toString() ?? '0') ?? 0,
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0,
      orderCount: int.tryParse(json['order_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class SpendingInsights {
  final SpendingSummary summary;
  final List<CategorySpending> categories;
  final SpendingTrend trend;
  final List<TopProduct> topProducts;

  SpendingInsights({
    required this.summary,
    required this.categories,
    required this.trend,
    required this.topProducts,
  });

  factory SpendingInsights.fromJson(Map<String, dynamic> json) {
    return SpendingInsights(
      summary: SpendingSummary.fromJson(json['summary'] ?? {}),
      categories: (json['categories'] as List?)
          ?.map((cat) => CategorySpending.fromJson(cat))
          .toList() ??
          [],
      trend: SpendingTrend.fromJson(json['trend'] ?? {}),
      topProducts: (json['top_products'] as List?)
          ?.map((prod) => TopProduct.fromJson(prod))
          .toList() ??
          [],
    );
  }
}

class TimelinePoint {
  final String date;
  final String dayName;
  final double amount;
  final int orderCount;

  TimelinePoint({
    required this.date,
    required this.dayName,
    required this.amount,
    required this.orderCount,
  });

  factory TimelinePoint.fromJson(Map<String, dynamic> json) {
    return TimelinePoint(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      orderCount: int.tryParse(json['order_count']?.toString() ?? '0') ?? 0,
    );
  }
}

// Insights state notifier for period management
class InsightsState {
  final String period; // 'week' or 'month'
  final bool isRefreshing;

  InsightsState({
    this.period = 'month',
    this.isRefreshing = false,
  });

  InsightsState copyWith({
    String? period,
    bool? isRefreshing,
  }) {
    return InsightsState(
      period: period ?? this.period,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class InsightsNotifier extends StateNotifier<InsightsState> {
  InsightsNotifier() : super(InsightsState());

  void setPeriod(String period) {
    state = state.copyWith(period: period);
  }

  Future<void> refreshCache() async {
    state = state.copyWith(isRefreshing: true);
    try {
      await ApiService.refreshInsightsCache();
    } finally {
      state = state.copyWith(isRefreshing: false);
    }
  }
}

final insightsStateProvider = StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  return InsightsNotifier();
});

// Spending insights provider
final spendingInsightsProvider = FutureProvider<SpendingInsights>((ref) async {
  final period = ref.watch(insightsStateProvider).period;

  final response = await ApiService.getSpendingInsights(period: period);

  if (response['success'] == true && response['insights'] != null) {
    return SpendingInsights.fromJson(response['insights']);
  }

  throw Exception(response['error'] ?? 'Failed to load insights');
});

// Spending timeline provider (for charts)
final spendingTimelineProvider = FutureProvider<List<TimelinePoint>>((ref) async {
  final period = ref.watch(insightsStateProvider).period;

  final response = await ApiService.getSpendingTimeline(period: period);

  if (response['success'] == true && response['timeline'] != null) {
    return (response['timeline'] as List)
        .map((point) => TimelinePoint.fromJson(point))
        .toList();
  }

  return [];
});

// Quick summary provider (cached)
final insightsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiService.getInsightsSummary();

  if (response['success'] == true) {
    return response;
  }

  throw Exception(response['error'] ?? 'Failed to load summary');
});
