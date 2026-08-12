import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';

class ReportIssueCard extends StatelessWidget {
  final VoidCallback onAlertAdmin;

  const ReportIssueCard({super.key, required this.onAlertAdmin});

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
                Text('Report an issue', style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  'Notify an admin about this reading or if you have encountered an error',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: onAlertAdmin,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryButton),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Alert admin',
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