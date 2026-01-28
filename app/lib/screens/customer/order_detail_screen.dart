import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderDetailProvider.notifier).fetchOrderDetails(widget.orderId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(orderDetailProvider);

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
          'Order Details',
          style: AppTypography.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: _buildContent(detailState),
    );
  }

  Widget _buildContent(OrderDetailState state) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (state.detail == null) {
      return const Center(child: Text('Order not found'));
    }

    final detail = state.detail!;

    return SingleChildScrollView(
      padding: AppSpacing.screenAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(detail),
          const SizedBox(height: AppSpacing.lg),
          _buildExitStatus(detail.exitStatus),
          const SizedBox(height: AppSpacing.lg),
          _buildItemsSection(detail.items),
          const SizedBox(height: AppSpacing.lg),
          _buildSummarySection(detail),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: AppSpacing.screenAll,
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: AppColors.cloud,
            highlightColor: AppColors.pure,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: AppSpacing.borderRadiusXl,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Shimmer.fromColors(
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
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Shimmer.fromColors(
                baseColor: AppColors.cloud,
                highlightColor: AppColors.pure,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                ),
              ),
            ),
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
              'Failed to load order',
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
              onPressed: () => ref
                  .read(orderDetailProvider.notifier)
                  .fetchOrderDetails(widget.orderId),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.customer,
                foregroundColor: AppColors.pure,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderDetail detail) {
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
                'Order #${detail.order.id.substring(0, 8).toUpperCase()}',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  'Paid',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.steel,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDateTime(detail.order.createdAt),
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          if (detail.order.paidAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Paid on ${_formatDateTime(detail.order.paidAt!)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExitStatus(ExitStatus? exitStatus) {
    if (exitStatus == null) {
      return Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: const Icon(
                Icons.qr_code_2_outlined,
                color: AppColors.steel,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Exit Token',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Exit token not generated for this order',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Color statusColor;
    IconData statusIcon;
    Color bgColor;

    if (exitStatus.verified) {
      if (exitStatus.allowed == true) {
        statusColor = AppColors.accent;
        statusIcon = Icons.check_circle_rounded;
        bgColor = AppColors.accentLight;
      } else {
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        bgColor = AppColors.errorLight;
      }
    } else if (exitStatus.isExpired) {
      statusColor = AppColors.warning;
      statusIcon = Icons.timer_off_outlined;
      bgColor = AppColors.warningLight;
    } else {
      statusColor = AppColors.security;
      statusIcon = Icons.pending_outlined;
      bgColor = AppColors.securityLight;
    }

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exit Status',
                  style: AppTypography.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  exitStatus.statusText,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (exitStatus.verified && exitStatus.verifiedAt != null)
            Text(
              _formatTime(exitStatus.verifiedAt!),
              style: AppTypography.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(List<OrderItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            'Items (${items.length})',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.pure,
            borderRadius: AppSpacing.borderRadiusXl,
            boxShadow: AppShadows.sm,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.mist.withOpacity(0.5),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemRow(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: AppSpacing.card,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cloud,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: AppSpacing.borderRadiusMd,
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.steel,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.steel,
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '\u20B9${item.price.toStringAsFixed(2)} x ${item.quantity}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '\u20B9${item.totalPrice.toStringAsFixed(2)}',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(OrderDetail detail) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', detail.order.totalAmount),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryRow('Tax', 0, isZero: true),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 1,
            color: AppColors.mist.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\u20B9${detail.order.totalAmount.toStringAsFixed(2)}',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.customer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isZero = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.steel,
          ),
        ),
        Text(
          isZero ? 'Included' : '\u20B9${amount.toStringAsFixed(2)}',
          style: AppTypography.bodyMedium.copyWith(
            color: isZero ? AppColors.steel : AppColors.voidBlack,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
