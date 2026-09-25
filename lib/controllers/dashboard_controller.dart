import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../services/monitoring_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/supabase_client.dart';
import '../services/app_state.dart';

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
    } catch (e) {
      errorMessage = 'Could not load dashboard data';
    }

    isLoading = false;
    notifyListeners();
  }
}
