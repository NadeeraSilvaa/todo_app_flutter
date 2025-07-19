import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class CommonGradientButton extends StatelessWidget {
  final String text;
  final Future<void> Function()? onPressed; // Keep this as nullable
  final LinearGradient? gradient;
  final bool isLoading;

  const CommonGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppColors.buttonShadow],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed, // Only disable when loading
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimaryDark),
          ),
        )
            : Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
    );
  }
}