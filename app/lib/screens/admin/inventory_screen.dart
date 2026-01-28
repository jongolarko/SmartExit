import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).fetchLowStock();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: AppColors.pearl,
      appBar: AppBar(
        backgroundColor: AppColors.pure,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cloud,
              borderRadius: AppSpacing.borderRadiusMd,
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
        title: Text(
          'Inventory',
          style: AppTypography.headlineSmall,
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.admin,
          unselectedLabelColor: AppColors.steel,
          indicatorColor: AppColors.admin,
          tabs: const [
            Tab(text: 'Low Stock'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLowStockTab(inventoryState),
          _buildHistoryTab(inventoryState),
        ],
      ),
    );
  }

  Widget _buildLowStockTab(InventoryState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(inventoryProvider.notifier).fetchLowStock(),
      color: AppColors.admin,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenAll,
              child: _buildSummaryCards(state.summary),
            ),
          ),
          if (state.isLoading && state.lowStockProducts.isEmpty)
            SliverToBoxAdapter(child: _buildLoadingState())
          else if (state.error != null && state.lowStockProducts.isEmpty)
            SliverToBoxAdapter(child: _buildErrorState(state.error!))
          else if (state.lowStockProducts.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = state.lowStockProducts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildLowStockCard(product),
                    );
                  },
                  childCount: state.lowStockProducts.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(InventorySummary? summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Overview',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: 'Out of Stock',
                value: summary?.outOfStockCount.toString() ?? '0',
                icon: Icons.error_outline_rounded,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildSummaryCard(
                label: 'Low Stock',
                value: summary?.lowStockCount.toString() ?? '0',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: 'Healthy',
                value: summary?.healthyStockCount.toString() ?? '0',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildSummaryCard(
                label: 'Inventory Value',
                value:
                    '\u20B9${_formatNumber(summary?.totalInventoryValue ?? 0)}',
                icon: Icons.inventory_2_outlined,
                color: AppColors.admin,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Low Stock Products',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: AppSpacing.cardSm,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 18),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockCard(LowStockProduct product) {
    final color = product.isOutOfStock
        ? AppColors.error
        : product.isCritical
            ? AppColors.warning
            : AppColors.warning;

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
        border: product.isOutOfStock
            ? Border.all(color: AppColors.error.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Center(
                  child: Icon(
                    product.isOutOfStock
                        ? Icons.error_outline_rounded
                        : Icons.warning_amber_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_2_outlined,
                          size: 12,
                          color: AppColors.steel,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.barcode,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStockBadge(product),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current: ${product.stock}',
                      style: AppTypography.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Reorder at: ${product.reorderLevel}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAdjustStockDialog(product),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Restock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.admin,
                  foregroundColor: AppColors.pure,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(LowStockProduct product) {
    final color = product.isOutOfStock ? AppColors.error : AppColors.warning;
    final bgColor =
        product.isOutOfStock ? AppColors.errorLight : AppColors.warningLight;
    final text = product.isOutOfStock ? 'OUT' : '${product.stock} left';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHistoryTab(InventoryState state) {
    // Fetch report on first build
    if (state.stockMovements.isEmpty && !state.isLoading && state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(inventoryProvider.notifier).fetchStockReport();
      });
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(inventoryProvider.notifier).fetchStockReport(),
      color: AppColors.admin,
      child: CustomScrollView(
        slivers: [
          if (state.reportSummary != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenAll,
                child: _buildReportSummary(state.reportSummary!),
              ),
            ),
          if (state.isLoading && state.stockMovements.isEmpty)
            SliverToBoxAdapter(child: _buildLoadingState())
          else if (state.stockMovements.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyHistoryState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final movement = state.stockMovements[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildMovementCard(movement),
                    );
                  },
                  childCount: state.stockMovements.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummary(ReportSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last 30 Days',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                label: 'Sold',
                value: '-${summary.totalSold}',
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildReportCard(
                label: 'Received',
                value: '+${summary.totalReceived}',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildReportCard(
                label: 'Damaged',
                value: '-${summary.totalDamaged}',
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Stock Movements',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildReportCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: AppSpacing.cardSm,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMovementCard(StockAuditLog movement) {
    final isAddition = movement.isAddition;
    final color = isAddition ? AppColors.accent : AppColors.error;
    final icon = isAddition ? Icons.add_circle_outline : Icons.remove_circle_outline;

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
                  movement.productName,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Text(
                        movement.changeTypeDisplay,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (movement.reason != null) ...[
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          movement.reason!,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isAddition ? '+' : ''}${movement.quantityChange}',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                _formatDate(movement.createdAt),
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: AppSpacing.screenAll,
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Shimmer.fromColors(
              baseColor: AppColors.cloud,
              highlightColor: AppColors.pure,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  borderRadius: AppSpacing.borderRadiusXl,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
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
            'Failed to load inventory',
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
            onPressed: () => ref.read(inventoryProvider.notifier).fetchLowStock(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.admin,
              foregroundColor: AppColors.pure,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: AppSpacing.screenAll,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'All stocked up!',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No products are running low on stock',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.steel),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Padding(
      padding: AppSpacing.screenAll,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cloud,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 40,
              color: AppColors.steel,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No movements yet',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Stock changes will appear here',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.steel),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(LowStockProduct product) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedType = 'receipt';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.pure,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: AppSpacing.screenAll,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Adjust Stock',
                    style: AppTypography.headlineSmall,
                  ),
                  Text(
                    product.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Adjustment Type',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      _buildTypeChip('Receipt', 'receipt', selectedType,
                          (type) => setDialogState(() => selectedType = type)),
                      _buildTypeChip('Return', 'return', selectedType,
                          (type) => setDialogState(() => selectedType = type)),
                      _buildTypeChip('Damage', 'damage', selectedType,
                          (type) => setDialogState(() => selectedType = type)),
                      _buildTypeChip('Correction', 'correction', selectedType,
                          (type) => setDialogState(() => selectedType = type)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Quantity',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText:
                          selectedType == 'damage' ? 'Enter damaged qty' : 'Enter quantity to add',
                      filled: true,
                      fillColor: AppColors.cloud,
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Reason (optional)',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Weekly restock, Supplier delivery',
                      filled: true,
                      fillColor: AppColors.cloud,
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Consumer(
                    builder: (context, ref, _) {
                      final isAdjusting =
                          ref.watch(inventoryProvider).isAdjusting;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isAdjusting
                              ? null
                              : () async {
                                  final qty =
                                      int.tryParse(quantityController.text);
                                  if (qty == null || qty <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please enter a valid quantity'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }

                                  // For damage, quantity should be negative
                                  final adjustQty =
                                      selectedType == 'damage' ? -qty : qty;

                                  final success = await ref
                                      .read(inventoryProvider.notifier)
                                      .adjustStock(
                                        productId: product.id,
                                        quantity: adjustQty,
                                        changeType: selectedType,
                                        reason: reasonController.text.isEmpty
                                            ? null
                                            : reasonController.text,
                                      );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Stock adjusted successfully'),
                                          backgroundColor: AppColors.accent,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.admin,
                            foregroundColor: AppColors.pure,
                            padding: AppSpacing.buttonPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusLg,
                            ),
                          ),
                          child: isAdjusting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.pure,
                                  ),
                                )
                              : const Text('Confirm Adjustment'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(
    String label,
    String value,
    String selected,
    Function(String) onSelect,
  ) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.admin : AppColors.cloud,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.pure : AppColors.voidBlack,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${date.day}/${date.month}';
  }
}
