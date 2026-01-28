import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import 'inventory_screen.dart';
import 'orders_list_screen.dart';
import 'product_list_screen.dart';
import 'users_list_screen.dart';
import 'sales_reports_screen.dart';
import 'product_performance_screen.dart';
import 'customer_analytics_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    // Fetch dashboard data, inventory data, and analytics data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).fetchDashboard();
      ref.read(inventoryProvider.notifier).fetchLowStock();
      ref.read(analyticsProvider.notifier).fetchRevenueChart();
      ref.read(analyticsProvider.notifier).fetchKpiTrends();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            );
          },
          child: RefreshIndicator(
            onRefresh: () => ref.read(adminProvider.notifier).refresh(),
            color: AppColors.admin,
            child: _buildContent(adminState),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AdminState adminState) {
    // Show error state
    if (adminState.error != null && adminState.data == null) {
      return _buildErrorState(adminState.error!);
    }

    // Show loading state on initial load
    if (adminState.isLoading && adminState.data == null) {
      return _buildLoadingState();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screenAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.xl),
                _buildMetricCards(adminState.data),
                const SizedBox(height: AppSpacing.xl),
                _buildDateRangeSelector(),
                const SizedBox(height: AppSpacing.md),
                _buildRevenueChart(adminState.data),
                const SizedBox(height: AppSpacing.xl),
                _buildQuickActions(),
                const SizedBox(height: AppSpacing.xl),
                _buildRecentActivityHeader(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          sliver: _buildActivityList(adminState.data),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xl),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.admin,
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
              'Failed to load dashboard',
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
              onPressed: () => ref.read(adminProvider.notifier).fetchDashboard(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.admin,
                foregroundColor: AppColors.pure,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Logout button
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            await ref.read(authProvider.notifier).logout();
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
                Icons.logout_rounded,
                size: 18,
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
                'Dashboard',
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.voidBlack,
                ),
              ),
              Text(
                'Overview and analytics',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        // Profile avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.admin,
                AppColors.admin.withOpacity(0.7),
              ],
            ),
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: const Center(
            child: Icon(
              Icons.person_rounded,
              color: AppColors.pure,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCards(AdminDashboardData? data) {
    final todayRevenue = data?.todayRevenue ?? 0;
    final totalOrders = data?.totalOrders ?? 0;
    final activeUsers = data?.totalUsers ?? 0;
    final alerts = data?.totalAlerts ?? 0;
    final todayOrders = data?.todayOrders ?? 0;
    final todayUsers = data?.todayUsers ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Today\'s Revenue',
                value: '\u20B9${_formatNumber(todayRevenue)}',
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.admin,
                trend: todayRevenue > 0 ? 'Today' : null,
                isPositive: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildMetricCard(
                label: 'Total Orders',
                value: totalOrders.toString(),
                icon: Icons.receipt_long_outlined,
                color: AppColors.accent,
                trend: todayOrders > 0 ? '+$todayOrders today' : null,
                isPositive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Total Users',
                value: activeUsers.toString(),
                icon: Icons.people_outline_rounded,
                color: AppColors.security,
                trend: todayUsers > 0 ? '+$todayUsers today' : null,
                isPositive: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildMetricCard(
                label: 'Alerts',
                value: alerts.toString(),
                icon: Icons.warning_amber_rounded,
                color: alerts > 0 ? AppColors.warning : AppColors.accent,
                trend: alerts > 0 ? '$alerts pending' : 'None',
                isPositive: alerts == 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
    bool isPositive = true,
  }) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 20),
                ),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppColors.accentLight
                        : AppColors.warningLight,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    trend,
                    style: AppTypography.labelSmall.copyWith(
                      color: isPositive ? AppColors.accent : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.voidBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(AdminDashboardData? data) {
    final analyticsState = ref.watch(analyticsProvider);

    if (analyticsState.isLoading && analyticsState.revenueData.isEmpty) {
      return Container(
        height: 250,
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppShadows.sm,
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.admin),
        ),
      );
    }

    // Use dynamic data if available, otherwise show empty state
    final revenueData = analyticsState.revenueData.isNotEmpty
        ? analyticsState.revenueData
        : [];

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Trend',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (analyticsState.comparison != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: analyticsState.comparison!.percentChange >= 0
                        ? AppColors.accentLight
                        : AppColors.warningLight,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    '${analyticsState.comparison!.percentChange > 0 ? '+' : ''}${analyticsState.comparison!.percentChange.toStringAsFixed(1)}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: analyticsState.comparison!.percentChange >= 0
                          ? AppColors.accent
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: revenueData.isEmpty
                ? Center(
                    child: Text(
                      'No revenue data available',
                      style: AppTypography.bodySmall,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.mist,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}k',
                                style: AppTypography.labelSmall,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < revenueData.length) {
                                final date = revenueData[value.toInt()].date;
                                final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dayName,
                                    style: AppTypography.labelSmall,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (revenueData.length - 1).toDouble(),
                      minY: 0,
                      maxY: _calculateMaxY(revenueData),
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenueData.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.revenue,
                            );
                          }).toList(),
                          isCurved: true,
                          color: AppColors.admin,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppColors.pure,
                                strokeWidth: 2,
                                strokeColor: AppColors.admin,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.admin.withOpacity(0.2),
                                AppColors.admin.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY(List<dynamic> data) {
    if (data.isEmpty) return 100000;
    final maxRevenue = data.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);
    final roundedMax = ((maxRevenue / 10000).ceil() * 10000).toDouble();
    return roundedMax > 0 ? roundedMax : 100000;
  }

  Widget _buildQuickActions() {
    final inventoryState = ref.watch(inventoryProvider);
    final lowStockCount = inventoryState.summary?.lowStockCount ?? 0;
    final outOfStockCount = inventoryState.summary?.outOfStockCount ?? 0;
    final totalAlerts = lowStockCount + outOfStockCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            'Quick Actions',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                color: AppColors.admin,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductListScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.warehouse_outlined,
                label: 'Inventory',
                color: totalAlerts > 0 ? AppColors.warning : AppColors.accent,
                badge: totalAlerts > 0 ? totalAlerts : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventoryScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                color: AppColors.security,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrdersListScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.people_outline_rounded,
                label: 'Users',
                color: AppColors.customer,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UsersListScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            'Analytics',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.bar_chart_rounded,
                label: 'Sales',
                color: AppColors.admin,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SalesReportsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                color: AppColors.accent,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductPerformanceScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickActionCard(
          icon: Icons.people_outline_rounded,
          label: 'Customer Analytics',
          color: AppColors.security,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerAnalyticsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    final analyticsState = ref.watch(analyticsProvider);

    return DateRangeSelector(
      selectedRange: analyticsState.selectedRange,
      onRangeChanged: (range) {
        ref.read(analyticsProvider.notifier).fetchRevenueChart(range: range);
      },
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardSm,
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : badge.toString(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.pure,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.voidBlack,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Activity',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            'View All',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.admin,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityList(AdminDashboardData? data) {
    final recentOrders = data?.recentOrders ?? [];

    if (recentOrders.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            color: AppColors.pure,
            borderRadius: AppSpacing.borderRadiusMd,
            boxShadow: AppShadows.sm,
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: AppColors.mist,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No recent orders',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final order = recentOrders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildOrderItem(order),
          );
        },
        childCount: recentOrders.length,
      ),
    );
  }

  Widget _buildOrderItem(RecentOrder order) {
    final color = order.status == 'paid' ? AppColors.accent : AppColors.warning;
    final icon = order.status == 'paid'
        ? Icons.receipt_outlined
        : Icons.pending_outlined;

    return Container(
      padding: AppSpacing.cardSm,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\u20B9${order.totalAmount.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(order.createdAt),
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatNumber(double number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}
