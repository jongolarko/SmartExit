import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// SmartExit Premium Typography System
/// Font Pairing: DM Sans (Headlines) + Inter (Body/UI)
class AppTypography {
  AppTypography._();

  // ============================================
  // BASE FONT FAMILIES
  // ============================================

  /// Headlines - distinctive, modern
  static String get headlineFamily => GoogleFonts.dmSans().fontFamily!;

  /// Body/UI - highly legible, screen-optimized
  static String get bodyFamily => GoogleFonts.inter().fontFamily!;

  // ============================================
  // DISPLAY STYLES (DM Sans)
  // ============================================

  /// Display Large - 40px, weight 700
  static TextStyle get displayLarge => GoogleFonts.dmSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.1,
    color: AppColors.voidBlack,
  );

  /// Display Medium - 36px, weight 600
  static TextStyle get displayMedium => GoogleFonts.dmSans(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.15,
    color: AppColors.voidBlack,
  );

  /// Display Small - 32px, weight 600
  static TextStyle get displaySmall => GoogleFonts.dmSans(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.voidBlack,
  );

  // ============================================
  // HEADLINE STYLES (Inter)
  // ============================================

  /// Headline Large - 24px, weight 600
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
    color: AppColors.voidBlack,
  );

  /// Headline Medium - 20px, weight 600
  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColors.voidBlack,
  );

  /// Headline Small - 18px, weight 600
  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
    color: AppColors.voidBlack,
  );

  // ============================================
  // TITLE STYLES (Inter)
  // ============================================

  /// Title Large - 18px, weight 500
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.voidBlack,
  );

  /// Title Medium - 16px, weight 500
  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.voidBlack,
  );

  /// Title Small - 14px, weight 500
  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.voidBlack,
  );

  // ============================================
  // BODY STYLES (Inter)
  // ============================================

  /// Body Large - 16px, weight 400
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.voidBlack,
  );

  /// Body Medium - 14px, weight 400
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.voidBlack,
  );

  /// Body Small - 12px, weight 400
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.steel,
  );

  // ============================================
  // LABEL STYLES (Inter)
  // ============================================

  /// Label Large - 14px, weight 500
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.voidBlack,
  );

  /// Label Medium - 12px, weight 500
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.steel,
  );

  /// Label Small - 11px, weight 500
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
    color: AppColors.silver,
  );

  // ============================================
  // SPECIAL STYLES
  // ============================================

  /// Button text
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
    color: AppColors.pure,
  );

  /// Small button text
  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
    color: AppColors.pure,
  );

  /// Caption
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.4,
    color: AppColors.silver,
  );

  /// Overline
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.4,
    color: AppColors.steel,
  );

  /// Price/Amount
  static TextStyle get price => GoogleFonts.dmSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.voidBlack,
  );

  /// Badge text
  static TextStyle get badge => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
    color: AppColors.pure,
  );
}
