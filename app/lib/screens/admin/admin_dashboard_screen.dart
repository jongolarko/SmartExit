import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/core.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Mock data - would come from API in production
  final double todayRevenue = 45680;
  final int totalOrders = 127;
  final int activeUsers = 89;
  final int alerts = 3;

  final List<Map<String, dynamic>> recentActivity = [
    {
      "type": "order",
      "description": "New order completed",
      "amount": 1250,
      "time": "2 min ago",
    },
    {
      "type": "exit",
      "description": "Exit QR verified",
      "customer": "Rahul Sharma",
      "time": "5 min ago",
    },
    {
      "type": "order",
      "description": "New order completed",
      "amount": 890,
      "time": "8 min ago",
    },
    {
      "type": "alert",
      "description": "Invalid QR attempt",
      "location": "Gate 2",
      "time": "15 min ago",
    },
    {
      "type": "exit",
      "description": "Exit QR verified",
      "customer": "Priya Patel",
      "time": "18 min ago",
    },
  ];

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.screenAll,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildMetricCards(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildRevenueChart(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildRecentActivityHeader(),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                sliver: _buildActivityList(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Back button
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
                Icons.arrow_back_ios_new_rounded,
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

  Widget _buildMetricCards() {
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
                trend: '+12.5%',
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
                trend: '+8.2%',
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
                label: 'Active Users',
                value: activeUsers.toString(),
                icon: Icons.people_outline_rounded,
                color: AppColors.security,
                trend: '+3.1%',
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
                trend: alerts > 0 ? '$alerts new' : 'None',
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

  Widget _buildRevenueChart() {
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  'This Week',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.steel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20000,
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
                      interval: 20000,
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
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()],
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
                maxX: 6,
                minY: 0,
                maxY: 60000,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 28000),
                      FlSpot(1, 35000),
                      FlSpot(2, 32000),
                      FlSpot(3, 41000),
                      FlSpot(4, 38000),
                      FlSpot(5, 52000),
                      FlSpot(6, 45680),
                    ],
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

  Widget _buildActivityList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final activity = recentActivity[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildActivityItem(activity),
          );
        },
        childCount: recentActivity.length,
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    Color color;

    switch (activity["type"]) {
      case "order":
        icon = Icons.receipt_outlined;
        color = AppColors.accent;
        break;
      case "exit":
        icon = Icons.exit_to_app_rounded;
        color = AppColors.security;
        break;
      case "alert":
        icon = Icons.warning_amber_rounded;
        color = AppColors.warning;
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.steel;
    }

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
                  activity["description"],
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity["customer"] ??
                      activity["location"] ??
                      (activity["amount"] != null
                          ? '\u20B9${activity["amount"]}'
                          : ''),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            activity["time"],
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
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
