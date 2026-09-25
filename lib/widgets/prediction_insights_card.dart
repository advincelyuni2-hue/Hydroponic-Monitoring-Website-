import 'package:flutter/material.dart';
import '../models/forecasting_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import 'apply_fix_dialog.dart';

class PredictionInsightsCard extends StatelessWidget {
  final PredictionInsightDetail detail;
  final Future<void> Function() onApplyFix;
  final Future<void> Function() onDismiss;

  const PredictionInsightsCard({
    super.key,
    required this.detail,
    required this.onApplyFix,
    required this.onDismiss,
  });

  Color get badgeColor {
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
    bool isPhTab = detail.statusLabel.contains('pH');
    String mainUnit = isPhTab ? '' : ' mS/cm';

    bool isNoRecommendation = detail.suggestedFixes.length == 1 &&
        detail.suggestedFixes.first.contains('No recommendation');

    String secondaryLabel = isPhTab ? 'EC Level:' : 'pH Level:';
    IconData secondaryIcon = isPhTab ? Icons.bolt : Icons.science;

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

          // Header Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(detail.statusLabel,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
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
          Text(
            detail.warningText,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textPrimary, height: 1.3),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 16),

          // Contributing Factors
          Text('Contributing factors',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.thermostat,
                      size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text('Temperature:', style: AppTextStyles.body),
                ],
              ),
              Text(detail.temperature, style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(secondaryIcon,
                      size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text(secondaryLabel, style: AppTextStyles.body),
                ],
              ),
              Text(detail.ecLevel, style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
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

          // High-Visibility Baseline vs Target
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current ${isPhTab ? 'pH' : 'EC'}',
                      style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${detail.currentPh.toStringAsFixed(1)}$mainUnit',
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 28,
                  width: 1,
                  color: AppColors.cardBorder,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target ${isPhTab ? 'pH' : 'EC'}',
                      style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${detail.targetPh.toStringAsFixed(1)}$mainUnit',
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 18,
                        color: AppColors.primaryButton,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // DSS Suggested Fixes
          Text('Suggested fix',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          if (isNoRecommendation)
            Text(
              'No recommendation for now',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final fix in detail.suggestedFixes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        fix,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 20),

          // Action Buttons (Disabled if No Recommendation)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: isNoRecommendation
                        ? null
                        : () => ActionConfirmationDialog.showApplyFix(
                              context,
                              onConfirm: onApplyFix,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Apply fix',
                        style: AppTextStyles.button.copyWith(fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: isNoRecommendation
                        ? null
                        : () => ActionConfirmationDialog.showDismissFix(
                              context,
                              onConfirm: onDismiss,
                            ),
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