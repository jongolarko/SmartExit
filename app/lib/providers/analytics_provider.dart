import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Models
class RevenueChartData {
  final DateTime date;
  final int orders;
  final double revenue;

  RevenueChartData({
    required this.date,
    required this.orders,
    required this.revenue,
  });

  factory RevenueChartData.fromJson(Map<String, dynamic> json) {
    return RevenueChartData(
      date: DateTime.parse(json['date']),
      orders: int.parse(json['orders'].toString()),
      revenue: double.parse(json['revenue'].toString()),
    );
  }
}

class ComparisonData {
  final double current;
  final double previous;
  final double percentChange;

  ComparisonData({
    required this.current,
    required this.previous,
    required this.percentChange,
  });

  factory ComparisonData.fromJson(Map<String, dynamic> json) {
    return ComparisonData(
      current: double.parse(json['current'].toString()),
      previous: double.parse(json['previous'].toString()),
      percentChange: double.parse(json['percentChange'].toString()),
    );
  }
}

class KpiTrend {
  final double current;
  final double previous;
  final double change;

  KpiTrend({
    required this.current,
    required this.previous,
    required this.change,
  });

  factory KpiTrend.fromJson(Map<String, dynamic> json) {
    return KpiTrend(
      current: double.parse(json['current'].toString()),
      previous: double.parse(json['previous'].toString()),
      change: double.parse(json['change'].toString()),
    );
  }
}

// State
class AnalyticsState {
  final bool isLoading;
  final List<RevenueChartData> revenueData;
  final String selectedRange;
  final ComparisonData? comparison;
  final Map<String, KpiTrend>? kpiTrends;
  final String? error;

  AnalyticsState({
    this.isLoading = false,
    this.revenueData = const [],
    this.selectedRange = '7d',
    this.comparison,
    this.kpiTrends,
    this.error,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    List<RevenueChartData>? revenueData,
    String? selectedRange,
    ComparisonData? comparison,
    Map<String, KpiTrend>? kpiTrends,
    String? error,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      revenueData: revenueData ?? this.revenueData,
      selectedRange: selectedRange ?? this.selectedRange,
      comparison: comparison ?? this.comparison,
      kpiTrends: kpiTrends ?? this.kpiTrends,
      error: error ?? this.error,
    );
  }
}

// Notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(AnalyticsState());

  Future<void> fetchRevenueChart({
    String? range,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.getRevenueChart(
        range: range ?? state.selectedRange,
        startDate: startDate,
        endDate: endDate,
      );

      final List<RevenueChartData> chartData = (data['data'] as List)
          .map((item) => RevenueChartData.fromJson(item))
          .toList();

      final comparison = ComparisonData.fromJson(data['comparison']);

      state = state.copyWith(
        isLoading: false,
        revenueData: chartData,
        comparison: comparison,
        selectedRange: range ?? state.selectedRange,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Error fetching revenue chart: $e');
    }
  }

  Future<void> fetchKpiTrends() async {
    try {
      final data = await ApiService.getKpiTrends();

      final kpiTrends = {
        'revenue': KpiTrend.fromJson(data['revenue']),
        'orders': KpiTrend.fromJson(data['orders']),
        'users': KpiTrend.fromJson(data['users']),
      };

      state = state.copyWith(kpiTrends: kpiTrends);
    } catch (e) {
      debugPrint('Error fetching KPI trends: $e');
    }
  }

  void setRange(String range) {
    if (range != state.selectedRange) {
      fetchRevenueChart(range: range);
    }
  }
}

// Provider
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier();
});
