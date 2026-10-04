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
    final isCritical = item.type == NotificationType.critical ||
        item.currentStatus.toLowerCase().contains('critical');
    final isWarning = item.type == NotificationType.warning ||
        item.currentStatus.toLowerCase().contains('warning') ||
        item.currentStatus.toLowerCase().contains('drift') ||
        item.currentStatus.toLowerCase().contains('high') ||
        item.currentStatus.toLowerCase().contains('low');

    final hasReadingDetails = item.currentValue != 'Not recorded' ||
        item.idealRange != 'Not recorded';

    // Badge styling based on alert type
    final badgeBg = isCritical
        ? AppColors.alertBackground
        : (isWarning ? AppColors.statusCardYellow : AppColors.statusCardGreen);

    final badgeText = item.type == NotificationType.info
        ? 'Information'
        : isCritical
            ? 'Critical Alert'
            : 'Warning Alert';

    // Border color determined dynamically: Red for Critical, Yellow/Amber for Warning
    final Color severityBorderColor = isCritical
        ? AppColors.criticalRed
        : (isWarning ? AppColors.warningYellow : AppColors.cardBorder);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card().copyWith(
          border: Border.all(
            color: isHighlighted ? AppColors.primaryButton : severityBorderColor,
            width: isHighlighted ? 2.0 : 1.5,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primaryButton.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTextStyles.cardMeta.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: isCritical
                          ? AppColors.criticalRed
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 10),
            Text(
              item.subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            if (hasReadingDetails) ...[
              RichText(
                text: TextSpan(
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  children: [
                    const TextSpan(
                      text: 'Current Status: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: item.currentStatus,
                      style: TextStyle(
                        color: item.currentStatus == 'Within range'
                            ? AppColors.accentGreen
                            : AppColors.criticalRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
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
            ],
            const SizedBox(height: 10),
            // DSS Recommendation Box
            Text(
              'Recommendation:',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.calloutBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.recommendation,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 8),
            // Timestamp and resolution audit footer
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Created ${item.timestamp}',
                    style: AppTextStyles.cardMeta.copyWith(fontSize: 10.5),
                  ),
                ),
                if (item.isResolved && item.resolvedByName != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Resolved by ${item.resolvedByName} ${item.resolvedAt ?? ''}',
                    style: AppTextStyles.cardMeta.copyWith(
                      fontSize: 10.5,
                      color: AppColors.primaryButton,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}