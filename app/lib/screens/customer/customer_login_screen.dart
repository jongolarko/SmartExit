import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';

class CustomerLoginScreen extends ConsumerStatefulWidget {
  final String? roleHint; // 'customer', 'security', 'admin'

  const CustomerLoginScreen({super.key, this.roleHint});

  @override
  ConsumerState<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends ConsumerState<CustomerLoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController otpCtrl = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();

  bool isNewUser = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    phoneCtrl.dispose();
    nameCtrl.dispose();
    otpCtrl.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (phoneCtrl.text.trim().isEmpty) {
      _showError("Please enter your phone number");
      return;
    }

    if (phoneCtrl.text.trim().length < 10) {
      _showError("Please enter a valid phone number");
      return;
    }

    HapticFeedback.lightImpact();
    final auth = ref.read(authProvider.notifier);

    bool success;
    if (isNewUser && nameCtrl.text.trim().isNotEmpty) {
      success = await auth.register(phoneCtrl.text.trim(), nameCtrl.text.trim());
    } else {
      success = await auth.sendOtp(phoneCtrl.text.trim());
    }

    if (success) {
      _otpFocus.requestFocus();
      _showSuccess("OTP sent to your phone");
    }
  }

  Future<void> _verifyOtp() async {
    if (otpCtrl.text.trim().length != 6) {
      _showError("Please enter a valid 6-digit OTP");
      return;
    }

    HapticFeedback.lightImpact();
    final auth = ref.read(authProvider.notifier);

    final success = await auth.verifyOtp(otpCtrl.text.trim());

    if (success) {
      HapticFeedback.mediumImpact();
      // Navigate back to root - AuthWrapper will handle the rest
      Navigator.of(context).popUntil((route) => route.isFirst);
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.pure, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.customer,
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
    final authState = ref.watch(authProvider);

    // Listen for errors
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        _showError(next.error!);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.pure,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: _slideAnimation.value,
                child: child,
              ),
            );
          },
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: AppSpacing.screenAll,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      _buildBackButton(authState),

                      const Spacer(flex: 1),

                      // Logo and branding
                      _buildHeader(authState),

                      const SizedBox(height: AppSpacing.xxxl),

                      // Form fields
                      if (authState.otpSent)
                        _buildOtpInput()
                      else
                        _buildPhoneInput(),

                      const SizedBox(height: AppSpacing.xl),

                      // Action button
                      _buildActionButton(authState),

                      const Spacer(flex: 2),

                      // Footer
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(AuthState authState) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (authState.otpSent) {
          ref.read(authProvider.notifier).resetOtpState();
          otpCtrl.clear();
        } else {
          Navigator.pop(context);
        }
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
    );
  }

  Widget _buildHeader(AuthState authState) {
    String title;
    String subtitle;

    if (authState.otpSent) {
      title = 'Verify OTP';
      subtitle = 'Enter the 6-digit code sent to ${authState.pendingPhone}';
    } else if (isNewUser) {
      title = 'Create Account';
      subtitle = 'Enter your details to get started';
    } else {
      title = 'Welcome back';
      subtitle = 'Enter your phone number to continue';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _getRoleColor(),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.md,
          ),
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/logo/smartexit_logo.png',
            color: AppColors.pure,
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Title
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.voidBlack,
            height: 1.1,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Subtitle
        Text(
          subtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.steel,
          ),
        ),
      ],
    );
  }

  Color _getRoleColor() {
    switch (widget.roleHint) {
      case 'security':
        return AppColors.security;
      case 'admin':
        return AppColors.admin;
      default:
        return AppColors.voidBlack;
    }
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNewUser) ...[
          Text(
            'Full Name',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.steel,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          PremiumTextField(
            controller: nameCtrl,
            focusNode: _nameFocus,
            label: 'Enter your name',
            autofocus: true,
            onSubmitted: (_) => _phoneFocus.requestFocus(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Phone Number',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        PhoneTextField(
          controller: phoneCtrl,
          focusNode: _phoneFocus,
          label: 'Enter your number',
          countryCode: '+91',
          autofocus: !isNewUser,
          onSubmitted: (_) => _sendOtp(),
        ),
        const SizedBox(height: AppSpacing.md),
        // Toggle new user
        GestureDetector(
          onTap: () {
            setState(() {
              isNewUser = !isNewUser;
            });
            if (isNewUser) {
              _nameFocus.requestFocus();
            }
          },
          child: Text(
            isNewUser ? 'Already have an account? Login' : "Don't have an account? Register",
            style: AppTypography.bodySmall.copyWith(
              color: _getRoleColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Code',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        PremiumTextField(
          controller: otpCtrl,
          focusNode: _otpFocus,
          label: 'Enter 6-digit OTP',
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onSubmitted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: AppSpacing.md),
        // Resend OTP
        GestureDetector(
          onTap: _sendOtp,
          child: Text(
            "Didn't receive OTP? Resend",
            style: AppTypography.bodySmall.copyWith(
              color: _getRoleColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(AuthState authState) {
    return PrimaryButton(
      text: authState.otpSent ? 'Verify OTP' : 'Send OTP',
      onPressed: authState.otpSent ? _verifyOtp : _sendOtp,
      isLoading: authState.isLoading,
      icon: authState.otpSent ? Icons.check_rounded : Icons.arrow_forward_rounded,
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'By continuing, you agree to our',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Terms of Service',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.voidBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                ' and ',
                style: AppTypography.bodySmall,
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Privacy Policy',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.voidBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
