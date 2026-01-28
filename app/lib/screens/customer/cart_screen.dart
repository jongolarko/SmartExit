import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../services/storage_service.dart';
import 'exit_qr_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with SingleTickerProviderStateMixin {
  bool checkingOut = false;

  late AnimationController _animController;

  // Payment-related state
  final PaymentService _paymentService = PaymentService.instance;
  String? _pendingOrderId;
  String? _pendingRazorpayOrderId;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Initialize payment service with callbacks
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );

    // Fetch cart on init
    Future.microtask(() {
      ref.read(cartProvider.notifier).fetchCart();
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> checkout() async {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) return;

    setState(() => checkingOut = true);
    HapticFeedback.mediumImpact();

    // Step 1: Create payment order on backend
    final payment = await ApiService.createPaymentOrder();

    if (payment['success'] == true && mounted) {
      // Store order details for use in payment callbacks
      _pendingOrderId = payment['order_id'];
      _pendingRazorpayOrderId = payment['razorpay_order_id'];

      // Get user details for prefilling checkout
      final user = await StorageService.getUser();

      // Step 2: Open Razorpay checkout UI
      _paymentService.openCheckout(
        razorpayKey: payment['key'] ?? '',
        amountInPaise: ((payment['amount'] ?? 0) as num).toInt(),
        razorpayOrderId: payment['razorpay_order_id'] ?? '',
        businessName: 'SmartExit',
        description: 'Store Purchase',
        userPhone: user['phone'],
        userName: user['name'],
      );
    } else {
      setState(() => checkingOut = false);
      _showError(payment['error'] ?? "Failed to create order. Please try again.");
    }
  }

  /// Handle successful payment from Razorpay
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    HapticFeedback.heavyImpact();

    // Step 3: Verify payment with backend
    final verification = await ApiService.verifyPayment(
      razorpayOrderId: response.orderId ?? _pendingRazorpayOrderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
      orderId: _pendingOrderId ?? '',
    );

    if (verification['success'] == true && mounted) {
      final cartState = ref.read(cartProvider);

      // Step 4: Navigate to Exit QR screen
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ExitQRScreen(
            orderId: _pendingOrderId!,
            totalAmount: cartState.total,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      setState(() => checkingOut = false);
      _showError(verification['error'] ?? "Payment verification failed.");
    }

    // Clear pending order data
    _pendingOrderId = null;
    _pendingRazorpayOrderId = null;
  }

  /// Handle payment failure from Razorpay
  void _handlePaymentFailure(PaymentFailureResponse response) {
    if (!mounted) return;

    setState(() => checkingOut = false);
    HapticFeedback.heavyImpact();

    String errorMessage = "Payment failed";
    if (response.message != null && response.message!.isNotEmpty) {
      errorMessage = response.message!;
    } else if (response.code != null) {
      // Map common Razorpay error codes to user-friendly messages
      switch (response.code) {
        case Razorpay.NETWORK_ERROR:
          errorMessage = "Network error. Please check your connection.";
          break;
        case Razorpay.INVALID_OPTIONS:
          errorMessage = "Invalid payment configuration.";
          break;
        case Razorpay.PAYMENT_CANCELLED:
          errorMessage = "Payment cancelled.";
          break;
        default:
          errorMessage = "Payment failed. Please try again.";
      }
    }

    _showError(errorMessage);

    // Clear pending order data
    _pendingOrderId = null;
    _pendingRazorpayOrderId = null;
  }

  /// Handle external wallet selection (e.g., PayTM, PhonePe)
  void _handleExternalWallet(ExternalWalletResponse response) {
    // External wallet selected - payment will continue in the wallet app
    // The success/failure will be handled by the respective callbacks
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirecting to ${response.walletName}...'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
    );
  }

  Future<void> _clearCart() async {
    HapticFeedback.mediumImpact();
    final success = await ref.read(cartProvider.notifier).clearCart();
    if (!success) {
      final cartState = ref.read(cartProvider);
      _showError(cartState.error ?? "Failed to clear cart");
      ref.read(cartProvider.notifier).clearError();
    }
  }

  Future<void> _removeItem(String itemId) async {
    HapticFeedback.mediumImpact();
    final success = await ref.read(cartProvider.notifier).removeItem(itemId);
    if (!success) {
      final cartState = ref.read(cartProvider);
      _showError(cartState.error ?? "Failed to remove item");
      ref.read(cartProvider.notifier).clearError();
    }
  }

  Future<void> _updateQuantity(String itemId, int quantity) async {
    if (quantity < 1) {
      _removeItem(itemId);
      return;
    }

    final success = await ref.read(cartProvider.notifier).updateQuantity(itemId, quantity);
    if (!success) {
      final cartState = ref.read(cartProvider);
      _showError(cartState.error ?? "Failed to update quantity");
      ref.read(cartProvider.notifier).clearError();
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.pure, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final loading = cartState.isLoading;
    final items = cartState.items;
    final total = cartState.total;

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(loading, items),

            // Content
            Expanded(
              child: loading && items.isEmpty
                  ? _buildLoadingState()
                  : items.isEmpty
                      ? _buildEmptyState()
                      : _buildCartList(items),
            ),

            // Bottom checkout panel
            if (!loading && items.isNotEmpty) _buildCheckoutPanel(total),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool loading, List<CartItem> items) {
    return Container(
      color: AppColors.pure,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
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
          const SizedBox(width: AppSpacing.md),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Cart',
                  style: AppTypography.headlineSmall,
                ),
                if (!loading && items.isNotEmpty)
                  Text(
                    '${items.length} item${items.length > 1 ? 's' : ''}',
                    style: AppTypography.bodySmall,
                  ),
              ],
            ),
          ),

          // Clear cart button
          if (!loading && items.isNotEmpty)
            GestureDetector(
              onTap: _clearCart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  'Clear',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.steel,
                  ),
                ),
              ),
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
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Shimmer.fromColors(
              baseColor: AppColors.mist,
              highlightColor: AppColors.pure,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.pure,
                  borderRadius: AppSpacing.borderRadiusXl,
                ),
              ),
            ),
          ),
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
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.cloud,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 56,
                  color: AppColors.silver,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Your cart is empty',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Scan products to add them to your cart',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.steel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SecondaryButton(
              text: 'Continue Scanning',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: () => Navigator.pop(context),
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(List<CartItem> items) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return ListView.builder(
          padding: AppSpacing.screenAll,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final delay = index * 0.1;
            final animation = CurvedAnimation(
              parent: _animController,
              curve: Interval(
                delay.clamp(0.0, 0.7),
                (delay + 0.3).clamp(0.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
            );

            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - animation.value)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Dismissible(
                    key: Key(item.itemId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: AppSpacing.borderRadiusXl,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.pure,
                        size: 28,
                      ),
                    ),
                    onDismissed: (direction) {
                      _removeItem(item.itemId);
                    },
                    child: _buildCartItem(item),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          // Product image placeholder
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.pearl,
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
                          Icons.shopping_bag_outlined,
                          color: AppColors.silver,
                          size: 32,
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.silver,
                      size: 32,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\u20B9${item.unitPrice.toStringAsFixed(0)} each',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),

          // Quantity and total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\u20B9${item.totalPrice.toStringAsFixed(0)}',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.voidBlack,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _updateQuantity(item.itemId, item.quantity - 1),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: AppColors.steel,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.voidBlack,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _updateQuantity(item.itemId, item.quantity + 1),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: AppColors.voidBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutPanel(double total) {
    return Container(
      padding: AppSpacing.screenAll,
      decoration: BoxDecoration(
        color: AppColors.pure,
        boxShadow: AppShadows.bottomSheet,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\u20B9${total.toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.voidBlack,
                    ),
                  ),
                ],
              ),
              // Tax info
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
                  'Incl. taxes',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Checkout button
          PrimaryButton(
            text: 'Pay & Get Exit QR',
            onPressed: checkout,
            isLoading: checkingOut,
            backgroundColor: AppColors.accent,
            icon: Icons.qr_code_rounded,
          ),
        ],
      ),
    );
  }
}
