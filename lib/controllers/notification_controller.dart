import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<List<AppNotificationItem>>? _subscription;
  List<AppNotificationItem> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  NotificationController() {
    initRealtimeListener();
  }

  void initRealtimeListener() {
    isLoading = true;
    notifyListeners();
    _subscription = _notificationService.streamNotificationItems().listen(
      (data) {
        notifications = data;
        errorMessage = null;
        isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        errorMessage = 'Unable to load notifications.';
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
    final updated =
        await _notificationService.updateAlertResolved(item.id, resolved);
    if (!updated) {
      item.isResolved = !resolved;
      errorMessage = 'Unable to update this notification. Please try again.';
      notifyListeners();
    } else {
      errorMessage = null;
    }
  }

  Future<bool> recordFixAndResolve(
    AppNotificationItem item, {
    required String parameter,
    required double currentValue,
    required String actionType,
    required double amount,
    required String notes,
  }) async {
    final saved = await _notificationService.recordFixAndResolve(
      notificationId: item.id,
      parameter: parameter,
      currentValue: currentValue,
      currentStatus: item.currentStatus,
      actionType: actionType,
      amount: amount,
      notes: notes,
    );

    if (saved) {
      item.isResolved = true;
      errorMessage = null;
    } else {
      errorMessage =
          'Unable to save the fix log. The notification was not resolved.';
    }
    notifyListeners();
    return saved;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
