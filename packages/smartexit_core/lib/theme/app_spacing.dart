import 'package:flutter/material.dart';

/// SmartExit Premium Spacing System
/// Generous whitespace that breathes luxury
class AppSpacing {
  AppSpacing._();

  // ============================================
  // BASE SPACING VALUES
  // ============================================

  /// 4px - Micro spacing
  static const double xxs = 4;

  /// 8px - Extra small spacing
  static const double xs = 8;

  /// 12px - Small spacing
  static const double sm = 12;

  /// 16px - Medium spacing (default)
  static const double md = 16;

  /// 20px - Medium-large spacing
  static const double lg = 20;

  /// 24px - Large spacing
  static const double xl = 24;

  /// 32px - Extra large spacing
  static const double xxl = 32;

  /// 40px - 2X extra large spacing
  static const double xxxl = 40;

  /// 48px - Huge spacing
  static const double huge = 48;

  /// 64px - Section spacing
  static const double section = 64;

  // ============================================
  // EDGE INSETS
  // ============================================

  /// No padding
  static const EdgeInsets none = EdgeInsets.zero;

  /// 4px all sides
  static const EdgeInsets allXxs = EdgeInsets.all(xxs);

  /// 8px all sides
  static const EdgeInsets allXs = EdgeInsets.all(xs);

  /// 12px all sides
  static const EdgeInsets allSm = EdgeInsets.all(sm);

  /// 16px all sides
  static const EdgeInsets allMd = EdgeInsets.all(md);

  /// 20px all sides
  static const EdgeInsets allLg = EdgeInsets.all(lg);

  /// 24px all sides
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  /// 32px all sides
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);

  // ============================================
  // HORIZONTAL EDGE INSETS
  // ============================================

  /// 8px horizontal
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);

  /// 12px horizontal
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);

  /// 16px horizontal
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);

  /// 20px horizontal
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  /// 24px horizontal
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // ============================================
  // VERTICAL EDGE INSETS
  // ============================================

  /// 8px vertical
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);

  /// 12px vertical
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);

  /// 16px vertical
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);

  /// 20px vertical
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  /// 24px vertical
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);

  // ============================================
  // SCREEN PADDING
  // ============================================

  /// Default screen padding (24px horizontal)
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: xl);

  /// Screen padding with vertical (24px all)
  static const EdgeInsets screenAll = EdgeInsets.all(xl);

  /// Compact screen padding (16px horizontal)
  static const EdgeInsets screenCompact = EdgeInsets.symmetric(horizontal: md);

  // ============================================
  // CARD PADDING
  // ============================================

  /// Small card padding (16px)
  static const EdgeInsets cardSm = EdgeInsets.all(md);

  /// Default card padding (20px)
  static const EdgeInsets card = EdgeInsets.all(lg);

  /// Large card padding (24px)
  static const EdgeInsets cardLg = EdgeInsets.all(xl);

  // ============================================
  // BUTTON PADDING
  // ============================================

  /// Primary button padding
  static const EdgeInsets buttonPrimary = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: md,
  );

  /// Secondary button padding
  static const EdgeInsets buttonSecondary = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  /// Compact button padding
  static const EdgeInsets buttonCompact = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );

  // ============================================
  // INPUT PADDING
  // ============================================

  /// Input field padding
  static const EdgeInsets input = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  // ============================================
  // BORDER RADIUS VALUES
  // ============================================

  /// 8px radius - subtle
  static const double radiusSm = 8;

  /// 12px radius - cards
  static const double radiusMd = 12;

  /// 14px radius - buttons/inputs
  static const double radiusLg = 14;

  /// 20px radius - large cards
  static const double radiusXl = 20;

  /// 28px radius - pills/badges
  static const double radiusXxl = 28;

  /// Full radius - circles
  static const double radiusFull = 999;

  // ============================================
  // BORDER RADIUS OBJECTS
  // ============================================

  /// Small border radius (8px)
  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);

  /// Medium border radius (12px)
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);

  /// Large border radius (14px) - buttons/inputs
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);

  /// Extra large border radius (20px) - cards
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);

  /// Pills/badges (28px)
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(radiusXxl);

  /// Full/circular
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // ============================================
  // COMPONENT SIZES
  // ============================================

  /// Primary button height
  static const double buttonHeightPrimary = 56;

  /// Secondary button height
  static const double buttonHeightSecondary = 48;

  /// Input field height
  static const double inputHeight = 56;

  /// Icon button size (large)
  static const double iconButtonLarge = 56;

  /// Icon button size (medium)
  static const double iconButtonMedium = 44;

  /// Icon button size (small)
  static const double iconButtonSmall = 36;

  /// Avatar size (large)
  static const double avatarLarge = 64;

  /// Avatar size (medium)
  static const double avatarMedium = 48;

  /// Avatar size (small)
  static const double avatarSmall = 36;
}
