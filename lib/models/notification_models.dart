enum NotificationType { warning, critical }

class AppNotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final NotificationType type;
  final String currentValue;
  final String idealRange;
  final String recommendation;
  final String timestamp;
  bool isResolved;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.currentValue,
    required this.idealRange,
    required this.recommendation,
    required this.timestamp,
    this.isResolved = false,
    this.isRead = false,
  });
}