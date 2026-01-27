import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import '../../services/socket_service.dart';
import 'scanner_screen.dart';

class SecurityHomeScreen extends ConsumerStatefulWidget {
  const SecurityHomeScreen({super.key});

  @override
  ConsumerState<SecurityHomeScreen> createState() => _SecurityHomeScreenState();
}

class _SecurityHomeScreenState extends ConsumerState<SecurityHomeScreen>
    with SingleTickerProviderStateMixin {
  String? lastScanResult;
  bool? isAllowed;
  String? customerName;
  double? amount;

  // Stats
  int todayScans = 0;
  int approved = 0;
  int denied = 0;

  // Pending exit requests from socket
  List<Map<String, dynamic>> pendingExits = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  StreamSubscription? _exitRequestSubscription;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    // Listen for realtime exit requests
    _listenToExitRequests();
  }

  void _listenToExitRequests() {
    _exitRequestSubscription =
        SocketService.instance.exitRequests.listen((data) {
      if (mounted) {
        setState(() {
          pendingExits.insert(0, data);
          // Keep only last 5
          if (pendingExits.length > 5) {
            pendingExits.removeLast();
          }
        });
        // Show notification
        _showExitRequestNotification(data);
      }
    });
  }

  void _showExitRequestNotification(Map<String, dynamic> data) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.person_outline, color: AppColors.pure, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Exit request from ${data['user']?['name'] ?? 'Customer'}',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.security,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        action: SnackBarAction(
          label: 'SCAN',
          textColor: AppColors.pure,
          onPressed: openScanner,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _exitRequestSubscription?.cancel();
    super.dispose();
  }

  Future<void> openScanner() async {
    HapticFeedback.mediumImpact();

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ScannerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        lastScanResult = result["message"];
        isAllowed = result["allowed"];
        customerName = result["customerName"];
        amount = result["amount"]?.toDouble();
        todayScans++;
        if (isAllowed == true) {
          approved++;
        } else {
          denied++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isConnected = SocketService.instance.isConnected;

    return Theme(
      data: AppTheme.dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.voidBlack,
          body: SafeArea(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: child,
                );
              },
              child: Padding(
                padding: AppSpacing.screenAll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(authState, isConnected),

                    const SizedBox(height: AppSpacing.xxl),

                    // Shield icon with glow
                    _buildShieldIcon(),

                    const SizedBox(height: AppSpacing.xxl),

                    // Scan button
                    _buildScanButton(),

                    const SizedBox(height: AppSpacing.xxl),

                    // Stats row
                    _buildStatsRow(),

                    const SizedBox(height: AppSpacing.xl),

                    // Last scan result
                    if (lastScanResult != null) ...[
                      Text(
                        'Last Scan',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.silver,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildLastScanCard(),
                    ],

                    const Spacer(),

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthState authState, bool isConnected) {
    return Row(
      children: [
        // Logout button
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            await ref.read(authProvider.notifier).logout();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.carbon,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: const Center(
              child: Icon(
                Icons.logout_rounded,
                color: AppColors.pure,
                size: 18,
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
                'Security Gate',
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pure,
                ),
              ),
              Text(
                'Hi, ${authState.userName ?? 'Security'}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.silver,
                ),
              ),
            ],
          ),
        ),
        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: (isConnected ? AppColors.accent : AppColors.error)
                .withOpacity(0.15),
            borderRadius: AppSpacing.borderRadiusFull,
            border: Border.all(
              color: (isConnected ? AppColors.accent : AppColors.error)
                  .withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.accent : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'Online' : 'Offline',
                style: AppTypography.labelSmall.copyWith(
                  color: isConnected ? AppColors.accent : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShieldIcon() {
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.security.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.security.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.security.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.shield_outlined,
                size: 48,
                color: AppColors.security,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: openScanner,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.security,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.security.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.pure,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Scan Exit QR',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.pure,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem(
          'Today',
          todayScans.toString(),
          Icons.qr_code_rounded,
          AppColors.pure,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildStatItem(
          'Approved',
          approved.toString(),
          Icons.check_circle_outline_rounded,
          AppColors.accent,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildStatItem(
          'Denied',
          denied.toString(),
          Icons.cancel_outlined,
          AppColors.error,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: AppSpacing.cardSm,
        decoration: BoxDecoration(
          color: AppColors.carbon,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.pure,
              ),
            ),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.silver,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastScanCard() {
    final bool allowed = isAllowed == true;

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: allowed ? AppColors.accent : AppColors.error,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (allowed ? AppColors.accent : AppColors.error)
                  .withOpacity(0.15),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Center(
              child: Icon(
                allowed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: allowed ? AppColors.accent : AppColors.error,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allowed ? 'Exit Approved' : 'Exit Denied',
                  style: AppTypography.titleSmall.copyWith(
                    color: allowed ? AppColors.accent : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (customerName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    customerName!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.pure,
                    ),
                  ),
                ],
                if (amount != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '\u20B9${amount!.toStringAsFixed(0)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.silver,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Time
          Text(
            'Just now',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.steel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'SmartExit Security v2.0',
        style: AppTypography.caption.copyWith(
          color: AppColors.steel,
        ),
      ),
    );
  }
}
