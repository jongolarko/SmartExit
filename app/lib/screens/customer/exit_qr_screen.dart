import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';

class ExitQRScreen extends ConsumerStatefulWidget {
  final String orderId;
  final double totalAmount;

  const ExitQRScreen({
    super.key,
    required this.orderId,
    this.totalAmount = 0,
  });

  @override
  ConsumerState<ExitQRScreen> createState() => _ExitQRScreenState();
}

class _ExitQRScreenState extends ConsumerState<ExitQRScreen>
    with TickerProviderStateMixin {
  String? exitToken;
  bool loading = true;
  String? error;
  bool isDarkMode = false;

  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  // Timer for QR validity (5 minutes)
  static const Duration qrValidity = Duration(minutes: 5);
  DateTime? qrGeneratedAt;

  @override
  void initState() {
    super.initState();

    // Entrance animations
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Pulse animation for the glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    generateQR();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> generateQR() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService.generateExitQR(orderId: widget.orderId);

      if (res['success'] == true) {
        setState(() {
          exitToken = res['exit_token'];
          qrGeneratedAt = DateTime.now();
          loading = false;
        });
        _entranceController.forward();
        HapticFeedback.heavyImpact();
      } else {
        setState(() {
          error = res['error'] ?? "Failed to generate exit QR";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Server unreachable";
        loading = false;
      });
    }
  }

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => isDarkMode = !isDarkMode);
  }

  void _navigateHome() {
    HapticFeedback.lightImpact();
    // Clear cart and navigate to customer home
    ref.read(cartProvider.notifier).clearCart();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? AppColors.voidBlack : AppColors.pure;
    final textColor = isDarkMode ? AppColors.pure : AppColors.voidBlack;
    final subtextColor = isDarkMode ? AppColors.silver : AppColors.steel;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: loading
              ? _buildLoadingState(textColor)
              : error != null
                  ? _buildErrorState(textColor)
                  : _buildQRContent(textColor, subtextColor),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Generating your exit QR...',
            style: AppTypography.bodyLarge.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color textColor) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Something went wrong',
              style: AppTypography.headlineSmall.copyWith(color: textColor),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.steel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              text: 'Try Again',
              onPressed: generateQR,
              icon: Icons.refresh_rounded,
              width: 180,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRContent(Color textColor, Color subtextColor) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _pulseController]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Padding(
            padding: AppSpacing.screenAll,
            child: Column(
              children: [
                // Header
                _buildHeader(textColor, subtextColor),

                const Spacer(),

                // QR Code with glow
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildQRContainer(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Amount badge
                _buildAmountBadge(textColor),

                const SizedBox(height: AppSpacing.md),

                // Timer
                if (qrGeneratedAt != null)
                  CountdownTimer(
                    duration: qrValidity,
                    onComplete: () {
                      // QR expired - could regenerate or show message
                    },
                  ),

                const Spacer(),

                // Instructions
                _buildInstructions(subtextColor),

                const SizedBox(height: AppSpacing.xl),

                // Done button
                SecondaryButton(
                  text: 'Done',
                  onPressed: _navigateHome,
                  textColor: textColor,
                  borderColor: isDarkMode ? AppColors.graphite : AppColors.mist,
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color textColor, Color subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exit Pass',
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            Text(
              'Show this QR at the exit gate',
              style: AppTypography.bodyMedium.copyWith(color: subtextColor),
            ),
          ],
        ),
        // Theme toggle
        GestureDetector(
          onTap: _toggleTheme,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.graphite : AppColors.cloud,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Center(
              child: Icon(
                isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDarkMode ? AppColors.pure : AppColors.voidBlack,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent
                .withOpacity(0.25 * _glowAnimation.value * _pulseAnimation.value),
            blurRadius: 40 * _pulseAnimation.value,
            spreadRadius: 8 * _pulseAnimation.value,
          ),
          BoxShadow(
            color: AppColors.accent
                .withOpacity(0.15 * _glowAnimation.value * _pulseAnimation.value),
            blurRadius: 80 * _pulseAnimation.value,
            spreadRadius: 16 * _pulseAnimation.value,
          ),
        ],
      ),
      child: PremiumQR(
        data: exitToken!,
        size: 280,
        showGlow: false,
        isDark: isDarkMode,
      ),
    );
  }

  Widget _buildAmountBadge(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Paid badge
        const VerifiedBadge(text: 'PAID'),
        const SizedBox(width: AppSpacing.md),
        // Amount
        Text(
          '\u20B9${widget.totalAmount.toStringAsFixed(0)}',
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(Color subtextColor) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.carbon
            : AppColors.cloud,
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: const Center(
              child: Icon(
                Icons.info_outline_rounded,
                color: AppColors.accent,
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
                  'One-time use only',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDarkMode ? AppColors.pure : AppColors.voidBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This QR becomes invalid after security scan',
                  style: AppTypography.bodySmall.copyWith(
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
