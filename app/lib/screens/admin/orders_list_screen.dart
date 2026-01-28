import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import 'admin_order_details_screen.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'All', 'status': null},
    {'label': 'Paid', 'status': 'paid'},
    {'label': 'Refunded', 'status': 'refunded'},
    {'label': 'Cancelled', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersAdminProvider.notifier).fetchOrders();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final status = _tabs[_tabController.index]['status'] as String?;
      ref.read(ordersAdminProvider.notifier).setStatusFilter(status);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(ordersAdminProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(ordersAdminProvider.notifier).refresh(),
                color: AppColors.admin,
                child: _buildContent(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.screenAll,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.pure,
                borderRadius: AppSpacing.borderRadiusMd,
                boxShadow: AppShadows.sm,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppColors.voidBlack,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orders',
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.voidBlack,
                  ),
                ),
                Text(
                  'Manage customer orders',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.admin,
        unselectedLabelColor: AppColors.steel,
        labelStyle: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.adminLight,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        dividerColor: Colors.transparent,
        tabs: _tabs.map((tab) => Tab(text: tab['label'] as String)).toList(),
      ),
    );
  }

  Widget _buildContent(OrdersAdminState state) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.admin),
      );
    }

    if (state.error != null && state.orders.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.orders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: AppSpacing.screenAll,
      itemCount: state.orders.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.orders.length) {
          return const Center(
            child: Padding(
              padding: AppSpacing.allMd,
              child: CircularProgressIndicator(color: AppColors.admin),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildOrderCard(state.orders[index]),
        );
      },
    );
  }

  Widget _buildOrderCard(AdminOrder order) {
    final statusColor = _getStatusColor(order.status);
    final statusBgColor = _getStatusBgColor(order.status);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminOrderDetailsScreen(orderId: order.id),
          ),
        );
      },
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.customerName ?? 'Unknown Customer',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Text(
                          _formatStatus(order.status),
                          style: AppTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\u20B9${order.totalAmount.toStringAsFixed(2)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.voidBlack,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '\u2022',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _formatDate(order.createdAt),
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  if (order.customerPhone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      order.customerPhone!,
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.silver,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.mist,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No orders found',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Orders will appear here when customers make purchases',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load orders',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.read(ordersAdminProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.admin,
                foregroundColor: AppColors.pure,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.accent;
      case 'refunded':
        return AppColors.security;
      case 'cancelled':
        return AppColors.error;
      case 'created':
        return AppColors.warning;
      default:
        return AppColors.steel;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.accentLight;
      case 'refunded':
        return AppColors.securityLight;
      case 'cancelled':
        return AppColors.errorLight;
      case 'created':
        return AppColors.warningLight;
      default:
        return AppColors.cloud;
    }
  }

  String _formatStatus(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
