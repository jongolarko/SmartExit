import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

// Recent order model
class RecentOrder {
  final String id;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String customerName;

  RecentOrder({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.customerName,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      id: json['id'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      customerName: json['name'] ?? 'Unknown',
    );
  }
}

// Admin dashboard data model
class AdminDashboardData {
  final double totalRevenue;
  final double todayRevenue;
  final int totalUsers;
  final int todayUsers;
  final int totalOrders;
  final int todayOrders;
  final int fraudAlerts;
  final int pendingExits;
  final List<RecentOrder> recentOrders;

  AdminDashboardData({
    required this.totalRevenue,
    required this.todayRevenue,
    required this.totalUsers,
    required this.todayUsers,
    required this.totalOrders,
    required this.todayOrders,
    required this.fraudAlerts,
    required this.pendingExits,
    required this.recentOrders,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final revenue = json['revenue'] ?? {};
    final users = json['users'] ?? {};
    final orders = json['orders'] ?? {};
    final alerts = json['alerts'] ?? {};
    final recentOrdersList = json['recent_orders'] as List? ?? [];

    return AdminDashboardData(
      totalRevenue: double.tryParse(revenue['total']?.toString() ?? '0') ?? 0,
      todayRevenue: double.tryParse(revenue['today']?.toString() ?? '0') ?? 0,
      totalUsers: int.tryParse(users['total']?.toString() ?? '0') ?? 0,
      todayUsers: int.tryParse(users['today']?.toString() ?? '0') ?? 0,
      totalOrders: int.tryParse(orders['total']?.toString() ?? '0') ?? 0,
      todayOrders: int.tryParse(orders['today']?.toString() ?? '0') ?? 0,
      fraudAlerts: int.tryParse(alerts['fraud']?.toString() ?? '0') ?? 0,
      pendingExits: int.tryParse(alerts['pending_exits']?.toString() ?? '0') ?? 0,
      recentOrders: recentOrdersList
          .map((order) => RecentOrder.fromJson(order))
          .toList(),
    );
  }

  int get totalAlerts => fraudAlerts + pendingExits;
}

// Admin state
class AdminState {
  final bool isLoading;
  final AdminDashboardData? data;
  final String? error;
  final DateTime? lastUpdated;

  const AdminState({
    this.isLoading = false,
    this.data,
    this.error,
    this.lastUpdated,
  });

  AdminState copyWith({
    bool? isLoading,
    AdminDashboardData? data,
    String? error,
    DateTime? lastUpdated,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Admin notifier
class AdminNotifier extends StateNotifier<AdminState> {
  StreamSubscription? _newOrderSubscription;
  StreamSubscription? _fraudAlertSubscription;

  AdminNotifier() : super(const AdminState()) {
    _listenToSocketUpdates();
  }

  void _listenToSocketUpdates() {
    // Listen for new orders
    _newOrderSubscription = SocketService.instance.newOrders.listen((_) {
      // Refresh dashboard when new order comes in
      fetchDashboard();
    });

    // Listen for fraud alerts
    _fraudAlertSubscription = SocketService.instance.fraudAlerts.listen((_) {
      // Refresh dashboard when fraud alert comes in
      fetchDashboard();
    });
  }

  /// Fetch dashboard data from API
  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.getDashboard();

    if (result['success'] == true) {
      final data = AdminDashboardData.fromJson(result['data'] ?? result);
      state = state.copyWith(
        isLoading: false,
        data: data,
        lastUpdated: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch dashboard data',
      );
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await fetchDashboard();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _newOrderSubscription?.cancel();
    _fraudAlertSubscription?.cancel();
    super.dispose();
  }
}

// Provider
final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});
