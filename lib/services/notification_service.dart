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
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: replace with a real query / realtime subscription
    return [
      AppNotification(
        id: '1',
        title: 'Critical Overheating',
        detail: 'Water Temp ${formatTemperature(26.8)}',
        timeAgo: 'Just now',
        isCritical: true,
      ),
      AppNotification(
        id: '2',
        title: 'Critical Overheating',
        detail: 'Water Temp ${formatTemperature(26.8)}',
        timeAgo: 'Just now',
        isCritical: true,
      ),
    ];
  }

  Future<bool> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: replace with a real Supabase update
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

  AppNotification({
    required this.id,
    required this.title,
    required this.detail,
    required this.timeAgo,
    required this.isCritical,
  });
}
