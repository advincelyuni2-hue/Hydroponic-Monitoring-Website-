import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';
import 'supabase_client.dart';

class NotificationService {
  RealtimeChannel? subscribeToAdminAlerts({
    required void Function() onAlert,
  }) {
    final client = supabaseClient;
    if (client == null || appProfile.value?.isAdmin != true) return null;
    return client
        .channel('admin-alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (_) => onAlert(),
        )
        .subscribe();
  }

  Future<void> sendAdminAlert(String message) async {
    final client = supabaseClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('An authenticated Supabase session is required.');
    }
    await client.from('notifications').insert({
      'employee_id': user.id,
      'message': message,
      'status': 'unread',
    });
  }

  Future<int> unreadAdminAlertCount() async {
    final client = supabaseClient;
    if (client == null || appProfile.value?.isAdmin != true) return 0;
    final rows =
        await client.from('notifications').select('id').eq('status', 'unread');
    return rows.length;
  }

  Future<List<AppNotification>> getNotifications() async {
    final client = supabaseClient;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      final isAdmin = appProfile.value?.isAdmin == true;
      final query = client
          .from('notifications')
          .select('id, message, status, timestamp, created_at');
      final rows = isAdmin
          ? await query.order('created_at', ascending: false).limit(10)
          : await query
              .eq('employee_id', user.id)
              .order('created_at', ascending: false)
              .limit(10);
      return (rows as List).cast<Map<String, dynamic>>().map((row) {
        final critical = (row['message'] as String? ?? '')
            .toLowerCase()
            .contains('critical');
        return AppNotification(
          id: row['id'].toString(),
          databaseId: row['id'].toString(),
          title: critical ? 'Critical alert' : 'Notification',
          detail: row['message'] as String? ?? '',
          timeAgo: _timeAgo(
              DateTime.tryParse((row['timestamp'] ?? row['created_at']) as String? ?? '')),
          isCritical: critical,
        );
      }).toList();
    }
    return const [];
  }

  String _timeAgo(DateTime? timestamp) {
    if (timestamp == null) return 'Recent';
    final difference = DateTime.now().difference(timestamp.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  Future<bool> markAsRead(String notificationId) async {
    final client = supabaseClient;
    if (client == null) return false;
    await client
        .from('notifications')
        .update({'status': 'read'}).eq('id', notificationId);
    return true;
  }

  Future<bool> deleteNotification(String notificationId) async {
    final client = supabaseClient;
    if (client == null) return false;
    await client.from('notifications').delete().eq('id', notificationId);
    return true;
  }
}

/// A single notification/alert shown in the dashboard.
class AppNotification {
  final String id;
  final String title;
  final String detail;
  final String timeAgo;
  final bool isCritical;
  final String? databaseId;

  AppNotification({
    required this.id,
    required this.title,
    required this.detail,
    required this.timeAgo,
    required this.isCritical,
    this.databaseId,
  });
}
