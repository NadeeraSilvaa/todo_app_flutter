import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType type;
  final bool obscureText;
  final IconData? icon;
  final String? Function(String?)? validator;
  final int? maxLines;
  final ValueChanged<String>? onChanged; // Added onChanged parameter

  const CommonTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.type,
    this.obscureText = false,
    this.icon,
    this.validator,
    this.maxLines = 1,
    this.onChanged, // Include in constructor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppColors.cardShadow],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscureText,
        maxLines: maxLines,
        onChanged: onChanged, // Pass onChanged to TextField
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: icon != null ? Icon(icon, color: AppColors.accent) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.accent, width: 2),
          ),
        ),
        style: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}