import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<List<AppNotificationItem>>? _subscription;
  List<AppNotificationItem> notifications = [];
  bool isLoading = true;

  NotificationController() {
    initRealtimeListener();
  }

  void initRealtimeListener() {
    isLoading = true;
    notifyListeners();
    _subscription = _notificationService.streamNotifications().listen(
      (data) {
        notifications = data;
        isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        print('Realtime notification stream error: $error');
        isLoading = false;
        notifyListeners();
      },
    );
  }

  List<AppNotificationItem> get activeNotifications =>
      notifications.where((n) => !n.isResolved).toList();

  List<AppNotificationItem> get resolvedNotifications =>
      notifications.where((n) => n.isResolved).toList();

  /// Updates status in Supabase to 'resolved' and moves card to Resolved tab
  Future<void> toggleResolve(AppNotificationItem item, bool? value) async {
    bool resolved = value ?? false;
    item.isResolved = resolved;
    notifyListeners();
    await _notificationService.updateAlertStatus(item.id, resolved);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}