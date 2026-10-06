import 'dart:async';

import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../models/forecasting_models.dart' as forecasting;
import '../models/notification_models.dart';
import '../services/forecasting_service.dart';
import '../services/monitoring_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/app_state.dart';
import '../services/supabase_client.dart';
import '../utils/manila_time.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardController extends ChangeNotifier {
  final MonitoringService _monitoringService = MonitoringService();
  final ForecastingService _forecastingService = ForecastingService();
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();

  bool isLoading = true;
  String? errorMessage;

  UserProfile? profile;
  List<ParameterStatus> parameterStatuses = [];
  forecasting.PredictionInsightDetail? latestInsight;
  forecasting.PredictionInsightDetail? phPredictionInsight;
  forecasting.PredictionInsightDetail? ecPredictionInsight;
  List<AppNotificationItem> notifications = [];
  List<ForecastPoint> phForecast = [];
  List<ForecastPoint> ecForecast = [];
  List<ForecastHorizonSummary> forecastSummaries = [];
  DateTime? forecastGeneratedAt;
  RealtimeChannel? _parameterChannel;
  StreamSubscription<List<AppNotificationItem>>? _notificationSubscription;
  bool _refreshingParameters = false;

  DashboardController() {
    loadDashboard();
    _parameterChannel = _monitoringService.subscribeToParameterChanges(
      _refreshParameterStatuses,
    );
    _notificationSubscription =
        _notificationService.streamNotificationItems().listen((items) {
      notifications = items
          .where((notification) => !notification.isResolved)
          .take(3)
          .toList();
      notifyListeners();
    });
  }

  Future<void> _refreshParameterStatuses() async {
    if (_refreshingParameters) return;
    _refreshingParameters = true;
    try {
      parameterStatuses = await _monitoringService.getParameterStatuses();
      notifyListeners();
      await _refreshPredictiveData();
    } catch (_) {
      // Keep the last known dashboard values during a transient refresh error.
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
        _userService.getProfile(
          supabaseClient?.auth.currentUser?.id ??
              appProfile.value?.id ??
              'mock-user-id',
        ),
        _monitoringService.getParameterStatuses(),
        _notificationService.getNotificationItems(limit: 3, activeOnly: true),
      ]);

      profile = results[0] as UserProfile;
      parameterStatuses = results[1] as List<ParameterStatus>;
      notifications = results[2] as List<AppNotificationItem>;
      await _refreshPredictiveData(notify: false);
    } catch (e) {
      errorMessage = 'Could not load dashboard data';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshPredictiveData({bool notify = true}) async {
    final currentPh = _currentValue('pH', 6.5);
    final currentEc = _currentValue('EC', 1.5);
    final currentTemp = _currentValue('Temp', 24.0);

    final results = await Future.wait([
      _forecastingService.getForecastChartData(
        'ph',
        selectedHours: 12,
        currentPh: currentPh,
        currentEc: currentEc,
        currentTemp: currentTemp,
      ),
      _forecastingService.getForecastChartData(
        'ec',
        selectedHours: 12,
        currentPh: currentPh,
        currentEc: currentEc,
        currentTemp: currentTemp,
      ),
    ]);

    final phPoints = results[0];
    final ecPoints = results[1];
    phForecast = phPoints.map(_toDashboardPoint).toList();
    ecForecast = ecPoints.map(_toDashboardPoint).toList();

    final generatedAt = manilaNow();
    forecastGeneratedAt = generatedAt;
    forecastSummaries = [4, 8, 12]
        .map(
          (hours) => ForecastHorizonSummary(
            hoursAhead: hours,
            phValue: _predictedValueAt(phPoints, hours, currentPh),
            ecValue: _predictedValueAt(ecPoints, hours, currentEc),
            predictedFor: generatedAt.add(Duration(hours: hours)),
          ),
        )
        .toList();

    final predictedPh = _lastPredictedValue(phPoints, currentPh);
    final predictedEc = _lastPredictedValue(ecPoints, currentEc);
    final phInsight = _forecastingService.runFlutterDSS(
      parameter: 'ph',
      currentPh: currentPh,
      currentEc: currentEc,
      currentTemp: currentTemp,
      predictedPh: predictedPh,
      predictedEc: predictedEc,
    );
    final ecInsight = _forecastingService.runFlutterDSS(
      parameter: 'ec',
      currentPh: currentPh,
      currentEc: currentEc,
      currentTemp: currentTemp,
      predictedPh: predictedPh,
      predictedEc: predictedEc,
    );
    phPredictionInsight = phInsight;
    ecPredictionInsight = ecInsight;
    latestInsight =
        _severity(phInsight.statusBadge) >= _severity(ecInsight.statusBadge)
            ? phInsight
            : ecInsight;

    if (notify) notifyListeners();
  }

  double _currentValue(String labelFragment, double fallback) {
    for (final status in parameterStatuses) {
      if (status.label.contains(labelFragment)) {
        return double.tryParse(status.currentValue) ?? fallback;
      }
    }
    return fallback;
  }

  ForecastPoint _toDashboardPoint(forecasting.ForecastingChartPoint point) {
    return ForecastPoint(
      hour: point.hour,
      value: point.value,
      isPredicted: point.isPredicted,
      isFallback: point.isFallback,
    );
  }

  double _lastPredictedValue(
    List<forecasting.ForecastingChartPoint> points,
    double fallback,
  ) {
    final predicted = points.where((point) => point.isPredicted);
    return predicted.isEmpty ? fallback : predicted.last.value;
  }

  double _predictedValueAt(
    List<forecasting.ForecastingChartPoint> points,
    int hours,
    double fallback,
  ) {
    final predicted = points.where((point) => point.isPredicted).toList();
    if (predicted.isEmpty) return fallback;

    var closest = predicted.first;
    for (final point in predicted.skip(1)) {
      if ((point.hour - hours).abs() < (closest.hour - hours).abs()) {
        closest = point;
      }
    }
    return closest.value;
  }

  int _severity(String badge) {
    switch (badge.toLowerCase()) {
      case 'critical':
        return 2;
      case 'warning':
        return 1;
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    final channel = _parameterChannel;
    if (channel != null) {
      _monitoringService.unsubscribe(channel);
    }
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
