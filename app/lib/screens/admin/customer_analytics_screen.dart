import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/core.dart';
import '../../providers/customer_analytics_provider.dart';
import '../../services/export_service.dart';

class CustomerAnalyticsScreen extends ConsumerStatefulWidget {
  const CustomerAnalyticsScreen({super.key});

  @override
  ConsumerState<CustomerAnalyticsScreen> createState() => _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends ConsumerState<CustomerAnalyticsScreen> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerAnalyticsProvider.notifier).fetchAllData(range: '30d');
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerAnalyticsProvider);

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
          'Customer Analytics',
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
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.admin,
          child: _buildContent(customerState),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await ref.read(customerAnalyticsProvider.notifier).fetchAllData(
      range: ref.read(customerAnalyticsProvider).selectedRange,
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      await ExportService.exportCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer analytics exported successfully'),
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

  Widget _buildContent(CustomerAnalyticsState customerState) {
    if (customerState.isLoading && customerState.acquisitionData.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.admin),
      );
    }

    if (customerState.error != null && customerState.acquisitionData.isEmpty) {
      return _buildErrorState(customerState.error!);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screenAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateRangeSelector(customerState),
                const SizedBox(height: AppSpacing.xl),
                if (customerState.acquisitionData.isNotEmpty)
                  _buildAcquisitionChart(customerState),
                const SizedBox(height: AppSpacing.xl),
                if (customerState.repeatRate != null)
                  _buildKeyMetrics(customerState),
                const SizedBox(height: AppSpacing.xl),
                if (customerState.segmentation.isNotEmpty)
                  _buildSegmentationChart(customerState),
                const SizedBox(height: AppSpacing.xl),
                if (customerState.clvData.isNotEmpty)
                  _buildCLVLeaderboard(customerState),
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
              'Failed to load customer data',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(error, style: AppTypography.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(CustomerAnalyticsState customerState) {
    return DateRangeSelector(
      selectedRange: customerState.selectedRange,
      onRangeChanged: (range) {
        ref.read(customerAnalyticsProvider.notifier).setRange(range);
      },
    );
  }

  Widget _buildAcquisitionChart(CustomerAnalyticsState customerState) {
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
            'Customer Acquisition',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: LineChart(
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
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
                        if (value.toInt() >= 0 && value.toInt() < customerState.acquisitionData.length) {
                          final date = customerState.acquisitionData[value.toInt()].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM d').format(date),
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
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: customerState.acquisitionData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.newCustomers.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.accent,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withOpacity(0.3),
                          AppColors.accent.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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

  Widget _buildKeyMetrics(CustomerAnalyticsState customerState) {
    final repeatRate = customerState.repeatRate!;

    return Row(
      children: [
        Expanded(
          child: _buildRepeatRateCard(repeatRate),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            padding: AppSpacing.card,
            decoration: BoxDecoration(
              color: AppColors.pure,
              borderRadius: AppSpacing.borderRadiusXl,
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.security.withOpacity(0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: const Center(
                    child: Icon(Icons.people_outline_rounded, color: AppColors.security, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  repeatRate.totalCustomers.toString(),
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.voidBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Total Customers', style: AppTypography.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatRateCard(RepeatRateData repeatRate) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: repeatRate.repeatRate / 100,
                  backgroundColor: AppColors.cloud,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  strokeWidth: 10,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${repeatRate.repeatRate.toStringAsFixed(1)}%',
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  Text('Repeat', style: AppTypography.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${repeatRate.repeatCustomers} of ${repeatRate.totalCustomers}',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentationChart(CustomerAnalyticsState customerState) {
    final segments = customerState.segmentation;
    final segmentColors = {
      'VIP': AppColors.admin,
      'Loyal': AppColors.security,
      'Regular': AppColors.accent,
      'New': AppColors.steel,
    };

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
            'Customer Segmentation',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: segments.map((segment) {
                  final color = segmentColors[segment.segment] ?? AppColors.steel;
                  return PieChartSectionData(
                    value: segment.count.toDouble(),
                    title: '${segment.segment}\n${segment.count}',
                    color: color,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pure,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCLVLeaderboard(CustomerAnalyticsState customerState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Lifetime Value',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        ...customerState.clvData.take(50).toList().asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final customer = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildLeaderboardCard(customer, rank),
          );
        }),
      ],
    );
  }

  Widget _buildLeaderboardCard(CustomerCLV customer, int rank) {
    final isTopThree = rank <= 3;
    final medalColor = rank == 1
        ? const Color(0xFFFFD700) // Gold
        : rank == 2
            ? const Color(0xFFC0C0C0) // Silver
            : const Color(0xFFCD7F32); // Bronze

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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isTopThree ? medalColor.withOpacity(0.2) : AppColors.cloud,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isTopThree ? medalColor : AppColors.steel,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.phoneNumber, style: AppTypography.titleSmall),
                Text(
                  '${customer.orderCount} orders${customer.lastPurchase != null ? ' • Last: ${_formatDate(customer.lastPurchase!)}' : ''}',
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            '₹${_formatNumber(customer.lifetimeValue)}',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
