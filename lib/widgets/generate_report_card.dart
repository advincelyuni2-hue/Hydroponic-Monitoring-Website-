import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
<<<<<<< HEAD
import '../utils/responsive.dart';
=======
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

class GenerateReportCard extends StatelessWidget {
  final VoidCallback onGenerateReport;

  const GenerateReportCard({
    super.key,
    required this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final isMobile = Responsive.isMobile(context);
    final description = Text(
      'Export a detailed document with telemetry logs, model forecasts, and sensor health summaries.',
      style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
    );
    final button = SizedBox(
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
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: isMobile
          ? Column(
=======
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate PDF Report',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 6),
<<<<<<< HEAD
                description,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: button),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate PDF Report',
                        style:
                            AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      description,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                button,
              ],
            ),
    );
  }
}
=======
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
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
