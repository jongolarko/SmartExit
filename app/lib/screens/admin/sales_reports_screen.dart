import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/core.dart';
import '../../providers/sales_reports_provider.dart';
import '../../services/export_service.dart';

class SalesReportsScreen extends ConsumerStatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  ConsumerState<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends ConsumerState<SalesReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesReportsProvider.notifier).fetchAllData('daily');
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final periods = ['daily', 'weekly', 'monthly'];
        ref.read(salesReportsProvider.notifier).fetchSalesSummary(periods[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesState = ref.watch(salesReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.pearl,
      appBar: AppBar(
        backgroundColor: AppColors.pure,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.voidBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sales Reports',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.voidBlack,
          ),
        ),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.admin,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.file_download_outlined, color: AppColors.admin),
              onPressed: _handleExport,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.admin,
          labelColor: AppColors.admin,
          unselectedLabelColor: AppColors.steel,
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
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
            onRefresh: _handleRefresh,
            color: AppColors.admin,
            child: _buildContent(salesState),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final periods = ['daily', 'weekly', 'monthly'];
    await ref.read(salesReportsProvider.notifier).fetchAllData(periods[_tabController.index]);
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      await ExportService.exportSalesReport(startDate: startDate, endDate: now);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sales report exported successfully'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildContent(SalesReportsState salesState) {
    if (salesState.isLoading && salesState.salesData.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.admin),
      );
    }

    if (salesState.error != null && salesState.salesData.isEmpty) {
      return _buildErrorState(salesState.error!);
    }

    if (salesState.salesData.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screenAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(salesState),
                const SizedBox(height: AppSpacing.xl),
                _buildSalesTrendChart(salesState),
                const SizedBox(height: AppSpacing.xl),
                _buildPeakHoursSection(salesState),
                const SizedBox(height: AppSpacing.xl),
                if (salesState.refundRate != null) _buildRefundRateCard(salesState.refundRate!),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load sales data',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(error, style: AppTypography.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.steel,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No sales data available',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sales data will appear here once orders are completed',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(SalesReportsState salesState) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Total Revenue',
                value: '₹${_formatNumber(salesState.totalRevenue)}',
                icon: Icons.currency_rupee,
                color: AppColors.admin,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildMetricCard(
                label: 'Avg Order',
                value: '₹${salesState.avgOrderValue.toStringAsFixed(0)}',
                icon: Icons.shopping_bag_outlined,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildMetricCard(
          label: 'Total Orders',
          value: salesState.totalOrders.toString(),
          icon: Icons.receipt_long_outlined,
          color: AppColors.security,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
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
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSalesTrendChart(SalesReportsState salesState) {
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
          Text(
            'Sales Trend',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(salesState.salesData),
                barGroups: salesState.salesData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.revenue,
                        color: AppColors.admin,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
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
                        if (value.toInt() >= 0 && value.toInt() < salesState.salesData.length) {
                          final data = salesState.salesData[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _formatDate(data.date),
                              style: AppTypography.labelSmall,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateMaxY(salesState.salesData) / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.mist,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursSection(SalesReportsState salesState) {
    if (salesState.peakHours.isEmpty) return const SizedBox.shrink();

    final maxOrders = salesState.peakHours.map((h) => h.orderCount).reduce((a, b) => a > b ? a : b);

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
          Text(
            'Peak Hours',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 24,
            itemBuilder: (context, index) {
              final hourData = salesState.peakHours.firstWhere(
                (h) => h.hour == index,
                orElse: () => PeakHourData(hour: index, orderCount: 0),
              );
              final intensity = maxOrders > 0 ? hourData.orderCount / maxOrders : 0.0;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.admin.withOpacity(0.1 + (intensity * 0.9)),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: AppTypography.labelSmall.copyWith(
                      color: intensity > 0.5 ? AppColors.pure : AppColors.voidBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRefundRateCard(RefundRateData refundRate) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.warningLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Center(
                  child: Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Refund Rate',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${refundRate.refundRate.toStringAsFixed(1)}%',
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Orders', style: AppTypography.labelSmall),
                  Text(
                    refundRate.totalPaidOrders.toString(),
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Refunded', style: AppTypography.labelSmall),
                  Text(
                    refundRate.refundedOrders.toString(),
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount', style: AppTypography.labelSmall),
                  Text(
                    '₹${_formatNumber(refundRate.totalRefundAmount)}',
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(2)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(2)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toStringAsFixed(0);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference < 7) {
        return DateFormat('EEE').format(date); // Mon, Tue, etc.
      } else if (difference < 60) {
        return DateFormat('MMM d').format(date); // Jan 1
      } else {
        return DateFormat('MMM').format(date); // Jan
      }
    } catch (e) {
      return dateStr;
    }
  }

  double _calculateMaxY(List<SalesSummary> data) {
    if (data.isEmpty) return 100000;
    final maxRevenue = data.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);
    final roundedMax = ((maxRevenue / 10000).ceil() * 10000).toDouble();
    return roundedMax;
  }
}
