import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartexit_core/smartexit_core.dart';
import 'package:smartexit_shared/smartexit_shared.dart';
import '../../config/premium_theme.dart';

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

    // Validate name for new users
    if (isNewUser && nameCtrl.text.trim().isEmpty) {
      _showError("Please enter your name");
      return;
    }

    HapticFeedback.lightImpact();
    final auth = ref.read(authProvider.notifier);

    bool success;
    if (isNewUser) {
      success = await auth.register(phoneCtrl.text.trim(), nameCtrl.text.trim());
    } else {
      success = await auth.sendOtp(phoneCtrl.text.trim());
    }

    if (!mounted) return;

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

    // Pass the expected role for validation (default to 'customer' if no roleHint)
    final expectedRole = widget.roleHint ?? 'customer';
    final success = await auth.verifyOtp(otpCtrl.text.trim(), expectedRole: expectedRole);

    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      // Navigate back to root - AuthWrapper will handle the rest
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: PremiumColors.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: PremiumColors.accent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
      body: Stack(
        children: [
          // Background image layer (if image exists)
          Positioned.fill(
            child: _buildBackground(),
          ),

          // Content layer with SafeArea
          SafeArea(
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
                          // Back button - removed as login screen shouldn't have back navigation
                          // _buildBackButton(authState),

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
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF), // Pure white
            Color(0xFFF0FFF4), // Mint tint
            Color(0xFFFFFFFF), // Pure white
            Color(0xFFD1FAE5), // Light mint
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
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
          color: PremiumColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: PremiumShadows.sm,
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: PremiumColors.textPrimary,
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
      title = 'Welcome';
      subtitle = 'Enter your phone number to continue';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo with emerald green gradient
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF10B981), // Light emerald
                Color(0xFF059669), // Emerald green
                Color(0xFF047857), // Deep emerald
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              // Emerald glow
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              // Light green shimmer
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              // Soft outer glow
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.2),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/images/SmartExit_Logo.png',
            fit: BoxFit.contain,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 32),

        // Title with emerald gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF047857), // Deep emerald
              Color(0xFF059669), // Emerald
              Color(0xFF10B981), // Light emerald
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              shadows: [
                Shadow(
                  color: const Color(0xFF059669).withOpacity(0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280), // Medium gray
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNewUser) ...[
          Text(
            'Full Name',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937), // Dark gray
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF059669), // Emerald border
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PremiumTextField(
              controller: nameCtrl,
              focusNode: _nameFocus,
              label: 'Enter your name',
              autofocus: true,
              onSubmitted: (_) => _phoneFocus.requestFocus(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Phone Number',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937), // Dark gray
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF059669), // Emerald border
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PhoneTextField(
            controller: phoneCtrl,
            focusNode: _phoneFocus,
            label: 'Enter your number',
            countryCode: '+91',
            autofocus: !isNewUser,
            onSubmitted: (_) => _sendOtp(),
          ),
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
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: Color(0xFF059669), // Emerald green
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
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
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937), // Dark gray
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF059669), // Emerald border
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PremiumTextField(
            controller: otpCtrl,
            focusNode: _otpFocus,
            label: 'Enter 6-digit OTP',
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onSubmitted: (_) => _verifyOtp(),
          ),
        ),
        const SizedBox(height: 16),
        // Resend OTP
        GestureDetector(
          onTap: _sendOtp,
          child: Text(
            "Didn't receive OTP? Resend",
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: Color(0xFF059669), // Emerald green
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(AuthState authState) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981), // Light emerald
            Color(0xFF059669), // Emerald green
            Color(0xFF047857), // Deep emerald
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Emerald glow
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          // Light green shimmer
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          // Soft outer glow
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: PrimaryButton(
        text: authState.otpSent ? 'Verify OTP' : 'Send OTP',
        onPressed: authState.otpSent ? _verifyOtp : _sendOtp,
        isLoading: authState.isLoading,
        icon: authState.otpSent ? Icons.check_rounded : Icons.arrow_forward_rounded,
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'By continuing, you agree to our',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              color: Color(0xFF4A4A4A),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Terms of Service',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: Color(0xFF059669), // Emerald green
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                ' and ',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Privacy Policy',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: Color(0xFF059669), // Emerald green
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
