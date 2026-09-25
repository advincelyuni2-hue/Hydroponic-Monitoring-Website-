import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class NotificationCardWidget extends StatelessWidget {
  final AppNotificationItem item;
  final ValueChanged<bool?> onResolveChanged;
  final bool isHighlighted;
  final VoidCallback onTap;

  const NotificationCardWidget({
    super.key,
    required this.item,
    required this.onResolveChanged,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = item.type == NotificationType.critical;
    final badgeBg = isCritical ? AppColors.alertBackground : AppColors.statusCardYellow;
    final badgeText = isCritical ? 'Critical Alert' : 'Warning Alert';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card().copyWith(
          border: Border.all(
            color: isHighlighted
                ? AppColors.primaryButton
                : AppColors.cardBorder,
            width: isHighlighted ? 2.0 : 1.0,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primaryButton.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row: Checkbox, Title, Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: item.isResolved,
                    onChanged: onResolveChanged,
                    activeColor: AppColors.primaryButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTextStyles.cardMeta.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: isCritical ? AppColors.alertText : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 10),

            // Reading & Ideal Range Wrap
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              spacing: 12,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                    children: [
                      const TextSpan(
                        text: 'Current Reading: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: item.currentValue),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.cardMeta.copyWith(fontSize: 12),
                    children: [
                      const TextSpan(text: 'Ideal Range: '),
                      TextSpan(
                        text: item.idealRange,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // DSS Recommendation Box
            Text(
              'Recommendation:',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.calloutBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    item.recommendation,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Timestamp Footer
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Updated on ${item.timestamp}',
                style: AppTextStyles.cardMeta.copyWith(fontSize: 10.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}