import 'package:flutter/material.dart';
import 'dart:ui';

/// Premium Theme for SmartExit Customer App
/// Design System: Shiny White + Matte Black + Minimalist
/// Typography: Plus Jakarta Sans (bundled for performance)
class PremiumColors {
  PremiumColors._();

  // ============================================
  // PRIMARY COLORS - Shiny White
  // ============================================
  static const Color primary = Color(0xFFFFFFFF);           // Pure white
  static const Color primaryDark = Color(0xFFF5F5F5);       // Light gray
  static const Color primaryLight = Color(0xFFFFFFFF);      // Pure white
  static const Color primaryUltraLight = Color(0xFFFAFAFA); // Off-white background

  // ============================================
  // ACCENT COLORS - Matte Black
  // ============================================
  static const Color accent = Color(0xFF1A1A1A);       // Matte black
  static const Color accentDark = Color(0xFF0A0A0A);   // Deep black
  static const Color accentGold = Color(0xFFC0C0C0);   // Silver

  // ============================================
  // NEUTRAL PALETTE
  // ============================================
  static const Color background = Color(0xFFFFFFFF);      // Pure white
  static const Color surface = Color(0xFFFAFAFA);         // Off-white
  static const Color darkBackground = Color(0xFF1A1A1A);  // Matte black
  static const Color cardBackground = Color(0xFFF5F5F5);  // Light gray

  // ============================================
  // TEXT COLORS
  // ============================================
  static const Color textPrimary = Color(0xFF1A1A1A);   // Matte black
  static const Color textSecondary = Color(0xFF6B6B6B); // Dark gray
  static const Color textTertiary = Color(0xFF9E9E9E);  // Medium gray
  static const Color onDark = Color(0xFFFFFFFF);        // Pure white on dark

  // ============================================
  // STATUS COLORS
  // ============================================
  static const Color success = Color(0xFF10B981);  // Emerald green - only for success states
  static const Color warning = Color(0xFFF59E0B);  // Amber
  static const Color error = Color(0xFFEF4444);    // Red

  // ============================================
  // GRADIENTS
  // ============================================
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFF1A1A1A)], // Shiny white to matte black
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE5E5E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Premium spacing constants
class PremiumSpacing {
  PremiumSpacing._();

  // Micro spacing
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;

  // Small spacing
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;

  // Large spacing
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(20);
  static const EdgeInsets cardPadding = EdgeInsets.all(20);
}

/// Premium border radius values
class PremiumRadius {
  PremiumRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  // Common radii
  static BorderRadius card = BorderRadius.circular(20);
  static BorderRadius button = BorderRadius.circular(16);
  static BorderRadius input = BorderRadius.circular(14);
  static BorderRadius bottomSheet = const BorderRadius.vertical(top: Radius.circular(32));
}

/// Premium shadow definitions
class PremiumShadows {
  PremiumShadows._();

  // Subtle shadow for cards at rest
  static List<BoxShadow> sm = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.02),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Medium shadow for elevated cards
  static List<BoxShadow> md = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Large shadow for modals/dialogs
  static List<BoxShadow> lg = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 48,
      offset: const Offset(0, 16),
    ),
  ];

  // Glow effect for primary elements (shiny white)
  static List<BoxShadow> glow = [
    BoxShadow(
      color: const Color(0xFFFFFFFF).withOpacity(0.8),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFFE5E5E5).withOpacity(0.6),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Accent glow for matte black elements
  static List<BoxShadow> accentGlow = [
    BoxShadow(
      color: const Color(0xFF1A1A1A).withOpacity(0.4),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Premium theme configuration
class PremiumTheme {
  PremiumTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: PremiumColors.primary,
        secondary: PremiumColors.accent,
        surface: PremiumColors.surface,
        error: PremiumColors.error,
      ),
      scaffoldBackgroundColor: PremiumColors.background,
      fontFamily: 'Plus Jakarta Sans',
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: PremiumColors.surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: PremiumColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PremiumColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: PremiumRadius.button,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PremiumColors.surface,
        border: OutlineInputBorder(
          borderRadius: PremiumRadius.input,
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PremiumRadius.input,
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PremiumRadius.input,
          borderSide: const BorderSide(color: PremiumColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: PremiumColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: PremiumRadius.card,
        ),
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    // Display (Hero text)
    displayLarge: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 48,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -1.5,
      color: PremiumColors.textPrimary,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -1,
      color: PremiumColors.textPrimary,
    ),

    // Headlines
    headlineLarge: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.4,
      letterSpacing: -0.5,
      color: PremiumColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: PremiumColors.textPrimary,
    ),

    // Titles
    titleLarge: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: PremiumColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: PremiumColors.textPrimary,
    ),

    // Body
    bodyLarge: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: PremiumColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: PremiumColors.textSecondary,
    ),

    // Labels
    labelLarge: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: PremiumColors.textPrimary,
    ),
  );

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Create gradient container decoration
  static BoxDecoration gradientDecoration({
    Gradient gradient = PremiumColors.heroGradient,
    double radius = 20,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows ?? PremiumShadows.glow,
    );
  }

  /// Create premium card decoration
  static BoxDecoration cardDecoration({
    Color? color,
    double radius = 20,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? PremiumColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows ?? PremiumShadows.sm,
      border: Border.all(
        color: const Color(0xFFF1F5F9),
        width: 1,
      ),
    );
  }
}
