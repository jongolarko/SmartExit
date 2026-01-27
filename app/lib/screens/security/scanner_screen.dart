import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/core.dart';
import '../../services/api_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  bool scanning = true;
  bool showResult = false;
  bool? isAllowed;
  Map<String, dynamic>? verificationResult;

  late AnimationController _resultAnimController;
  late Animation<double> _resultScaleAnimation;
  late Animation<double> _resultOpacityAnimation;

  Timer? _autoReturnTimer;
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _resultScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _resultAnimController,
        curve: Curves.elasticOut,
      ),
    );

    _resultOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _resultAnimController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _resultAnimController.dispose();
    _autoReturnTimer?.cancel();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!scanning) return;

    final String? token = capture.barcodes.first.rawValue;
    if (token == null || token.isEmpty) return;

    setState(() => scanning = false);
    HapticFeedback.mediumImpact();

    final res = await ApiService.verifyExitQR(exitToken: token);

    if (!mounted) return;

    _showResult(res);
  }

  void _showResult(Map<String, dynamic>? res) {
    final bool allowed = res?["valid"] == true;

    setState(() {
      showResult = true;
      isAllowed = allowed;
      verificationResult = res;
    });

    // Trigger haptic and animation
    if (allowed) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    _resultAnimController.forward();

    // Start auto-return countdown
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 5;
    _autoReturnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        _resetScanner();
      }
    });
  }

  void _resetScanner() {
    _autoReturnTimer?.cancel();
    _resultAnimController.reset();
    setState(() {
      showResult = false;
      scanning = true;
      verificationResult = null;
      isAllowed = null;
    });
  }

  void _returnWithResult() {
    _autoReturnTimer?.cancel();

    Navigator.pop(context, {
      "allowed": isAllowed,
      "message": isAllowed == true ? "Exit Approved" : "Exit Denied",
      "customerName": verificationResult?["user"]?["name"],
      "amount": verificationResult?["order"]?["amount"],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.voidBlack,
          body: Stack(
            children: [
              // Camera
              if (!showResult)
                MobileScanner(
                  controller: MobileScannerController(
                    detectionSpeed: DetectionSpeed.noDuplicates,
                    facing: CameraFacing.back,
                  ),
                  onDetect: _onDetect,
                ),

              // Scanner overlay
              if (!showResult)
                const ScannerOverlay(
                  scanAreaSize: 280,
                  borderColor: AppColors.security,
                ),

              // Header (when scanning)
              if (!showResult)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildHeader(),
                ),

              // Full-screen result
              if (showResult) _buildResultScreen(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
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
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Scan Exit QR',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Point at customer\'s QR code',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final bool allowed = isAllowed == true;
    final Color accentColor = allowed ? AppColors.accent : AppColors.error;

    return AnimatedBuilder(
      animation: _resultAnimController,
      builder: (context, child) {
        return Container(
          color: allowed
              ? AppColors.accent.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          child: SafeArea(
            child: Opacity(
              opacity: _resultOpacityAnimation.value,
              child: Transform.scale(
                scale: _resultScaleAnimation.value,
                child: Padding(
                  padding: AppSpacing.screenAll,
                  child: Column(
                    children: [
                      // Header with countdown
                      _buildResultHeader(accentColor),

                      const Spacer(),

                      // Result icon
                      _buildResultIcon(allowed, accentColor),

                      const SizedBox(height: AppSpacing.xxl),

                      // Result text
                      Text(
                        allowed ? 'EXIT APPROVED' : 'ACCESS DENIED',
                        style: GoogleFonts.dmSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Customer details or error message
                      if (allowed)
                        _buildCustomerDetails()
                      else
                        _buildDeniedMessage(),

                      const Spacer(),

                      // Action buttons
                      _buildActionButtons(accentColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultHeader(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Result title
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification Result',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.pure,
              ),
            ),
            Text(
              'Auto-return in $_countdown seconds',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.silver,
              ),
            ),
          ],
        ),
        // Countdown circle
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.carbon,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$_countdown',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.pure,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultIcon(bool allowed, Color accentColor) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: allowed
                ? AnimatedCheck(
                    size: 60,
                    color: accentColor,
                  )
                : AnimatedX(
                    size: 60,
                    color: accentColor,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDetails() {
    final user = verificationResult?["user"];
    final order = verificationResult?["order"];

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Customer',
            user?["name"] ?? "Unknown",
            Icons.person_outline_rounded,
          ),
          const Divider(color: AppColors.graphite, height: 24),
          _buildDetailRow(
            'Phone',
            user?["phone"] ?? "N/A",
            Icons.phone_outlined,
          ),
          const Divider(color: AppColors.graphite, height: 24),
          _buildDetailRow(
            'Amount',
            '\u20B9${order?["amount"]?.toStringAsFixed(0) ?? "0"}',
            Icons.receipt_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.graphite,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Center(
            child: Icon(icon, color: AppColors.silver, size: 20),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.silver,
                ),
              ),
              Text(
                value,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.pure,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeniedMessage() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: const Center(
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
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
                  'Invalid or Expired QR',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Payment not verified. Customer cannot exit.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.silver,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color accentColor) {
    return Column(
      children: [
        // Primary action
        GestureDetector(
          onTap: _returnWithResult,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAllowed == true ? Icons.check_rounded : Icons.close_rounded,
                  color: AppColors.pure,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isAllowed == true ? 'Allow Exit' : 'Done',
                  style: AppTypography.button,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Scan again button
        GestureDetector(
          onTap: _resetScanner,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: AppColors.graphite,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.pure,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Scan Another',
                  style: AppTypography.button.copyWith(
                    color: AppColors.pure,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
