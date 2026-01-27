import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../core/core.dart';

/// Legacy BrandedQR widget - now uses PremiumQR internally
/// Kept for backward compatibility
class BrandedQR extends StatelessWidget {
  final String data;
  final double size;

  const BrandedQR({
    super.key,
    required this.data,
    this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.md,
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
    );
  }
}
