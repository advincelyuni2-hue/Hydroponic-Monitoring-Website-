enum NotificationType { critical, warning, info }

class AppNotificationItem {
  final String id;
  final String title;
  final String subtitle;
  // Activity time retained for existing list ordering, grouping and consumers.
  final String timestamp;
  final DateTime? createdAt;
  // Actual notifications.created_at, formatted for the details panel.
  final String? alertCreatedAt;
  final String? latestActivityAt;
  final bool hasRecordedIntervention;
  final NotificationType type;
  final String currentStatus;
  final String currentValue;
  final String idealRange;
  final String recommendation;
  final String source;
  final String lifecycleState;
  final String? actionTakenAt;
  final String? recoveryStartedAt;
  final int stableReadingCount;
  final String? resolvedByName;
  final String? resolvedAt;
  bool isRead;
  bool isResolved;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.createdAt,
    this.alertCreatedAt,
    this.latestActivityAt,
    this.hasRecordedIntervention = false,
    required this.type,
    required this.currentStatus,
    required this.currentValue,
    required this.idealRange,
    required this.recommendation,
    this.source = 'manual',
    this.lifecycleState = 'open',
    this.actionTakenAt,
    this.recoveryStartedAt,
    this.stableReadingCount = 0,
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
  bool get isSensorAlert => source == 'sensor' || source == 'sensor_threshold';

  bool get isMonitoring =>
      !isResolved &&
      lifecycleState != 'resolved' &&
      (hasRecordedIntervention ||
          actionTakenAt != null ||
          lifecycleState == 'action_taken');

  String get lifecycleLabel {
    if (isResolved || lifecycleState == 'resolved') return 'Resolved';
    if (isMonitoring) return 'Monitoring';
    if (isSensorAlert) return 'Ongoing';
    if (lifecycleState == 'recovering') {
      return 'Recovering ($stableReadingCount/3 stable readings)';
    }
    return 'Open';
  }
}
