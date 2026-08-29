import 'package:flutter/material.dart';

class DesignSystem {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF2E7D32); // Calm green
  static const Color secondaryBlue = Color(0xFF1976D2); // Trustworthy blue
  static const Color accentPurple = Color(0xFF9C27B0); // Accent purple
  static const Color backgroundLight = Color(0xFFF4F8F5); // Soft blue-green-white
  static const Color textDark = Color(0xFF1E2D37); // Dark navy/charcoal
  static const Color textSubtle = Color(0xFF5A6E7F); // Gray-blue
  
  // High Contrast Colors
  static const Color highContrastBackground = Colors.white;
  static const Color highContrastText = Colors.black;
  static const Color highContrastGreen = Color(0xFF1B5E20);
  static const Color highContrastBlue = Color(0xFF0D47A1);

  // Spacing & Border Radius
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;

  // Custom shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  // Theme builder that takes accessibility options
  static ThemeData buildTheme({
    required bool isHighContrast,
    required double textScaleFactor,
    required bool isEasyReadFont,
  }) {
    final baseTextColor = isHighContrast ? highContrastText : textDark;
    final primaryColor = isHighContrast ? highContrastGreen : primaryGreen;
    final secondaryColor = isHighContrast ? highContrastBlue : secondaryBlue;
    final baseBgColor = isHighContrast ? highContrastBackground : backgroundLight;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: baseBgColor,
      ),
      scaffoldBackgroundColor: baseBgColor,
      fontFamily: isEasyReadFont ? 'Courier' : null, // Fallback to system fonts but styled
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32 * textScaleFactor, fontWeight: FontWeight.bold, color: baseTextColor),
        headlineLarge: TextStyle(fontSize: 24 * textScaleFactor, fontWeight: FontWeight.bold, color: baseTextColor),
        headlineMedium: TextStyle(fontSize: 20 * textScaleFactor, fontWeight: FontWeight.w600, color: baseTextColor),
        bodyLarge: TextStyle(fontSize: 18 * textScaleFactor, fontWeight: FontWeight.normal, color: baseTextColor),
        bodyMedium: TextStyle(fontSize: 16 * textScaleFactor, color: isHighContrast ? Colors.black : textSubtle),
        labelLarge: TextStyle(fontSize: 16 * textScaleFactor, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusLarge),
          ),
          textStyle: TextStyle(
            fontSize: 18 * textScaleFactor,
            fontWeight: FontWeight.bold,
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          side: isHighContrast
              ? const BorderSide(color: Colors.black, width: 2.0)
              : BorderSide(color: Colors.grey.shade100),
        ),
      ),
    );
  }
}
