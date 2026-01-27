import 'package:flutter/material.dart';

/// SmartExit Premium Color System
/// Design Direction: "Monochrome Plus" - Refined neutrals with Electric Mint accent
class AppColors {
  AppColors._();

  // ============================================
  // REFINED NEUTRALS (softer than pure black/white)
  // ============================================

  /// Primary dark - #0A0A0B
  static const Color voidBlack = Color(0xFF0A0A0B);

  /// Secondary dark - #1A1A1D
  static const Color carbon = Color(0xFF1A1A1D);

  /// Elevated surfaces - #2D2D32
  static const Color graphite = Color(0xFF2D2D32);

  /// Secondary text - #71717A
  static const Color steel = Color(0xFF71717A);

  /// Tertiary text - #A1A1AA
  static const Color silver = Color(0xFFA1A1AA);

  /// Borders - #D4D4D8
  static const Color mist = Color(0xFFD4D4D8);

  /// Subtle backgrounds - #F4F4F5
  static const Color pearl = Color(0xFFF4F4F5);

  /// Container backgrounds - #FAFAFA
  static const Color cloud = Color(0xFFFAFAFA);

  /// Primary background - #FFFFFF
  static const Color pure = Color(0xFFFFFFFF);

  // ============================================
  // ACCENT - "Electric Mint"
  // ============================================

  /// Success, verified, proceed - #10B981
  static const Color accent = Color(0xFF10B981);

  /// Light backgrounds - #D1FAE5
  static const Color accentLight = Color(0xFFD1FAE5);

  /// Pressed states - #059669
  static const Color accentDark = Color(0xFF059669);

  // ============================================
  // ROLE-SPECIFIC ACCENTS
  // ============================================

  /// Customer - Green (Go, Verified) - #10B981
  static const Color customer = Color(0xFF10B981);

  /// Security - Blue (Trust, Authority) - #3B82F6
  static const Color security = Color(0xFF3B82F6);

  /// Admin - Purple (Data, Intelligence) - #8B5CF6
  static const Color admin = Color(0xFF8B5CF6);

  /// Security light background
  static const Color securityLight = Color(0xFFDBEAFE);

  /// Admin light background
  static const Color adminLight = Color(0xFFEDE9FE);

  // ============================================
  // SEMANTIC COLORS
  // ============================================

  /// Error - #EF4444
  static const Color error = Color(0xFFEF4444);

  /// Error light background
  static const Color errorLight = Color(0xFFFEE2E2);

  /// Warning - #F59E0B
  static const Color warning = Color(0xFFF59E0B);

  /// Warning light background
  static const Color warningLight = Color(0xFFFEF3C7);

  /// Success (same as accent) - #10B981
  static const Color success = accent;

  /// Success light background
  static const Color successLight = accentLight;

  // ============================================
  // GRADIENTS
  // ============================================

  /// Premium dark gradient for overlays
  static const LinearGradient darkOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x80000000),
    ],
  );

  /// Premium accent glow gradient
  static const RadialGradient accentGlow = RadialGradient(
    colors: [
      Color(0x4010B981),
      Color(0x0010B981),
    ],
  );

  /// Security blue glow gradient
  static const RadialGradient securityGlow = RadialGradient(
    colors: [
      Color(0x403B82F6),
      Color(0x003B82F6),
    ],
  );

  /// Admin purple glow gradient
  static const RadialGradient adminGlow = RadialGradient(
    colors: [
      Color(0x408B5CF6),
      Color(0x008B5CF6),
    ],
  );

  // ============================================
  // SHADOWS
  // ============================================

  /// Subtle card shadow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: voidBlack.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Elevated shadow
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: voidBlack.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Glow shadow (accent)
  static List<BoxShadow> get accentGlowShadow => [
    BoxShadow(
      color: accent.withOpacity(0.3),
      blurRadius: 32,
      spreadRadius: 4,
    ),
  ];

  /// Security glow shadow
  static List<BoxShadow> get securityGlowShadow => [
    BoxShadow(
      color: security.withOpacity(0.3),
      blurRadius: 32,
      spreadRadius: 4,
    ),
  ];
}
