import 'package:flutter/material.dart';
import '../utils/parameter_severity.dart';
import 'app_colors.dart';

/// Shared theme mapping; null means no genuine forecast is available.
class ForecastSeverityStyle {
  final ParameterSeverity? severity;
  const ForecastSeverityStyle(this.severity);

  Color get tint => switch (severity) {
        ParameterSeverity.stable => AppColors.statusCardGreen,
        ParameterSeverity.warning => AppColors.statusCardYellow,
        ParameterSeverity.critical => AppColors.alertBackground,
        null => AppColors.surfaceMuted,
      };

  Color get text => switch (severity) {
        ParameterSeverity.stable => AppColors.accentGreen,
        ParameterSeverity.warning => AppColors.warningYellow,
        ParameterSeverity.critical => AppColors.criticalRed,
        null => AppColors.textSecondary,
      };
}
