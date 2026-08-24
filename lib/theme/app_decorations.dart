import 'package:flutter/material.dart';
import 'app_colors.dart';


class AppDecorations {
  AppDecorations._();

  static BoxDecoration card({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? AppColors.cardBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
