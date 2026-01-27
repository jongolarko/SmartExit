import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// SmartExit Premium Theme Configuration
/// Design Direction: "Effortless Luxury" - clean, refined, and distinctive
class AppTheme {
  AppTheme._();

  // ============================================
  // LIGHT THEME (Customer/Default)
  // ============================================

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Colors
    primaryColor: AppColors.voidBlack,
    scaffoldBackgroundColor: AppColors.pure,
    colorScheme: const ColorScheme.light(
      primary: AppColors.voidBlack,
      onPrimary: AppColors.pure,
      secondary: AppColors.accent,
      onSecondary: AppColors.pure,
      surface: AppColors.pure,
      onSurface: AppColors.voidBlack,
      error: AppColors.error,
      onError: AppColors.pure,
    ),

    // Typography
    textTheme: _textTheme,

    // AppBar
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.voidBlack,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.voidBlack,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.voidBlack,
        size: 24,
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.pure,
      selectedItemColor: AppColors.voidBlack,
      unselectedItemColor: AppColors.steel,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.pure,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      margin: EdgeInsets.zero,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.voidBlack,
        foregroundColor: AppColors.pure,
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeightPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.voidBlack,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.voidBlack,
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeightSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        side: const BorderSide(color: AppColors.mist, width: 1.5),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cloud,
      contentPadding: AppSpacing.input,
      border: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.mist, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.mist, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.voidBlack, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.steel,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.silver,
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.error,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.voidBlack,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.mist,
      thickness: 1,
      space: 1,
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.carbon,
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.pure,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.pure,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.voidBlack,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.steel,
      ),
    ),

    // Bottom Sheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.pure,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      dragHandleColor: AppColors.mist,
      dragHandleSize: const Size(40, 4),
    ),

    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.pearl,
      circularTrackColor: AppColors.pearl,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.cloud,
      selectedColor: AppColors.voidBlack,
      disabledColor: AppColors.pearl,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.voidBlack,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.voidBlack,
      foregroundColor: AppColors.pure,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
      ),
    ),

    // Icon
    iconTheme: const IconThemeData(
      color: AppColors.voidBlack,
      size: 24,
    ),

    // Splash/Highlight
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: AppColors.pearl,
  );

  // ============================================
  // DARK THEME (Security)
  // ============================================

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Colors
    primaryColor: AppColors.pure,
    scaffoldBackgroundColor: AppColors.voidBlack,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.pure,
      onPrimary: AppColors.voidBlack,
      secondary: AppColors.security,
      onSecondary: AppColors.pure,
      surface: AppColors.carbon,
      onSurface: AppColors.pure,
      error: AppColors.error,
      onError: AppColors.pure,
    ),

    // Typography
    textTheme: _textThemeDark,

    // AppBar
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.pure,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.pure,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.pure,
        size: 24,
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.carbon,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      margin: EdgeInsets.zero,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.pure,
        foregroundColor: AppColors.voidBlack,
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeightPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.graphite,
      contentPadding: AppSpacing.input,
      border: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.graphite, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.graphite, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.pure, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.silver,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.steel,
      ),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.graphite,
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.pure,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.security,
      linearTrackColor: AppColors.graphite,
      circularTrackColor: AppColors.graphite,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.graphite,
      thickness: 1,
      space: 1,
    ),

    // Icon
    iconTheme: const IconThemeData(
      color: AppColors.pure,
      size: 24,
    ),

    // Splash/Highlight
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: AppColors.graphite,
  );

  // ============================================
  // TEXT THEMES
  // ============================================

  static TextTheme get _textTheme => TextTheme(
    displayLarge: GoogleFonts.dmSans(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      color: AppColors.voidBlack,
    ),
    displayMedium: GoogleFonts.dmSans(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: AppColors.voidBlack,
    ),
    displaySmall: GoogleFonts.dmSans(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: AppColors.voidBlack,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: AppColors.voidBlack,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: AppColors.voidBlack,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.voidBlack,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: AppColors.voidBlack,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.voidBlack,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.voidBlack,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.voidBlack,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.voidBlack,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.steel,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: AppColors.voidBlack,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: AppColors.steel,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: AppColors.silver,
    ),
  );

  static TextTheme get _textThemeDark => TextTheme(
    displayLarge: GoogleFonts.dmSans(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      color: AppColors.pure,
    ),
    displayMedium: GoogleFonts.dmSans(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: AppColors.pure,
    ),
    displaySmall: GoogleFonts.dmSans(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: AppColors.pure,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: AppColors.pure,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: AppColors.pure,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.pure,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: AppColors.pure,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.pure,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.pure,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.pure,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.pure,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.silver,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: AppColors.pure,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: AppColors.silver,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: AppColors.steel,
    ),
  );
}
