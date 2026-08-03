import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Standard Brand Color Palette
  static const Color primaryViolet = Color(0xFF6C5CE7);
  static const Color accentCyan = Color(0xFF00CEC9);
  static const Color darkBackground = Color(0xFF0F0E17);
  static const Color cardSurface = Color(0xFF1F1D2B);
  static const Color textPrimary = Color(0xFFFFFFFE);
  static const Color textSecondary = Color(0xFFA7A9BE);
  static const Color warningOrange = Color(0xFFFF7675);
  static const Color successGreen = Color(0xFF55E6C1);

  // High-Contrast Palette Tokens
  static const Color hcBackground = Color(0xFF000000);
  static const Color hcCardSurface = Color(0xFF121212);
  static const Color hcPrimary = Color(0xFFFFD700); // High contrast gold/yellow
  static const Color hcAccent = Color(0xFF00FFFF);  // High contrast cyan
  static const Color hcText = Color(0xFFFFFFFF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFFa29bfe)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00CEC9), Color(0xFF81ECEC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData getTheme({
    bool isHighContrast = false,
    bool isDyslexicFont = false,
  }) {
    final bg = isHighContrast ? hcBackground : darkBackground;
    final surface = isHighContrast ? hcCardSurface : cardSurface;
    final primary = isHighContrast ? hcPrimary : primaryViolet;
    final secondary = isHighContrast ? hcAccent : accentCyan;

    TextTheme baseTextTheme = ThemeData.dark().textTheme;
    if (isDyslexicFont) {
      baseTextTheme = GoogleFonts.lexendTextTheme(baseTextTheme);
    } else {
      baseTextTheme = GoogleFonts.outfitTextTheme(baseTextTheme);
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: bg,
        error: warningOrange,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: hcText, fontSize: 32, fontWeight: FontWeight.bold),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: hcText, fontSize: 22, fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: hcText, fontSize: 16),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: isHighContrast ? hcText : textSecondary, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isHighContrast ? const Color(0xFF222222) : const Color(0xFF2A2739),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: isHighContrast ? const BorderSide(color: hcPrimary) : BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData get darkTheme => getTheme();
}
