import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class GenerateReportCard extends StatelessWidget {
  final VoidCallback onGenerateReport;

  const GenerateReportCard({
    super.key,
    required this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate PDF Report',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  'Export a detailed document with telemetry logs, model forecasts, and sensor health summaries.',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: onGenerateReport,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryButton),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Export PDF',
                style: AppTextStyles.button.copyWith(
                  fontSize: 13,
                  color: AppColors.primaryButton,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}