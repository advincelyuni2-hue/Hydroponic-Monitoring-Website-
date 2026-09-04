
import 'app_state.dart';

class NotificationService {
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
