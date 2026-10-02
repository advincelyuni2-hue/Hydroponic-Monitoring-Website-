import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusStyle {
  StatusStyle._();

  static Color background(String status) {
    switch (status.toLowerCase()) {
      case 'stable':
      case 'success':
      case 'normal':
        return AppColors.statusCardGreen;
      case 'warning':
        return AppColors.statusCardYellow;
      case 'critical':
      case 'failed':
        return AppColors.alertBackground;
      default:
        return AppColors.calloutBackground;
    }
  }

  static Color text(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
      case 'failed':
        return AppColors.alertText;
      default:
        return AppColors.textPrimary;
    }
  }
}
