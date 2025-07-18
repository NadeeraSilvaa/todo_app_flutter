import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF4FC3F7); // Light Blue
  static const Color primaryDark = Color(0xFF0288D1); // Darker Blue
  static const Color accent = Color(0xFFFFCA28); // Amber (complementary)
  static const Color background = Color(0xFFE3F2FD); // Very Light Blue
  static const Color cardBackground = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF212121); // Dark Grey
  static const Color textSecondary = Color(0xFFFFFFFF); // Medium Grey

  // Category Colors
  static const Color workCategory = Color(0xFF42A5F5); // Soft Blue
  static const Color personalCategory = Color(0xFF66BB6A); // Soft Green
  static const Color urgentCategory = Color(0xFFEF5350); // Soft Red

  // Priority Colors
  static const Color priorityLow = Color(0xFF66BB6A); // Soft Green
  static const Color priorityMedium = Color(0xFFFFCA28); // Amber
  static const Color priorityHigh = Color(0xFFEF5350); // Soft Red

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0D47A1); // Dark Blue
  static const Color textPrimaryDark = Color(0xFFE3F2FD); // Very Light Blue

  // Gradients
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF4FC3F7), Color(0xFF81D4FA)], // Light Blue to Lighter Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)], // Light Blue to Darker Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient pageGradient = LinearGradient(
    colors: [Color(0xFF6BB6DA), Color(0xFF4C7187)], // Gradient from top to bottom
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadows
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  );
  static const BoxShadow buttonShadow = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
}