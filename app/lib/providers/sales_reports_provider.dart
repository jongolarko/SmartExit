import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Models
class SalesSummary {
  final String date;
  final double revenue;
  final int orders;
  final double avgOrderValue;

  SalesSummary({
    required this.date,
    required this.revenue,
    required this.orders,
    required this.avgOrderValue,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    return SalesSummary(
      date: json['date'] as String,
      revenue: double.parse(json['revenue'].toString()),
      orders: int.parse(json['orders'].toString()),
      avgOrderValue: double.parse(json['avgOrderValue'].toString()),
    );
  }
}

class PeakHourData {
  final int hour;
  final int orderCount;

  PeakHourData({
    required this.hour,
    required this.orderCount,
  });

  factory PeakHourData.fromJson(Map<String, dynamic> json) {
    return PeakHourData(
      hour: int.parse(json['hour'].toString()),
      orderCount: int.parse(json['orderCount'].toString()),
    );
  }
}

class RefundRateData {
  final int totalPaidOrders;
  final int refundedOrders;
  final double refundRate;
  final double totalRefundAmount;

  RefundRateData({
    required this.totalPaidOrders,
    required this.refundedOrders,
    required this.refundRate,
    required this.totalRefundAmount,
  });

  factory RefundRateData.fromJson(Map<String, dynamic> json) {
    return RefundRateData(
      totalPaidOrders: int.parse(json['totalPaidOrders'].toString()),
      refundedOrders: int.parse(json['refundedOrders'].toString()),
      refundRate: double.parse(json['refundRate'].toString()),
      totalRefundAmount: double.parse(json['totalRefundAmount'].toString()),
    );
  }
}

// State
class SalesReportsState {
  final bool isLoading;
  final String selectedPeriod;
  final List<SalesSummary> salesData;
  final List<PeakHourData> peakHours;
  final RefundRateData? refundRate;
  final String? error;

  SalesReportsState({
    this.isLoading = false,
    this.selectedPeriod = 'daily',
    this.salesData = const [],
    this.peakHours = const [],
    this.refundRate,
    this.error,
  });

  SalesReportsState copyWith({
    bool? isLoading,
    String? selectedPeriod,
    List<SalesSummary>? salesData,
    List<PeakHourData>? peakHours,
    RefundRateData? refundRate,
    String? error,
  }) {
    return SalesReportsState(
      isLoading: isLoading ?? this.isLoading,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      salesData: salesData ?? this.salesData,
      peakHours: peakHours ?? this.peakHours,
      refundRate: refundRate ?? this.refundRate,
      error: error ?? this.error,
    );
  }

  double get totalRevenue {
    return salesData.fold(0.0, (sum, item) => sum + item.revenue);
  }

  int get totalOrders {
    return salesData.fold(0, (sum, item) => sum + item.orders);
  }

  double get avgOrderValue {
    if (totalOrders == 0) return 0.0;
    return totalRevenue / totalOrders;
  }
}

// Notifier
class SalesReportsNotifier extends StateNotifier<SalesReportsState> {
  SalesReportsNotifier() : super(SalesReportsState());

  Future<void> fetchSalesSummary(String period) async {
    state = state.copyWith(isLoading: true, error: null, selectedPeriod: period);
    try {
      final data = await ApiService.getSalesSummary(period: period);

      final List<SalesSummary> salesData = (data['data'] as List)
          .map((item) => SalesSummary.fromJson(item))
          .toList();

      state = state.copyWith(
        isLoading: false,
        salesData: salesData,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Error fetching sales summary: $e');
    }
  }

  Future<void> fetchPeakHours() async {
    try {
      final data = await ApiService.getPeakHours();

      final List<PeakHourData> peakHours = (data['peakHours'] as List)
          .map((item) => PeakHourData.fromJson(item))
          .toList();

      state = state.copyWith(peakHours: peakHours);
    } catch (e) {
      debugPrint('Error fetching peak hours: $e');
    }
  }

  Future<void> fetchRefundRate() async {
    try {
      final data = await ApiService.getRefundRate();
      final refundRate = RefundRateData.fromJson(data);

      state = state.copyWith(refundRate: refundRate);
    } catch (e) {
      debugPrint('Error fetching refund rate: $e');
    }
  }

  Future<void> fetchAllData(String period) async {
    await Future.wait([
      fetchSalesSummary(period),
      fetchPeakHours(),
      fetchRefundRate(),
    ]);
  }
}

// Provider
final salesReportsProvider =
    StateNotifierProvider<SalesReportsNotifier, SalesReportsState>((ref) {
  return SalesReportsNotifier();
});
