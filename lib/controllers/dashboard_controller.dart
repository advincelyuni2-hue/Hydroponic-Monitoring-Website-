import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monitoring_models.dart';
import '../models/notification_models.dart';
import '../services/monitoring_service.dart';
import '../services/notification_service.dart';
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
  List<AppNotificationItem> notifications = []; // Fixed type model
  List<ForecastPoint> phForecast = [];
  List<ForecastPoint> ecForecast = [];

  RealtimeChannel? parameterChannel;
  bool _refreshingParameters = false;

  DashboardController() {
    loadDashboard();
    parameterChannel = _monitoringService.subscribeToParameterChanges(
      _refreshParameterStatuses,
    );
  }

  Future<void> _refreshParameterStatuses() async {
    if (_refreshingParameters) return;
    _refreshingParameters = true;
    try {
      parameterStatuses = await _monitoringService.getParameterStatuses();
      notifyListeners();
    } catch (_) {
      // Keep existing values during transient network error
    } finally {
      _refreshingParameters = false;
    }
  }

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _userService.getProfile('mock-user-id'),
        _monitoringService.getParameterStatuses(),
        _monitoringService.getLatestInsight(),
        _notificationService.getNotifications(), // Now resolves correctly
        _monitoringService.getForecastData('ph'),
        _monitoringService.getForecastData('ec'),
      ]);

      profile = results[0] as UserProfile;
      parameterStatuses = results[1] as List<ParameterStatus>;
      latestInsight = results[2] as LatestInsight;
      notifications = results[3] as List<AppNotificationItem>;
      phForecast = results[4] as List<ForecastPoint>;
      ecForecast = results[5] as List<ForecastPoint>;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Could not load dashboard data';
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    final channel = parameterChannel;
    if (channel != null) {
      _monitoringService.unsubscribe(channel);
    }
    super.dispose();
  }
}