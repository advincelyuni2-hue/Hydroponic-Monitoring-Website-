import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';

class ReportGenerationCard extends StatelessWidget {
  final bool includeSensorLogs;
  final bool includeCalibrationLogs;
  final bool includePhOptimization;
  final bool includeEcOptimization;
  final bool includeAllAnalytics;
  final ValueChanged<bool?> onToggleSensorLogs;
  final ValueChanged<bool?> onToggleCalibrationLogs;
  final ValueChanged<bool?> onTogglePhOptimization;
  final ValueChanged<bool?> onToggleEcOptimization;
  final ValueChanged<bool?> onToggleAllAnalytics;
  final VoidCallback onDismiss;
  final VoidCallback onGenerate;

  const ReportGenerationCard({
    super.key,
    required this.includeSensorLogs,
    required this.includeCalibrationLogs,
    required this.includePhOptimization,
    required this.includeEcOptimization,
    required this.includeAllAnalytics,
    required this.onToggleSensorLogs,
    required this.onToggleCalibrationLogs,
    required this.onTogglePhOptimization,
    required this.onToggleEcOptimization,
    required this.onToggleAllAnalytics,
    required this.onDismiss,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report generation', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          _checkboxTile(
              'Sensor history logs', includeSensorLogs, onToggleSensorLogs),
          _checkboxTile('Calibration history logs', includeCalibrationLogs,
              onToggleCalibrationLogs),
          _checkboxTile('pH optimization results', includePhOptimization,
              onTogglePhOptimization),
          _checkboxTile('EC optimization results', includeEcOptimization,
              onToggleEcOptimization),
          _checkboxTile('All analytics and graphs', includeAllAnalytics,
              onToggleAllAnalytics),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.description,
                      color: Colors.white, size: 20),
                  label: Text('Generate report',
                      style: AppTextStyles.button.copyWith(fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onDismiss,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkboxTile(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primaryButton,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(title, style: AppTextStyles.body.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}