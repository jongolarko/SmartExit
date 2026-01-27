import 'package:flutter/material.dart';
import 'app_colors.dart';

/// SmartExit Premium Shadow System
/// Subtle shadows that add depth without being heavy
class AppShadows {
  AppShadows._();

  // ============================================
  // ELEVATION SHADOWS
  // ============================================

  /// Level 0 - No shadow
  static const List<BoxShadow> none = [];

  /// Level 1 - Subtle elevation (cards resting)
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Level 2 - Default elevation (cards)
  static List<BoxShadow> get md => [
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.03),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  /// Level 3 - Elevated (hover states, dropdowns)
  static List<BoxShadow> get lg => [
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.05),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.04),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];

  /// Level 4 - High elevation (modals, dialogs)
  static List<BoxShadow> get xl => [
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.06),
      blurRadius: 48,
      offset: const Offset(0, 16),
    ),
  ];

  // ============================================
  // GLOW SHADOWS
  // ============================================

  /// Accent glow (success, verified states)
  static List<BoxShadow> get accentGlow => [
    BoxShadow(
      color: AppColors.accent.withOpacity(0.25),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.accent.withOpacity(0.15),
      blurRadius: 48,
      spreadRadius: 8,
    ),
  ];

  /// Strong accent glow (QR code, hero elements)
  static List<BoxShadow> get accentGlowStrong => [
    BoxShadow(
      color: AppColors.accent.withOpacity(0.35),
      blurRadius: 32,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.accent.withOpacity(0.20),
      blurRadius: 64,
      spreadRadius: 16,
    ),
  ];

  /// Security blue glow
  static List<BoxShadow> get securityGlow => [
    BoxShadow(
      color: AppColors.security.withOpacity(0.25),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.security.withOpacity(0.15),
      blurRadius: 48,
      spreadRadius: 8,
    ),
  ];

  /// Admin purple glow
  static List<BoxShadow> get adminGlow => [
    BoxShadow(
      color: AppColors.admin.withOpacity(0.25),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.admin.withOpacity(0.15),
      blurRadius: 48,
      spreadRadius: 8,
    ),
  ];

  /// Error glow
  static List<BoxShadow> get errorGlow => [
    BoxShadow(
      color: AppColors.error.withOpacity(0.25),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.error.withOpacity(0.15),
      blurRadius: 48,
      spreadRadius: 8,
    ),
  ];

  // ============================================
  // INNER SHADOWS (for depth effects)
  // ============================================

  /// Subtle inner shadow
  static List<BoxShadow> get innerSm => [
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
      blurStyle: BlurStyle.inner,
    ),
  ];

  // ============================================
  // BUTTON SHADOWS
  // ============================================

  /// Button default shadow
  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Button pressed shadow (reduced)
  static List<BoxShadow> get buttonPressed => [
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.06),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  // ============================================
  // SPECIAL EFFECTS
  // ============================================

  /// QR code container shadow
  static List<BoxShadow> get qrContainer => [
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.accent.withOpacity(0.12),
      blurRadius: 32,
      spreadRadius: 4,
    ),
  ];

  /// Bottom sheet/panel shadow
  static List<BoxShadow> get bottomSheet => [
    BoxShadow(
      color: AppColors.voidBlack.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, -8),
    ),
  ];
}
