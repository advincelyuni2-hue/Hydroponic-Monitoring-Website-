import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _notificationService;
  final Set<String> _pending = {};
  bool _disposed = false;
  int _revision = 0;
  bool isBusy(String id) => _pending.contains(id);
  StreamSubscription<List<AppNotificationItem>>? _subscription;
  List<AppNotificationItem> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  NotificationController({NotificationService? service})
      : _notificationService = service ?? NotificationService() {
    initRealtimeListener();
  }

  void initRealtimeListener() {
    isLoading = true;
    notifyListeners();
    _subscription = _notificationService.streamNotificationItems().listen(
      (data) {
        if (_disposed) return;
        ++_revision;
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

  /// Retained for manual notifications. Sensor alerts use Record Fix and are
  /// resolved automatically after three stable five-minute readings.
  Future<bool> toggleResolve(AppNotificationItem item, bool? value) async {
    if (item.isSensorAlert || isBusy(item.id) || item.isResolved == value) {
      return false;
    }
    _pending.add(item.id);
    notifyListeners();
    try {
      final updated = await _notificationService.updateAlertResolved(
          item.id, value ?? false);
      if (_disposed) return updated;
      if (updated) {
        item.isResolved = value ?? false;
        for (final current in notifications.where((n) => n.id == item.id)) {
          current.isResolved = value ?? false;
        }
        errorMessage = null;
      } else {
        errorMessage = 'Unable to update this notification. Please try again.';
      }
      return updated;
    } catch (_) {
      if (!_disposed) {
        errorMessage = 'Unable to update this notification. Please try again.';
      }
      return false;
    } finally {
      _pending.remove(item.id);
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> recordFixAndResolve(
    AppNotificationItem item, {
    required String parameter,
    required double currentValue,
    required String actionType,
    double? amount,
    required String notes,
    double? reservoirVolumeL,
  }) async {
    if (_disposed || item.isResolved || isBusy(item.id)) return false;
    _pending.add(item.id);
    notifyListeners();
    try {
      final saved = await _notificationService.recordFixAndResolve(
        notificationId: item.id,
        parameter: parameter,
        currentValue: currentValue,
        currentStatus: item.currentStatus,
        actionType: actionType,
        amount: amount,
        notes: notes,
        reservoirVolumeL: reservoirVolumeL,
      );

      if (_disposed) return saved;
      if (saved) {
        errorMessage = null;
        try {
          final revision = _revision;
          final refreshed =
              await _notificationService.getNotificationItems(limit: 1000);
          if (!_disposed && revision == _revision) notifications = refreshed;
        } catch (_) {
          // Realtime remains subscribed if an immediate refresh is unavailable.
        }
      } else {
        errorMessage = _notificationService.lastInterventionError ??
            'Unable to save the intervention. The alert remains open.';
      }
      return saved;
    } finally {
      _pending.remove(item.id);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
