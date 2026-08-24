import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';

class ReportSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String badgeText;
  final Color badgeColor;
  final Color? badgeTextColor;

  const ReportSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    required this.badgeText,
    required this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.cardMeta.copyWith(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline, // ✅ Corrected here
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.pageHeading.copyWith(fontSize: 28),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(unit, style: AppTextStyles.cardMeta.copyWith(fontSize: 13)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.cardMeta.copyWith(
                fontWeight: FontWeight.w600,
                color: badgeTextColor ?? Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}