import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import 'product_form_screen.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).fetchProducts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    ref.read(productsProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);

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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.steel,
                  ),
                  border: InputBorder.none,
                ),
                style: AppTypography.bodyMedium,
                onSubmitted: _onSearch,
              )
            : Text(
                'Products',
                style: AppTypography.headlineSmall,
              ),
        centerTitle: !_isSearching,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search_rounded,
              color: AppColors.voidBlack,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(productsProvider.notifier).clearSearch();
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductFormScreen(),
            ),
          );
        },
        backgroundColor: AppColors.admin,
        foregroundColor: AppColors.pure,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productsProvider.notifier).refresh(),
        color: AppColors.admin,
        child: _buildContent(productsState),
      ),
    );
  }

  Widget _buildContent(ProductsState state) {
    if (state.isLoading && state.products.isEmpty) {
      return _buildLoadingState();
    }

    if (state.error != null && state.products.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.products.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: AppSpacing.screenAll,
      itemCount: state.products.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.products.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.admin),
            ),
          );
        }

        final product = state.products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildProductCard(product),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: AppSpacing.screenAll,
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Shimmer.fromColors(
            baseColor: AppColors.cloud,
            highlightColor: AppColors.pure,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: AppSpacing.borderRadiusXl,
              ),
            ),
          ),
        );
      },
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
              'Failed to load products',
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
              onPressed: () => ref.read(productsProvider.notifier).fetchProducts(),
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

  Widget _buildEmptyState() {
    final isSearching = ref.watch(productsProvider).searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: AppSpacing.screenAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.adminLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.admin,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isSearching ? 'No products found' : 'No products yet',
              style: AppTypography.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Add your first product to get started',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.steel),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.admin,
                  foregroundColor: AppColors.pure,
                  padding: AppSpacing.buttonPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductFormScreen(product: product),
          ),
        );
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showProductOptionsSheet(product);
      },
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppShadows.sm,
          border: product.isOutOfStock
              ? Border.all(color: AppColors.error.withOpacity(0.3), width: 1)
              : product.isLowStock
                  ? Border.all(color: AppColors.warning.withOpacity(0.3), width: 1)
                  : null,
        ),
        child: Row(
          children: [
            // Stock indicator bar
            Container(
              width: 4,
              height: 64,
              decoration: BoxDecoration(
                color: _getStockIndicatorColor(product),
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: AppSpacing.borderRadiusMd,
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.steel,
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.steel,
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_2_outlined,
                        size: 12,
                        color: AppColors.steel,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.barcode,
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\u20B9${product.price.toStringAsFixed(2)}',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.admin,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (product.stock != null) _buildStockBadge(product),
                    ],
                  ),
                ],
              ),
            ),
            // Quick action buttons
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showQuickAdjustDialog(product);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.adminLight,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.admin,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStockIndicatorColor(Product product) {
    if (product.stock == null) return AppColors.mist;
    if (product.isOutOfStock) return AppColors.error;
    if (product.isLowStock) return AppColors.warning;
    return AppColors.accent;
  }

  void _showProductOptionsSheet(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.pure,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildOptionTile(
                      icon: Icons.edit_outlined,
                      label: 'Edit Product',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductFormScreen(product: product),
                          ),
                        );
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.add_circle_outline,
                      label: 'Adjust Stock',
                      onTap: () {
                        Navigator.pop(context);
                        _showQuickAdjustDialog(product);
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.history_rounded,
                      label: 'Stock History',
                      onTap: () {
                        Navigator.pop(context);
                        _showStockHistorySheet(product);
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete Product',
                      color: AppColors.error,
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(product);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? AppColors.admin).withOpacity(0.1),
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: Icon(icon, color: color ?? AppColors.admin, size: 20),
      ),
      title: Text(
        label,
        style: AppTypography.titleSmall.copyWith(
          color: color ?? AppColors.voidBlack,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color ?? AppColors.steel,
      ),
    );
  }

  void _showQuickAdjustDialog(Product product) {
    final quantityController = TextEditingController();
    bool isAdding = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.pure,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  'Quick Stock Adjust',
                  style: AppTypography.headlineSmall,
                ),
                Text(
                  '${product.name} (Current: ${product.stock ?? 0})',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.steel),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => isAdding = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isAdding ? AppColors.accent : AppColors.cloud,
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: isAdding ? AppColors.pure : AppColors.steel,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: isAdding ? AppColors.pure : AppColors.steel,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => isAdding = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isAdding ? AppColors.error : AppColors.cloud,
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.remove_rounded,
                                  color: !isAdding ? AppColors.pure : AppColors.steel,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Remove',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: !isAdding ? AppColors.pure : AppColors.steel,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter quantity',
                    filled: true,
                    fillColor: AppColors.cloud,
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      isAdding ? Icons.add_rounded : Icons.remove_rounded,
                      color: isAdding ? AppColors.accent : AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final qty = int.tryParse(quantityController.text);
                      if (qty == null || qty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid quantity'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);

                      final result = await ApiService.adjustStock(
                        productId: product.id,
                        quantity: isAdding ? qty : -qty,
                        changeType: isAdding ? 'receipt' : 'adjustment',
                        reason: isAdding ? 'Quick restock' : 'Quick adjustment',
                      );

                      if (mounted) {
                        if (result['success'] == true) {
                          ref.read(productsProvider.notifier).refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isAdding
                                    ? 'Added $qty to stock'
                                    : 'Removed $qty from stock',
                              ),
                              backgroundColor: AppColors.accent,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['error'] ?? 'Failed to adjust stock'),
                              backgroundColor: AppColors.error,
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
                    child: const Text('Confirm'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStockHistorySheet(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.pure,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
              ),
              Padding(
                padding: AppSpacing.screenAll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock History',
                      style: AppTypography.headlineSmall,
                    ),
                    Text(
                      product.name,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.steel),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: ApiService.getProductStockHistory(productId: product.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.admin),
                      );
                    }

                    if (snapshot.data?['success'] != true) {
                      return Center(
                        child: Text(
                          'Failed to load history',
                          style: AppTypography.bodyMedium,
                        ),
                      );
                    }

                    final history = snapshot.data!['history'] as List? ?? [];

                    if (history.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: AppColors.mist,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No history yet',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.steel,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        final qtyChange = entry['quantity_change'] ?? 0;
                        final isAdd = qtyChange > 0;
                        final color = isAdd ? AppColors.accent : AppColors.error;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: AppSpacing.cardSm,
                          decoration: BoxDecoration(
                            color: AppColors.cloud,
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: AppSpacing.borderRadiusSm,
                                ),
                                child: Icon(
                                  isAdd
                                      ? Icons.add_circle_outline
                                      : Icons.remove_circle_outline,
                                  color: color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatChangeType(entry['change_type']),
                                      style: AppTypography.labelMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (entry['reason'] != null)
                                      Text(
                                        entry['reason'],
                                        style: AppTypography.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isAdd ? '+' : ''}$qtyChange',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _formatHistoryDate(entry['created_at']),
                                    style: AppTypography.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatChangeType(String? type) {
    switch (type) {
      case 'sale':
        return 'Sale';
      case 'adjustment':
        return 'Adjustment';
      case 'receipt':
        return 'Receipt';
      case 'damage':
        return 'Damage';
      case 'return':
        return 'Return';
      case 'correction':
        return 'Correction';
      default:
        return type ?? 'Unknown';
    }
  }

  String _formatHistoryDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';

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

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        title: Text(
          'Delete Product?',
          style: AppTypography.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.labelMedium.copyWith(color: AppColors.steel),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final result = await ApiService.deleteProduct(productId: product.id);

              if (mounted) {
                if (result['success'] == true) {
                  ref.read(productsProvider.notifier).refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['soft_deleted'] == true
                            ? 'Product deactivated'
                            : 'Product deleted',
                      ),
                      backgroundColor: AppColors.accent,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['error'] ?? 'Failed to delete product'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.pure,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(Product product) {
    Color bgColor;
    Color textColor;
    String text;

    if (product.isOutOfStock) {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
      text = 'Out of stock';
    } else if (product.isLowStock) {
      bgColor = AppColors.warningLight;
      textColor = AppColors.warning;
      text = '${product.stock} left';
    } else {
      bgColor = AppColors.accentLight;
      textColor = AppColors.accent;
      text = '${product.stock} in stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
