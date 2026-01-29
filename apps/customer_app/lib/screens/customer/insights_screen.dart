import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/customer_theme.dart';
import '../../providers/insights_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsState = ref.watch(insightsStateProvider);
    final insightsAsync = ref.watch(spendingInsightsProvider);

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      appBar: AppBar(
        backgroundColor: CustomerTheme.surface,
        elevation: 0,
        title: const Text(
          'Spending Insights',
          style: TextStyle(
            color: CustomerTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CustomerTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Period selector
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week', label: Text('Week')),
                ButtonSegment(value: 'month', label: Text('Month')),
              ],
              selected: {insightsState.period},
              onSelectionChanged: (Set<String> newSelection) {
                ref.read(insightsStateProvider.notifier).setPeriod(newSelection.first);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return CustomerTheme.primaryBlue;
                  }
                  return CustomerTheme.background;
                }),
                foregroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return CustomerTheme.textSecondary;
                }),
              ),
            ),
          ),
        ],
      ),
      body: insightsAsync.when(
        data: (insights) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(insightsStateProvider.notifier).refreshCache();
            ref.invalidate(spendingInsightsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                _buildSummaryCards(insights.summary, insights.trend),
                const SizedBox(height: 24),

                // Spending chart
                _buildSpendingChart(context, ref, insightsState.period),
                const SizedBox(height: 24),

                // Category breakdown
                _buildCategorySection(insights.categories),
                const SizedBox(height: 24),

                // Top products
                _buildTopProductsSection(insights.topProducts),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: CustomerTheme.energeticOrange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load insights',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CustomerTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: CustomerTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(SpendingSummary summary, SpendingTrend trend) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Spent',
            '₹${summary.totalSpent.toStringAsFixed(2)}',
            trend.trend == 'increasing' ? Icons.trending_up : Icons.trending_down,
            trend.trend == 'increasing' ? CustomerTheme.accentGreen : CustomerTheme.energeticOrange,
            trend.changePercent != null ? '${trend.changePercent!.toStringAsFixed(1)}%' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Orders',
            '${summary.orderCount}',
            Icons.shopping_bag_outlined,
            CustomerTheme.primaryBlue,
            null,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? badge,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomerTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CustomerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: CustomerTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(BuildContext context, WidgetRef ref, String period) {
    final timelineAsync = ref.watch(spendingTimelineProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomerTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CustomerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          timelineAsync.when(
            data: (timeline) {
              if (timeline.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: Text('No data available')),
                );
              }

              return SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '₹${value.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: CustomerTheme.textSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < timeline.length) {
                              return Text(
                                timeline[value.toInt()].dayName.substring(0, 3),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: CustomerTheme.textSecondary,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: timeline
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.amount))
                            .toList(),
                        isCurved: true,
                        color: CustomerTheme.primaryBlue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: CustomerTheme.primaryBlue.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 200,
              child: Center(child: Text('Failed to load chart')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(List<CategorySpending> categories) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomerTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CustomerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryItem(category),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategorySpending category) {
    final colors = [
      CustomerTheme.primaryBlue,
      CustomerTheme.accentGreen,
      CustomerTheme.energeticOrange,
      CustomerTheme.coolPurple,
      CustomerTheme.funPink,
    ];
    final color = colors[category.category.hashCode % colors.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CustomerTheme.textPrimary,
              ),
            ),
            Text(
              '₹${category.total.toStringAsFixed(2)} (${category.percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: category.percentage / 100,
            backgroundColor: CustomerTheme.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductsSection(List<TopProduct> products) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomerTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CustomerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTopProductItem(index + 1, product),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopProductItem(int rank, TopProduct product) {
    return Row(
      children: [
        // Rank badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: rank == 1
                ? CustomerTheme.sunnyYellow
                : CustomerTheme.background,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: rank == 1 ? Colors.white : CustomerTheme.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Product info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CustomerTheme.textPrimary,
                ),
              ),
              Text(
                '${product.totalQuantity} items • ${product.orderCount} orders',
                style: const TextStyle(
                  fontSize: 12,
                  color: CustomerTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Amount
        Text(
          '₹${product.totalSpent.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CustomerTheme.accentGreen,
          ),
        ),
      ],
    );
  }
}
