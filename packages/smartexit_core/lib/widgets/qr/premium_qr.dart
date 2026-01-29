import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_shadows.dart';

/// Premium QR code with glow effect and double border
class PremiumQR extends StatelessWidget {
  final String data;
  final double size;
  final bool showGlow;
  final Color glowColor;
  final bool isDark;

  const PremiumQR({
    super.key,
    required this.data,
    this.size = 280,
    this.showGlow = true,
    this.glowColor = AppColors.accent,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: glowColor.withOpacity(0.15),
                  blurRadius: 80,
                  spreadRadius: 16,
                ),
              ]
            : AppShadows.lg,
        border: Border.all(
          color: isDark ? AppColors.graphite : AppColors.mist,
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: AppColors.pearl,
            width: 2,
          ),
        ),
        child: PrettyQrView.data(
          data: data,
          decoration: PrettyQrDecoration(
            shape: PrettyQrSmoothSymbol(
              color: AppColors.voidBlack,
              roundFactor: 1,
            ),
            image: const PrettyQrDecorationImage(
              image: AssetImage('assets/logo/smartexit_logo.png'),
              position: PrettyQrDecorationImagePosition.embedded,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated QR container with entrance animation
class AnimatedQRContainer extends StatefulWidget {
  final String data;
  final double size;
  final bool showGlow;
  final Color glowColor;
  final Widget? badge;

  const AnimatedQRContainer({
    super.key,
    required this.data,
    this.size = 280,
    this.showGlow = true,
    this.glowColor = AppColors.accent,
    this.badge,
  });

  @override
  State<AnimatedQRContainer> createState() => _AnimatedQRContainerState();
}

class _AnimatedQRContainerState extends State<AnimatedQRContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.pure,
                borderRadius: AppSpacing.borderRadiusXl,
                boxShadow: widget.showGlow
                    ? [
                        BoxShadow(
                          color: widget.glowColor
                              .withOpacity(0.25 * _glowAnimation.value),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: widget.glowColor
                              .withOpacity(0.15 * _glowAnimation.value),
                          blurRadius: 80,
                          spreadRadius: 16,
                        ),
                      ]
                    : AppShadows.lg,
                border: Border.all(
                  color: AppColors.mist,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.pure,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: AppColors.pearl,
                        width: 2,
                      ),
                    ),
                    child: PrettyQrView.data(
                      data: widget.data,
                      decoration: PrettyQrDecoration(
                        shape: PrettyQrSmoothSymbol(
                          color: AppColors.voidBlack,
                          roundFactor: 1,
                        ),
                        image: const PrettyQrDecorationImage(
                          image: AssetImage('assets/logo/smartexit_logo.png'),
                          position: PrettyQrDecorationImagePosition.embedded,
                        ),
                      ),
                    ),
                  ),
                  if (widget.badge != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    widget.badge!,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Verified badge pill
class VerifiedBadge extends StatelessWidget {
  final String text;
  final Color color;

  const VerifiedBadge({
    super.key,
    this.text = 'PAID',
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Timer countdown display
class CountdownTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const CountdownTimer({
    super.key,
    required this.duration,
    this.onComplete,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final remaining = widget.duration * (1 - _controller.value);
        final isLow = remaining.inSeconds <= 60;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isLow
                ? AppColors.errorLight
                : AppColors.pearl,
            borderRadius: AppSpacing.borderRadiusFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: isLow ? AppColors.error : AppColors.steel,
              ),
              const SizedBox(width: 8),
              Text(
                'Valid for ${_formatDuration(remaining)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isLow ? AppColors.error : AppColors.steel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
