import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class NotificationOverlayWidget extends StatelessWidget {
  final List<AppNotificationItem> notifications;
  final ValueChanged<AppNotificationItem> onNotificationTap;
  final VoidCallback onViewAllTap;

  const NotificationOverlayWidget({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeNotifications =
        notifications.where((n) => !n.isResolved).toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: AppDecorations.card(radius: 16),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                ),
                GestureDetector(
                  onTap: onViewAllTap,
                  child: Text(
                    'View all notifications',
                    style: AppTextStyles.cardMeta.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 12),

            // Notification List
            if (activeNotifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No active notifications',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: activeNotifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = activeNotifications[index];
                    final isCritical = item.type == NotificationType.critical;
                    final stripeColor = isCritical
                        ? AppColors.alertBorder
                        : const Color(0xFFD97706);

                    return GestureDetector(
                      onTap: () => onNotificationTap(item),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusCardGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Severity Stripe
                            Container(
                              width: 3,
                              height: 36,
                              decoration: BoxDecoration(
                                color: stripeColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Notification Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.subtitle,
                                    style: AppTextStyles.bodyBold.copyWith(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.timestamp,
                                    style: AppTextStyles.cardMeta.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Info Icon
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}