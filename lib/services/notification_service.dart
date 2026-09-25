import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_models.dart';
import 'supabase_client.dart';

class NotificationService {
  /// Fetches a one-time snapshot of notifications
  Future<List<AppNotificationItem>> getNotifications() async {
    try {
      final response = await supabase
          .from('notification_alerts')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((map) => _mapToNotification(map))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Realtime stream listening to the notification_alerts table
  Stream<List<AppNotificationItem>> streamNotifications() {
    return supabase
        .from('notification_alerts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((map) => _mapToNotification(map)).toList());
  }

  /// Evaluates sensor readings and generates Supabase notification entries if thresholds are breached
  Future<void> evaluateAndCreateAlert({
    required String parameter, // 'pH', 'EC', or 'Temperature'
    required double currentValue,
    required double minIdeal,
    required double maxIdeal,
    required String unit,
    required String recommendation,
  }) async {
    bool isLow = currentValue < minIdeal;
    bool isHigh = currentValue > maxIdeal;

    if (!isLow && !isHigh) return;

    bool isCritical = false;
    if (parameter == 'pH') {
      isCritical = currentValue < 5.0 || currentValue > 7.0;
    } else if (parameter == 'EC') {
      isCritical = currentValue < 0.8 || currentValue > 2.2;
    } else if (parameter == 'Temperature') {
      isCritical = currentValue > 30.0;
    }

    String typeStr = isCritical ? 'critical' : 'warning';
    String severityLabel = isCritical ? 'Critical' : 'Warning';
    String direction = isHigh ? 'High' : 'Low';
    String alertId =
        'notif_${parameter.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';

    String title = '$parameter Level $direction $severityLabel';
    String subtitle = '$parameter: $currentValue $unit - $recommendation';
    String idealRange = '$minIdeal - $maxIdeal $unit'.trim();

    try {
      await supabase.from('notification_alerts').insert({
        'id': alertId,
        'parameter': parameter,
        'title': title,
        'subtitle': subtitle,
        'type': typeStr,
        'current_value': '$currentValue $unit'.trim(),
        'ideal_range': idealRange,
        'recommendation': recommendation,
        'status': 'active',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving notification alert to Supabase: $e');
    }
  }

  /// Marks all unread active notifications as read in Supabase
  Future<void> markAllAsRead() async {
    try {
      await supabase
          .from('notification_alerts')
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  /// Updates notification status from 'active' to 'resolved' in Supabase
  Future<void> updateAlertStatus(String id, bool isResolved) async {
    try {
      await supabase.from('notification_alerts').update({
        'status': isResolved ? 'resolved' : 'active',
        'resolved_at': isResolved ? DateTime.now().toIso8601String() : null,
      }).eq('id', id);
    } catch (e) {
      print('Error updating notification alert status: $e');
    }
  }

  AppNotificationItem _mapToNotification(Map<String, dynamic> map) {
    return AppNotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      type: (map['type'] == 'critical')
          ? NotificationType.critical
          : NotificationType.warning,
      currentValue: map['current_value'] ?? '',
      idealRange: map['ideal_range'] ?? '',
      recommendation: map['recommendation'] ?? '',
      timestamp: map['created_at'] != null
          ? map['created_at'].toString().split('T').first
          : '',
      isResolved: map['status'] == 'resolved',
      isRead: map['is_read'] ?? false,
    );
  }
}