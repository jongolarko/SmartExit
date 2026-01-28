import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import 'user_details_screen.dart';

class AdminOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState
    extends ConsumerState<AdminOrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersAdminProvider.notifier).fetchOrderDetails(widget.orderId);
    });
  }

  @override
  void dispose() {
    ref.read(ordersAdminProvider.notifier).clearSelectedOrder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersAdminProvider);
    final details = state.selectedOrderDetails;

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(state, details),
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
                  'Order Details',
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.voidBlack,
                  ),
                ),
                Text(
                  'View and manage order',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(OrdersAdminState state, AdminOrderDetails? details) {
    if (state.isLoading && details == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.admin),
      );
    }

    if (state.error != null && details == null) {
      return _buildErrorState(state.error!);
    }

    if (details == null) {
      return _buildErrorState('Order not found');
    }

    final order = details.order;
    final statusColor = _getStatusColor(order.status);
    final statusBgColor = _getStatusBgColor(order.status);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(ordersAdminProvider.notifier).fetchOrderDetails(widget.orderId),
      color: AppColors.admin,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Amount Card
            _buildStatusCard(order, statusColor, statusBgColor),
            const SizedBox(height: AppSpacing.lg),

            // Order Info
            _buildSectionTitle('Order Information'),
            const SizedBox(height: AppSpacing.sm),
            _buildOrderInfoCard(order),
            const SizedBox(height: AppSpacing.lg),

            // Customer Info
            _buildSectionTitle('Customer'),
            const SizedBox(height: AppSpacing.sm),
            _buildCustomerCard(order),
            const SizedBox(height: AppSpacing.lg),

            // Items
            _buildSectionTitle('Items (${details.items.length})'),
            const SizedBox(height: AppSpacing.sm),
            _buildItemsCard(details.items),
            const SizedBox(height: AppSpacing.lg),

            // Exit Status
            if (details.exit != null) ...[
              _buildSectionTitle('Exit Status'),
              const SizedBox(height: AppSpacing.sm),
              _buildExitCard(details.exit!),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Refund Info (if refunded)
            if (order.isRefunded) ...[
              _buildSectionTitle('Refund Details'),
              const SizedBox(height: AppSpacing.sm),
              _buildRefundCard(order),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Actions
            if (order.canRefund || order.canCancel) ...[
              _buildActionsSection(order, state.isProcessing),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(AdminOrder order, Color statusColor, Color statusBgColor) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    _formatStatus(order.status),
                    style: AppTypography.labelMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '\u20B9${order.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.voidBlack,
                  ),
                ),
                Text(
                  _formatDateTime(order.createdAt),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              _getStatusIcon(order.status),
              color: statusColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(AdminOrder order) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _buildInfoRow('Order ID', order.id.substring(0, 8).toUpperCase()),
          if (order.razorpayOrderId != null)
            _buildInfoRow('Razorpay Order', order.razorpayOrderId!),
          if (order.razorpayPaymentId != null)
            _buildInfoRow('Payment ID', order.razorpayPaymentId!),
          if (order.paidAt != null)
            _buildInfoRow('Paid At', _formatDateTime(order.paidAt!), isLast: true),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(AdminOrder order) {
    return GestureDetector(
      onTap: order.userId != null
          ? () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetailsScreen(userId: order.userId!),
                ),
              );
            }
          : null,
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Center(
                child: Text(
                  (order.customerName ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
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
                    order.customerName ?? 'Unknown Customer',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (order.customerPhone != null)
                    Text(
                      order.customerPhone!,
                      style: AppTypography.bodySmall,
                    ),
                ],
              ),
            ),
            if (order.userId != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.silver,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(List<OrderItem> items) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.titleSmall,
                        ),
                        Text(
                          'x${item.quantity} @ \u20B9${item.price.toStringAsFixed(2)}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\u20B9${item.subtotal.toStringAsFixed(2)}',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: AppSpacing.sm),
                Divider(color: AppColors.mist.withOpacity(0.5), height: 1),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExitCard(ExitInfo exit) {
    final exitStatusColor = exit.verified
        ? (exit.allowed == true ? AppColors.accent : AppColors.error)
        : (exit.isExpired ? AppColors.error : AppColors.warning);
    final exitStatusBgColor = exit.verified
        ? (exit.allowed == true ? AppColors.accentLight : AppColors.errorLight)
        : (exit.isExpired ? AppColors.errorLight : AppColors.warningLight);

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: AppTypography.bodySmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: exitStatusBgColor,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  exit.statusText,
                  style: AppTypography.labelSmall.copyWith(
                    color: exitStatusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow('Token', exit.token.substring(0, 8).toUpperCase()),
          _buildInfoRow('Expires', _formatDateTime(exit.expiresAt)),
          if (exit.verifiedAt != null)
            _buildInfoRow('Verified At', _formatDateTime(exit.verifiedAt!), isLast: true),
        ],
      ),
    );
  }

  Widget _buildRefundCard(AdminOrder order) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _buildInfoRow('Refund ID', order.refundId ?? 'N/A'),
          _buildInfoRow(
            'Amount',
            '\u20B9${order.refundAmount?.toStringAsFixed(2) ?? '0.00'}',
          ),
          if (order.refundedAt != null)
            _buildInfoRow('Refunded At', _formatDateTime(order.refundedAt!)),
          if (order.refundReason != null)
            _buildInfoRow('Reason', order.refundReason!, isLast: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall,
            ),
            Flexible(
              child: Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: AppSpacing.xs),
          Divider(color: AppColors.mist.withOpacity(0.5), height: 1),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Widget _buildActionsSection(AdminOrder order, bool isProcessing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Actions'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (order.canRefund)
              Expanded(
                child: _buildActionButton(
                  label: 'Refund',
                  icon: Icons.replay_rounded,
                  color: AppColors.security,
                  isLoading: isProcessing,
                  onTap: () => _showRefundSheet(order),
                ),
              ),
            if (order.canRefund && order.canCancel)
              const SizedBox(width: AppSpacing.sm),
            if (order.canCancel)
              Expanded(
                child: _buildActionButton(
                  label: 'Cancel',
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  isLoading: isProcessing,
                  onTap: () => _showCancelDialog(order),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: AppSpacing.cardSm,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRefundSheet(AdminOrder order) {
    final amountController = TextEditingController(
      text: order.totalAmount.toStringAsFixed(2),
    );
    final reasonController = TextEditingController();
    bool isFullRefund = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          decoration: const BoxDecoration(
            color: AppColors.pure,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
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
                'Process Refund',
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Refund will be processed via Razorpay',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Refund Type
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          isFullRefund = true;
                          amountController.text = order.totalAmount.toStringAsFixed(2);
                        });
                      },
                      child: Container(
                        padding: AppSpacing.cardSm,
                        decoration: BoxDecoration(
                          color: isFullRefund ? AppColors.securityLight : AppColors.cloud,
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(
                            color: isFullRefund ? AppColors.security : AppColors.mist,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: isFullRefund ? AppColors.security : AppColors.steel,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Full Refund',
                              style: AppTypography.labelMedium.copyWith(
                                color: isFullRefund ? AppColors.security : AppColors.steel,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          isFullRefund = false;
                        });
                      },
                      child: Container(
                        padding: AppSpacing.cardSm,
                        decoration: BoxDecoration(
                          color: !isFullRefund ? AppColors.securityLight : AppColors.cloud,
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(
                            color: !isFullRefund ? AppColors.security : AppColors.mist,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: !isFullRefund ? AppColors.security : AppColors.steel,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Partial Refund',
                              style: AppTypography.labelMedium.copyWith(
                                color: !isFullRefund ? AppColors.security : AppColors.steel,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Amount field
              if (!isFullRefund) ...[
                Text(
                  'Refund Amount',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '\u20B9 ',
                    hintText: 'Enter amount',
                    filled: true,
                    fillColor: AppColors.cloud,
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Reason field
              Text(
                'Reason (Optional)',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter refund reason',
                  filled: true,
                  fillColor: AppColors.cloud,
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0 || amount > order.totalAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid refund amount'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    final success = await ref.read(ordersAdminProvider.notifier).refundOrder(
                      orderId: order.id,
                      amount: isFullRefund ? null : amount,
                      reason: reasonController.text.isEmpty ? null : reasonController.text,
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Refund processed successfully'),
                          backgroundColor: AppColors.accent,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.security,
                    foregroundColor: AppColors.pure,
                    padding: AppSpacing.buttonPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusLg,
                    ),
                  ),
                  child: Text(
                    'Process Refund',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(AdminOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        title: Text(
          'Cancel Order',
          style: AppTypography.headlineMedium,
        ),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Order',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.steel,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(ordersAdminProvider.notifier).cancelOrder(
                orderId: order.id,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order cancelled'),
                    backgroundColor: AppColors.accent,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.pure,
            ),
            child: Text('Cancel Order'),
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
                  .read(ordersAdminProvider.notifier)
                  .fetchOrderDetails(widget.orderId),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'refunded':
        return Icons.replay_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'created':
        return Icons.pending_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  String _formatStatus(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
