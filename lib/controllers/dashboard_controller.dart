import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monitoring_models.dart';
import '../models/notification_models.dart';
import '../services/app_state.dart';
import '../services/monitoring_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_client.dart';
import '../services/user_service.dart';

class DashboardController extends ChangeNotifier {
  final MonitoringService _monitoringService = MonitoringService();
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();

  bool isLoading = true;
  String? errorMessage;
  UserProfile? profile;

  List<ParameterStatus> parameterStatuses = [];
  LatestInsight? latestInsight;
  List<AppNotificationItem> notifications = [];
  List<ForecastPoint> phForecast = [];
  List<ForecastPoint> ecForecast = [];

  RealtimeChannel? _readingChannel;

  DashboardController() {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userId = supabaseClient?.auth.currentUser?.id ??
          appProfile.value?.id ??
          'mock-user-id';

      final results = await Future.wait([
        _userService.getProfile(userId),
        _monitoringService.getParameterStatuses(),
        _monitoringService.getLatestInsight(),
        _notificationService.getNotifications(),
        _monitoringService.getForecastData('ph'),
        _monitoringService.getForecastData('ec'),
      ]);

      profile = results[0] as UserProfile;
      parameterStatuses = results[1] as List<ParameterStatus>;
      latestInsight = results[2] as LatestInsight;
      notifications = results[3] as List<AppNotificationItem>;
      phForecast = results[4] as List<ForecastPoint>;
      ecForecast = results[5] as List<ForecastPoint>;

      _readingChannel ??= _monitoringService.subscribeToParameterChanges(
        _handleReadingChange,
      );

      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Could not load dashboard data';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleReadingChange() async {
    await loadDashboard();
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