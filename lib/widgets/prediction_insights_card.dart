import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/monitoring_models.dart';

class PredictionInsightsCard extends StatelessWidget {
  final PredictionInsightDetail detail;
  final VoidCallback onApplyFix;
  final VoidCallback onDismiss;

  const PredictionInsightsCard({
    super.key,
    required this.detail,
    required this.onApplyFix,
    required this.onDismiss,
  });

  Color get _badgeColor {
    switch (detail.statusBadge) {
      case 'Critical':
        return AppColors.alertBackground;
      case 'Normal':
        return AppColors.statusCardGreen;
      case 'Warning':
      default:
        return AppColors.statusCardYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prediction Insights', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 16),

          // Status Row + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(detail.statusLabel, style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  detail.statusBadge,
                  style: AppTextStyles.cardMeta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(detail.warningText, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 16),

          // Contributing factors section
          Text('Contributing factors', style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.air, size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text('Air humidity:', style: AppTextStyles.body),
                ],
              ),
              Text(detail.airHumidity, style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text('EC Level:', style: AppTextStyles.body),
                ],
              ),
              Text(detail.ecLevel, style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 12),

          // Callout box — themed color instead of a raw Colors.grey value.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.calloutBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              detail.calloutText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 16),

          // Current vs Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.body,
                  children: [
                    TextSpan(
                      text: 'Current ${detail.statusLabel.contains('EC') ? 'EC' : 'pH'}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: detail.currentPh.toStringAsFixed(1)),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.body,
                  children: [
                    TextSpan(
                      text: 'Target ${detail.statusLabel.contains('EC') ? 'EC' : 'pH'}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: detail.targetPh.toStringAsFixed(1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text('Suggested fix', style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
          const SizedBox(height: 4),
          for (final fix in detail.suggestedFixes)
            Text(fix, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.3)),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onApplyFix,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Apply fix', style: AppTextStyles.button.copyWith(fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryButton),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Dismiss',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 14,
                        color: AppColors.primaryButton,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
