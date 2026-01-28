import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Admin User model
class AdminUser {
  final String id;
  final String name;
  final String phone;
  final String role;
  final DateTime createdAt;
  final int? orderCount;

  AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.orderCount,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      orderCount: json['order_count'] != null
          ? int.tryParse(json['order_count'].toString())
          : null,
    );
  }

  bool get isCustomer => role == 'customer';
  bool get isSecurity => role == 'security';
  bool get isAdmin => role == 'admin';
}

// User stats model
class UserStats {
  final int totalOrders;
  final double totalSpent;
  final double totalRefunded;

  UserStats({
    required this.totalOrders,
    required this.totalSpent,
    required this.totalRefunded,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0,
      totalRefunded: double.tryParse(json['total_refunded']?.toString() ?? '0') ?? 0,
    );
  }

  double get netSpent => totalSpent - totalRefunded;
}

// User details model
class UserDetails {
  final AdminUser user;
  final UserStats stats;

  UserDetails({
    required this.user,
    required this.stats,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      user: AdminUser.fromJson(json['user'] ?? {}),
      stats: UserStats.fromJson(json['stats'] ?? {}),
    );
  }
}

// User order model (simplified)
class UserOrder {
  final String id;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? refundId;
  final double? refundAmount;
  final DateTime? refundedAt;

  UserOrder({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.refundId,
    this.refundAmount,
    this.refundedAt,
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) {
    return UserOrder(
      id: json['id'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'created',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
      refundId: json['refund_id'],
      refundAmount: json['refund_amount'] != null
          ? double.tryParse(json['refund_amount'].toString())
          : null,
      refundedAt: json['refunded_at'] != null
          ? DateTime.tryParse(json['refunded_at'])
          : null,
    );
  }
}

// Users admin state
class UsersAdminState {
  final bool isLoading;
  final List<AdminUser> users;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final String? roleFilter;
  final String searchQuery;
  final bool isProcessing;
  final UserDetails? selectedUserDetails;
  final List<UserOrder>? selectedUserOrders;
  final int userOrdersPage;
  final int userOrdersTotalPages;
  final bool hasMoreUserOrders;

  const UsersAdminState({
    this.isLoading = false,
    this.users = const [],
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.roleFilter,
    this.searchQuery = '',
    this.isProcessing = false,
    this.selectedUserDetails,
    this.selectedUserOrders,
    this.userOrdersPage = 1,
    this.userOrdersTotalPages = 1,
    this.hasMoreUserOrders = false,
  });

  UsersAdminState copyWith({
    bool? isLoading,
    List<AdminUser>? users,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    String? roleFilter,
    String? searchQuery,
    bool? isProcessing,
    UserDetails? selectedUserDetails,
    List<UserOrder>? selectedUserOrders,
    int? userOrdersPage,
    int? userOrdersTotalPages,
    bool? hasMoreUserOrders,
    bool clearSelectedUser = false,
    bool clearRoleFilter = false,
  }) {
    return UsersAdminState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      isProcessing: isProcessing ?? this.isProcessing,
      selectedUserDetails: clearSelectedUser
          ? null
          : (selectedUserDetails ?? this.selectedUserDetails),
      selectedUserOrders: clearSelectedUser
          ? null
          : (selectedUserOrders ?? this.selectedUserOrders),
      userOrdersPage: userOrdersPage ?? this.userOrdersPage,
      userOrdersTotalPages: userOrdersTotalPages ?? this.userOrdersTotalPages,
      hasMoreUserOrders: hasMoreUserOrders ?? this.hasMoreUserOrders,
    );
  }
}

// Users admin notifier
class UsersAdminNotifier extends StateNotifier<UsersAdminState> {
  UsersAdminNotifier() : super(const UsersAdminState());

  /// Fetch users (first page)
  Future<void> fetchUsers({String? role, String? search}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      roleFilter: role,
      searchQuery: search ?? state.searchQuery,
    );

    final result = await ApiService.getUsers(
      page: 1,
      limit: 20,
      role: role,
      search: search ?? state.searchQuery,
    );

    if (result['success'] == true) {
      final usersData = result['data'] as List? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        users: usersData.map((u) => AdminUser.fromJson(u)).toList(),
        currentPage: pagination['page'] ?? 1,
        totalPages: pagination['totalPages'] ?? 1,
        hasMore: (pagination['page'] ?? 1) < (pagination['totalPages'] ?? 1),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch users',
      );
    }
  }

  /// Load more users
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    final nextPage = state.currentPage + 1;
    final result = await ApiService.getUsers(
      page: nextPage,
      limit: 20,
      role: state.roleFilter,
      search: state.searchQuery,
    );

    if (result['success'] == true) {
      final usersData = result['data'] as List? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        users: [...state.users, ...usersData.map((u) => AdminUser.fromJson(u))],
        currentPage: pagination['page'] ?? nextPage,
        totalPages: pagination['totalPages'] ?? 1,
        hasMore: (pagination['page'] ?? nextPage) < (pagination['totalPages'] ?? 1),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Set role filter
  Future<void> setRoleFilter(String? role) async {
    if (role == state.roleFilter) return;
    await fetchUsers(role: role, search: state.searchQuery);
  }

  /// Search users
  Future<void> search(String query) async {
    await fetchUsers(role: state.roleFilter, search: query);
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    fetchUsers(role: state.roleFilter);
  }

  /// Fetch user details
  Future<void> fetchUserDetails(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ApiService.getUserDetails(userId: userId);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        selectedUserDetails: UserDetails.fromJson(result),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch user details',
      );
    }
  }

  /// Fetch user orders
  Future<void> fetchUserOrders(String userId, {bool loadMore = false}) async {
    if (loadMore && !state.hasMoreUserOrders) return;

    final page = loadMore ? state.userOrdersPage + 1 : 1;

    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await ApiService.getUserOrders(
      userId: userId,
      page: page,
      limit: 20,
    );

    if (result['success'] == true) {
      final ordersData = result['data'] as List? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
      final newOrders = ordersData.map((o) => UserOrder.fromJson(o)).toList();

      state = state.copyWith(
        isLoading: false,
        selectedUserOrders: loadMore
            ? [...(state.selectedUserOrders ?? []), ...newOrders]
            : newOrders,
        userOrdersPage: pagination['page'] ?? page,
        userOrdersTotalPages: pagination['totalPages'] ?? 1,
        hasMoreUserOrders: (pagination['page'] ?? page) < (pagination['totalPages'] ?? 1),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] ?? 'Failed to fetch user orders',
      );
    }
  }

  /// Update user role
  Future<bool> updateUserRole({
    required String userId,
    required String role,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await ApiService.updateUserRole(
      userId: userId,
      role: role,
    );

    if (result['success'] == true) {
      // Update user in list
      final updatedUsers = state.users.map((u) {
        if (u.id == userId) {
          return AdminUser(
            id: u.id,
            name: u.name,
            phone: u.phone,
            role: role,
            createdAt: u.createdAt,
            orderCount: u.orderCount,
          );
        }
        return u;
      }).toList();

      // Update selected user details if viewing
      UserDetails? updatedDetails;
      if (state.selectedUserDetails?.user.id == userId) {
        updatedDetails = UserDetails(
          user: AdminUser(
            id: state.selectedUserDetails!.user.id,
            name: state.selectedUserDetails!.user.name,
            phone: state.selectedUserDetails!.user.phone,
            role: role,
            createdAt: state.selectedUserDetails!.user.createdAt,
            orderCount: state.selectedUserDetails!.user.orderCount,
          ),
          stats: state.selectedUserDetails!.stats,
        );
      }

      state = state.copyWith(
        isProcessing: false,
        users: updatedUsers,
        selectedUserDetails: updatedDetails,
      );

      return true;
    }

    state = state.copyWith(
      isProcessing: false,
      error: result['error'] ?? 'Failed to update user role',
    );
    return false;
  }

  /// Clear selected user
  void clearSelectedUser() {
    state = state.copyWith(clearSelectedUser: true);
  }

  /// Refresh users
  Future<void> refresh() async {
    await fetchUsers(role: state.roleFilter, search: state.searchQuery);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final usersAdminProvider = StateNotifierProvider<UsersAdminNotifier, UsersAdminState>((ref) {
  return UsersAdminNotifier();
});
