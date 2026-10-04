enum NotificationType { critical, warning, info }

class AppNotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final String timestamp;
  final NotificationType type;
  final String currentStatus;
  final String currentValue;
  final String idealRange;
  final String recommendation;
  final String? resolvedByName;
  final String? resolvedAt;
  bool isRead;
  bool isResolved;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    required this.currentStatus,
    required this.currentValue,
    required this.idealRange,
    required this.recommendation,
    this.resolvedByName,
    this.resolvedAt,
    this.isRead = false,
    this.isResolved = false,
  });

  // Backward-compatibility getters for Dashboard & Header components
  String get detail => subtitle;
  String get timeAgo => timestamp;
  String? get databaseId => id;
  bool get isCritical => type == NotificationType.critical;
}
