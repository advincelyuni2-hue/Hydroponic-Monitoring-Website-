import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../services/monitoring_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/supabase_client.dart';
import '../services/app_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardController extends ChangeNotifier {
  final MonitoringService _monitoringService = MonitoringService();
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();

  bool isLoading = true;
  String? errorMessage;

  UserProfile? profile;
  List<ParameterStatus> parameterStatuses = [];
  LatestInsight? latestInsight;
  List<AppNotification> notifications = [];
  List<ForecastPoint> phForecast = [];
  List<ForecastPoint> ecForecast = [];
  RealtimeChannel? _readingChannel;
  bool _alertInProgress = false;

  DashboardController() {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _userService.getProfile(
          supabaseClient?.auth.currentUser?.id ??
              appProfile.value?.id ??
              'mock-user-id',
        ),
        _monitoringService.getParameterStatuses(),
        _monitoringService.getLatestInsight(),
        _notificationService.getNotifications(),
        _monitoringService.getForecastData('ph'),
        _monitoringService.getForecastData('ec'),
      ]);

      profile = results[0] as UserProfile;
      parameterStatuses = results[1] as List<ParameterStatus>;
      latestInsight = results[2] as LatestInsight;
      notifications = results[3] as List<AppNotification>;
      phForecast = results[4] as List<ForecastPoint>;
      ecForecast = results[5] as List<ForecastPoint>;
      _readingChannel ??= _monitoringService.subscribeToParameterChanges(
        _handleReadingChange,
      );
    } catch (e) {
      errorMessage = 'Could not load dashboard data';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _handleReadingChange() async {
    final previous = parameterStatuses;
    await loadDashboard();
    if (_alertInProgress || appProfile.value?.isAdmin == true) return;
    final critical = parameterStatuses.where((item) =>
        item.status == 'Critical' &&
        !previous.any((old) =>
            old.label == item.label && old.currentValue == item.currentValue));
    if (critical.isEmpty) return;
    _alertInProgress = true;
    try {
      await _notificationService.sendAdminAlert(
        '${critical.map((item) => '${item.label}: ${item.currentValue}${item.unit.isEmpty ? '' : ' ${item.unit}'}').join(', ')} is outside the configured range.',
      );
    } finally {
      _alertInProgress = false;
    }
  }

  @override
  void dispose() {
    final channel = _readingChannel;
    if (channel != null) {
      _monitoringService.unsubscribe(channel);
    }
    super.dispose();
  }
}
