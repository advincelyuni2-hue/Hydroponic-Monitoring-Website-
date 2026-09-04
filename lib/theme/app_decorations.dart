import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'theme_mode_controller.dart';


class AppDecorations {
  AppDecorations._();

  static BoxDecoration card({Color? color, double radius = 16}) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    return BoxDecoration(
      color: color ?? (isDark ? const Color(0xFF1B211B) : AppColors.cardBackground),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? const Color(0xFF4C584C) : AppColors.cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
