import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/core.dart';
import '../../providers/product_performance_provider.dart';
import '../../services/export_service.dart';

class ProductPerformanceScreen extends ConsumerStatefulWidget {
  const ProductPerformanceScreen({super.key});

  @override
  ConsumerState<ProductPerformanceScreen> createState() => _ProductPerformanceScreenState();
}

class _ProductPerformanceScreenState extends ConsumerState<ProductPerformanceScreen> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productPerformanceProvider.notifier).fetchAllData(metric: 'revenue');
    });
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productPerformanceProvider);

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
          'Product Performance',
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
          child: _buildContent(productState),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await ref.read(productPerformanceProvider.notifier).fetchAllData(
      metric: ref.read(productPerformanceProvider).selectedMetric,
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      await ExportService.exportProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product performance exported successfully'),
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

  Widget _buildContent(ProductPerformanceState productState) {
    if (productState.isLoading && productState.topProducts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.admin),
      );
    }

    if (productState.error != null && productState.topProducts.isEmpty) {
      return _buildErrorState(productState.error!);
    }

    if (productState.topProducts.isEmpty) {
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
                _buildMetricToggle(productState),
                const SizedBox(height: AppSpacing.xl),
                _buildTopProductsSection(productState),
                const SizedBox(height: AppSpacing.xl),
                if (productState.slowMovers.isNotEmpty) ...[
                  _buildSlowMoversSection(productState),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (productState.turnoverData.isNotEmpty) ...[
                  _buildStockTurnoverChart(productState),
                  const SizedBox(height: AppSpacing.xl),
                ],
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
              'Failed to load product data',
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
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.steel,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No product data available',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Product performance data will appear here',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricToggle(ProductPerformanceState productState) {
    return Row(
      children: [
        FilterChip(
          selected: productState.selectedMetric == 'revenue',
          label: const Text('By Revenue'),
          onSelected: (_) {
            ref.read(productPerformanceProvider.notifier).setMetric('revenue');
          },
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.accent.withOpacity(0.2),
          labelStyle: TextStyle(
            color: productState.selectedMetric == 'revenue' ? AppColors.accent : AppColors.steel,
            fontWeight: productState.selectedMetric == 'revenue' ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: productState.selectedMetric == 'revenue' ? AppColors.accent : AppColors.mist,
            width: 1.5,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        FilterChip(
          selected: productState.selectedMetric == 'quantity',
          label: const Text('By Quantity'),
          onSelected: (_) {
            ref.read(productPerformanceProvider.notifier).setMetric('quantity');
          },
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.accent.withOpacity(0.2),
          labelStyle: TextStyle(
            color: productState.selectedMetric == 'quantity' ? AppColors.accent : AppColors.steel,
            fontWeight: productState.selectedMetric == 'quantity' ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: productState.selectedMetric == 'quantity' ? AppColors.accent : AppColors.mist,
            width: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductsSection(ProductPerformanceState productState) {
    if (productState.topProducts.isEmpty) return const SizedBox.shrink();

    final maxValue = productState.selectedMetric == 'revenue'
        ? productState.topProducts.map((p) => p.revenue).reduce((a, b) => a > b ? a : b)
        : productState.topProducts.map((p) => p.unitsSold.toDouble()).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Products',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        ...productState.topProducts.map((product) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildTopProductCard(product, maxValue),
        )),
      ],
    );
  }

  Widget _buildTopProductCard(TopProduct product, double maxValue) {
    final value = ref.read(productPerformanceProvider).selectedMetric == 'revenue'
        ? product.revenue
        : product.unitsSold.toDouble();
    final percentage = maxValue > 0 ? value / maxValue : 0.0;

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
              Expanded(
                child: Text(product.name, style: AppTypography.titleSmall),
              ),
              Text(
                ref.read(productPerformanceProvider).selectedMetric == 'revenue'
                    ? '₹${_formatNumber(product.revenue)}'
                    : '${product.unitsSold} units',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${product.unitsSold} units sold • ${product.barcode}',
            style: AppTypography.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusFull,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.cloud,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlowMoversSection(ProductPerformanceState productState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Slow Movers',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...productState.slowMovers.take(5).map((product) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildSlowMoverCard(product),
        )),
      ],
    );
  }

  Widget _buildSlowMoverCard(SlowMover product) {
    return Container(
      padding: AppSpacing.cardSm,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.warningLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTypography.titleSmall),
                Text('Stock: ${product.stock} • ${product.barcode}', style: AppTypography.labelSmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Text(
              '${product.daysSinceLastSale}d',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockTurnoverChart(ProductPerformanceState productState) {
    if (productState.turnoverData.isEmpty) return const SizedBox.shrink();

    final topTurnover = productState.turnoverData.take(10).toList();
    final maxTurnover = topTurnover.map((t) => t.turnoverRate).reduce((a, b) => a > b ? a : b);

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
            'Stock Turnover Rate',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxTurnover * 1.2,
                barGroups: topTurnover.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.turnoverRate,
                        color: AppColors.accent,
                        width: 20,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: AppTypography.labelSmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 80,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < topTurnover.length) {
                          final name = topTurnover[value.toInt()].productName;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                name.length > 12 ? '${name.substring(0, 12)}...' : name,
                                style: AppTypography.labelSmall,
                                textAlign: TextAlign.end,
                              ),
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
}
