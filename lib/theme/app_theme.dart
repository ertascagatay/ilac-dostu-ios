import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors
  static const Color _lightPrimary = Color(0xFF00509E);
  static const Color _lightBackground = Color(0xFFF5F7FA);
  static const Color _lightCardBackground = Colors.white;
  static const Color _lightTextPrimary = Color(0xFF1A1A1A);
  static const Color _lightTextSecondary = Color(0xFF757575);
  
  // Dark Theme Colors
  static const Color _darkPrimary = Color(0xFF42A5F5);
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF2C2C2C);
  static const Color _darkTextPrimary = Color(0xFFE0E0E0);
  static const Color _darkTextSecondary = Color(0xFFB0B0B0);
  
  // Shared Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFF6F61);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color darkDivider = Color(0xFF404040);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _lightPrimary,
        secondary: _lightPrimary,
        background: _lightBackground,
        surface: _lightCardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: _lightTextPrimary,
        onSurface: _lightTextPrimary,
      ),
      scaffoldBackgroundColor: _lightBackground,
      cardColor: _lightCardBackground,
      dividerColor: divider,
      
      // Text Theme
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: _lightTextPrimary,
        displayColor: _lightTextPrimary,
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: _lightCardBackground,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: _lightTextPrimary,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkPrimary,
        background: _darkBackground,
        surface: _darkSurface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onBackground: _darkTextPrimary,
        onSurface: _darkTextPrimary,
      ),
      scaffoldBackgroundColor: _darkBackground,
      cardColor: _darkCard,
      dividerColor: darkDivider,
      
      // Text Theme
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: _darkTextPrimary,
        displayColor: _darkTextPrimary,
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: _darkCard,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: _darkTextPrimary,
      ),
    );
  }
}
