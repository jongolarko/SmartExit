import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Models
class AcquisitionData {
  final DateTime date;
  final int newCustomers;

  AcquisitionData({
    required this.date,
    required this.newCustomers,
  });

  factory AcquisitionData.fromJson(Map<String, dynamic> json) {
    return AcquisitionData(
      date: DateTime.parse(json['date']),
      newCustomers: int.parse(json['newCustomers'].toString()),
    );
  }
}

class RepeatRateData {
  final int totalCustomers;
  final int repeatCustomers;
  final double repeatRate;

  RepeatRateData({
    required this.totalCustomers,
    required this.repeatCustomers,
    required this.repeatRate,
  });

  factory RepeatRateData.fromJson(Map<String, dynamic> json) {
    return RepeatRateData(
      totalCustomers: int.parse(json['totalCustomers'].toString()),
      repeatCustomers: int.parse(json['repeatCustomers'].toString()),
      repeatRate: double.parse(json['repeatRate'].toString()),
    );
  }
}

class CustomerCLV {
  final String customerId;
  final String phoneNumber;
  final String? name;
  final double lifetimeValue;
  final int orderCount;
  final DateTime? lastPurchase;

  CustomerCLV({
    required this.customerId,
    required this.phoneNumber,
    this.name,
    required this.lifetimeValue,
    required this.orderCount,
    this.lastPurchase,
  });

  factory CustomerCLV.fromJson(Map<String, dynamic> json) {
    return CustomerCLV(
      customerId: json['customerId'] as String,
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String?,
      lifetimeValue: double.parse(json['lifetimeValue'].toString()),
      orderCount: int.parse(json['orderCount'].toString()),
      lastPurchase: json['lastPurchase'] != null
          ? DateTime.parse(json['lastPurchase'])
          : null,
    );
  }
}

class SegmentData {
  final String segment;
  final int count;
  final double percentage;

  SegmentData({
    required this.segment,
    required this.count,
    required this.percentage,
  });

  factory SegmentData.fromJson(Map<String, dynamic> json) {
    return SegmentData(
      segment: json['segment'] as String,
      count: int.parse(json['count'].toString()),
      percentage: double.parse(json['percentage'].toString()),
    );
  }
}

// State
class CustomerAnalyticsState {
  final bool isLoading;
  final String selectedRange;
  final List<AcquisitionData> acquisitionData;
  final RepeatRateData? repeatRate;
  final List<CustomerCLV> clvData;
  final List<SegmentData> segmentation;
  final String? error;

  CustomerAnalyticsState({
    this.isLoading = false,
    this.selectedRange = '30d',
    this.acquisitionData = const [],
    this.repeatRate,
    this.clvData = const [],
    this.segmentation = const [],
    this.error,
  });

  CustomerAnalyticsState copyWith({
    bool? isLoading,
    String? selectedRange,
    List<AcquisitionData>? acquisitionData,
    RepeatRateData? repeatRate,
    List<CustomerCLV>? clvData,
    List<SegmentData>? segmentation,
    String? error,
  }) {
    return CustomerAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      selectedRange: selectedRange ?? this.selectedRange,
      acquisitionData: acquisitionData ?? this.acquisitionData,
      repeatRate: repeatRate ?? this.repeatRate,
      clvData: clvData ?? this.clvData,
      segmentation: segmentation ?? this.segmentation,
      error: error ?? this.error,
    );
  }
}

// Notifier
class CustomerAnalyticsNotifier extends StateNotifier<CustomerAnalyticsState> {
  CustomerAnalyticsNotifier() : super(CustomerAnalyticsState());

  Future<void> fetchCustomerAcquisition({String range = '30d'}) async {
    state = state.copyWith(isLoading: true, error: null, selectedRange: range);
    try {
      final data = await ApiService.getCustomerAcquisition(range: range);

      final List<AcquisitionData> acquisitionData = (data['data'] as List)
          .map((item) => AcquisitionData.fromJson(item))
          .toList();

      state = state.copyWith(
        isLoading: false,
        acquisitionData: acquisitionData,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Error fetching customer acquisition: $e');
    }
  }

  Future<void> fetchRepeatRate() async {
    try {
      final data = await ApiService.getRepeatRate();
      final repeatRate = RepeatRateData.fromJson(data);

      state = state.copyWith(repeatRate: repeatRate);
    } catch (e) {
      debugPrint('Error fetching repeat rate: $e');
    }
  }

  Future<void> fetchCustomerLifetimeValue() async {
    try {
      final data = await ApiService.getCustomerLifetimeValue();

      final List<CustomerCLV> clvData = (data['customers'] as List)
          .map((item) => CustomerCLV.fromJson(item))
          .toList();

      state = state.copyWith(clvData: clvData);
    } catch (e) {
      debugPrint('Error fetching customer lifetime value: $e');
    }
  }

  Future<void> fetchCustomerSegmentation() async {
    try {
      final data = await ApiService.getCustomerSegmentation();

      final List<SegmentData> segmentation = (data['segments'] as List)
          .map((item) => SegmentData.fromJson(item))
          .toList();

      state = state.copyWith(segmentation: segmentation);
    } catch (e) {
      debugPrint('Error fetching customer segmentation: $e');
    }
  }

  Future<void> fetchAllData({String range = '30d'}) async {
    await Future.wait([
      fetchCustomerAcquisition(range: range),
      fetchRepeatRate(),
      fetchCustomerLifetimeValue(),
      fetchCustomerSegmentation(),
    ]);
  }

  void setRange(String range) {
    if (range != state.selectedRange) {
      fetchCustomerAcquisition(range: range);
    }
  }
}

// Provider
final customerAnalyticsProvider =
    StateNotifierProvider<CustomerAnalyticsNotifier, CustomerAnalyticsState>((ref) {
  return CustomerAnalyticsNotifier();
});
