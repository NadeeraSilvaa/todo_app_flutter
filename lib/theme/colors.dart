import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF3F51B5); // Indigo
  static const Color primaryDark = Color(0xFF1A237E);
  static const Color accent = Color(0xFFFF4081); // Pink
  static const Color background = Color(0xFFF5F7FA); // Light Grey
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Category Colors
  static const Color workCategory = Color(0xFF2196F3); // Blue
  static const Color personalCategory = Color(0xFF4CAF50); // Green
  static const Color urgentCategory = Color(0xFFF44336); // Red

  // Priority Colors
  static const Color priorityLow = Color(0xFF4CAF50);
  static const Color priorityMedium = Color(0xFFFFC107);
  static const Color priorityHigh = Color(0xFFF44336);

  // Gradients
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF3F51B5), Color(0xFF7986CB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFFFF4081), Color(0xFFF50057)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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