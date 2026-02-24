import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium design tokens extracted from the mockup
class PremiumColors {
  // Core
  static const Color background = Color(0xFFEDF1F7);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color darkNavy = Color(0xFF2D3142);
  static const Color coralAccent = Color(0xFFE8646A);
  static const Color greenCheck = Color(0xFF4CAF50);

  // Medication card left borders
  static const Color pillBlue = Color(0xFF4A90D9);
  static const Color pillAmber = Color(0xFFF5A623);
  static const Color pillPurple = Color(0xFF8B6FC0);

  // Text
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF7B8794);
  static const Color textTertiary = Color(0xFFA0AAB4);

  // Misc
  static const Color divider = Color(0xFFE8ECF0);
  static const Color shimmer = Color(0xFFF5F7FA);

  static const List<Color> pillColors = [pillBlue, pillAmber, pillPurple];
}

class AppTheme {
  // Patient Theme - Premium Mockup Design
  static ThemeData get patientTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: PremiumColors.coralAccent,
        secondary: PremiumColors.pillBlue,
        surface: PremiumColors.cardWhite,
        error: Color(0xFFE53935),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: PremiumColors.textPrimary,
      ),
      scaffoldBackgroundColor: PremiumColors.background,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: PremiumColors.textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: PremiumColors.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: PremiumColors.textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: PremiumColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 20,
          color: PremiumColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 18,
          color: PremiumColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: PremiumColors.cardWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PremiumColors.coralAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PremiumColors.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: PremiumColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: PremiumColors.coralAccent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  // Caregiver Theme - Premium with teal accent
  static ThemeData get caregiverTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: PremiumColors.darkNavy,
        secondary: PremiumColors.coralAccent,
        surface: PremiumColors.cardWhite,
        error: PremiumColors.coralAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: PremiumColors.textPrimary,
      ),
      scaffoldBackgroundColor: PremiumColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: PremiumColors.textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: PremiumColors.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: PremiumColors.textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: PremiumColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 20,
          color: PremiumColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 18,
          color: PremiumColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: PremiumColors.cardWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PremiumColors.coralAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PremiumColors.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: PremiumColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: PremiumColors.coralAccent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
