import 'package:flutter/material.dart';

/// Centralized color palette for the entire app
class AppColors {
  // Primary Colors (Pink/Rose - Modern & Professional)
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryLight = Color(0xFFFF6E40);
  static const Color primaryDark = Color(0xFFC2185B);

  // Background Colors
  static const Color background = Color(0xFFF7F7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFAFAFA);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textTertiary = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFFBDC3C7);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE91E63);
  static const Color info = Color(0xFF3498DB);

  // Accent Colors
  static const Color accent1 = Color(0xFF4CAF50);  // Green
  static const Color accent2 = Color(0xFF3F51B5);  // Indigo
  static const Color accent3 = Color(0xFF607D8B);  // Blue Grey
  static const Color accent4 = Color(0xFFFF9800);  // Orange

  // Border & Shadow Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color divider = Color(0xFFECF0F1);
  static const Color shadow = Color(0x0A000000);

  // Glassmorphism Colors
  static Color get glassWhite => Colors.white.withValues(alpha: 0.7);      // 70% white
  static Color get glassBorder => Colors.white.withValues(alpha: 0.2);    // 20% white
  static Color get glassOverlay => Colors.white.withValues(alpha: 0.1);   // 10% white

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFFF6E40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFFFCE4EC), Color(0xFFF7F7F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Helper method
  static Color withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }
}
