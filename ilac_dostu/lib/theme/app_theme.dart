import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Patient Theme - Calm & Clear
  static ThemeData get patientTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1E88E5), // Radiant Blue
        secondary: Color(0xFF42A5F5),
        surface: Color(0xFFFFFFFF), // Pure White
        background: Color(0xFFF5F7FA), // Mist White
        error: Color(0xFFE53935),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF212121),
        onBackground: Color(0xFF212121),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF212121),
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF212121),
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF212121),
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF212121),
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 20,
          color: const Color(0xFF424242),
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 18,
          color: const Color(0xFF424242),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  // Caregiver Theme - Professional & Data-Driven
  static ThemeData get caregiverTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF009688), // Teal
        secondary: Color(0xFF26A69A),
        surface: Color(0xFFFFFFFF),
        background: Color(0xFFF0F2F5),
        error: Color(0xFFFF6F61), // Coral Red for alerts
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF212121),
        onBackground: Color(0xFF212121),
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF212121),
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF212121),
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF212121),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF212121),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 20,
          color: const Color(0xFF424242),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 18,
          color: const Color(0xFF424242),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF009688),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF009688), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
