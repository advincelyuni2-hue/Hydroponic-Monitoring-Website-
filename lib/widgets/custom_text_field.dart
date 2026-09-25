import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback? onToggleObscureText;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    this.obscureText = false,
    this.onToggleObscureText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTextStyles.input,
      decoration: InputDecoration(
        suffixIcon: onToggleObscureText == null
            ? null
            : IconButton(
                tooltip: obscureText ? 'Show password' : 'Hide password',
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: onToggleObscureText,
              ),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primaryButton,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}