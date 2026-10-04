import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/notification_models.dart';

class NotificationTile extends StatelessWidget {
  final AppNotificationItem notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isCritical
            ? AppColors.alertBackground
            : AppColors.cardBackground,
        border: Border.all(
          color: notification.isCritical
              ? AppColors.alertBorder
              : AppColors.cardBorder,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: notification.isCritical
                          ? AppTextStyles.alert
                          : AppTextStyles.bodyBold,
                    ),
                    Row(
                      children: [
                        Text(notification.timestamp,
                            style: AppTextStyles.cardMeta),
                        if (onDelete != null)
                          IconButton(
                            tooltip: 'Delete notification',
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: onDelete,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(notification.subtitle, style: AppTextStyles.body),
                if (notification.currentValue != 'Not recorded' ||
                    notification.idealRange != 'Not recorded') ...[
                  const SizedBox(height: 6),
                  Text(
                    '${notification.currentStatus} • ${notification.currentValue} • Ideal: ${notification.idealRange}',
                    style: AppTextStyles.cardMeta,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
