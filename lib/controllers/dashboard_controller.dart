import 'dart:async';
import '../models/forecast_insight_summary.dart';

import 'package:flutter/material.dart';
import '../models/monitoring_models.dart'
    show
        ParameterStatus,
        TelemetrySnapshot,
        ForecastPoint,
        ForecastHorizonSummary;
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
  String? forecastIssue;
  bool isSensorOffline = false;
  bool isCalibrating = false;
  DateTime? latestSensorRecordedAt;
  DateTime? _forecastBaselineRecordedAt;
  RealtimeChannel? _parameterChannel;
  RealtimeChannel? _notificationChannel;
  Timer? _freshnessTimer;
  bool _refreshingParameters = false;
  bool _refreshingNotifications = false;
  bool _notificationRefreshPending = false;
  bool _disposed = false;
  int _telemetryVersion = 0;
  int _forecastVersion = 0;

  DashboardController() {
    loadDashboard();
    _parameterChannel = _monitoringService.subscribeToParameterChanges(
      _refreshParameterStatuses,
    );
    _notificationChannel = _notificationService.subscribeToNotifications(
      onNotification: _refreshNotifications,
    );
    _freshnessTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshParameterStatuses(),
    );
  }

  Future<void> _refreshParameterStatuses() async {
    if (_refreshingParameters || isLoading || _disposed) return;
    _refreshingParameters = true;
    final version = ++_telemetryVersion;
    ++_forecastVersion;
    try {
      final snapshot = await _monitoringService.getTelemetrySnapshot();
      if (_disposed || version != _telemetryVersion) return;
      parameterStatuses = snapshot.statuses;
      isSensorOffline = snapshot.isOffline;
      isCalibrating = snapshot.isCalibrating;
      latestSensorRecordedAt = snapshot.latestRecordedAt;
      if (isSensorOffline) {
        forecastIssue = null;
        _clearPredictiveData();
        _forecastBaselineRecordedAt = null;
      }
      notifyListeners();
      await _refreshForecastForCurrentBaseline();
    } catch (_) {
      // Keep the last known dashboard values during a transient refresh error.
    } finally {
      _refreshingParameters = false;
    }
  }

  Future<void> loadDashboard() async {
    final version = ++_telemetryVersion;
    ++_forecastVersion;
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
        _monitoringService.getTelemetrySnapshot(),
        _notificationService.getNotificationItems(limit: 3, activeOnly: true),
      ]);

      if (_disposed || version != _telemetryVersion) return;
      profile = results[0] as UserProfile;
      final snapshot = results[1] as TelemetrySnapshot;
      parameterStatuses = snapshot.statuses;
      isSensorOffline = snapshot.isOffline;
      isCalibrating = snapshot.isCalibrating;
      latestSensorRecordedAt = snapshot.latestRecordedAt;
      notifications = results[2] as List<AppNotificationItem>;
      if (isSensorOffline) {
        forecastIssue = null;
        _clearPredictiveData();
        _forecastBaselineRecordedAt = null;
      } else {
        await _refreshForecastForCurrentBaseline(notify: false);
      }
    } catch (e) {
      if (_disposed || version != _telemetryVersion) return;
      errorMessage = 'Could not load dashboard data';
    }

    if (_disposed || version != _telemetryVersion) return;
    isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshForecastForCurrentBaseline({bool notify = true}) async {
    final baseline = latestSensorRecordedAt;
    if (isSensorOffline || baseline == null) return;
    if (_forecastBaselineRecordedAt?.isAtSameMomentAs(baseline) == true) return;

    // Claim this baseline before starting the request. The one-minute freshness
    // check and the Realtime insert can arrive together; both must not generate
    // and persist the same forecast.
    _forecastBaselineRecordedAt = baseline;
    await _refreshPredictiveData(notify: notify);
  }

  Future<void> _refreshNotifications() async {
    if (_disposed) return;
    if (_refreshingNotifications) {
      _notificationRefreshPending = true;
      return;
    }
    _refreshingNotifications = true;
    try {
      do {
        _notificationRefreshPending = false;
        try {
          notifications = await _notificationService.getNotificationItems(
            limit: 3,
            activeOnly: true,
          );
          if (_disposed) return;
          notifyListeners();
        } catch (_) {
          // Keep the last known alerts during a transient refresh error.
        }
      } while (_notificationRefreshPending && !_disposed);
    } finally {
      _refreshingNotifications = false;
    }
  }

  Future<void> _refreshPredictiveData({bool notify = true}) async {
    final version = ++_forecastVersion;
    if (isSensorOffline) {
      _clearPredictiveData();
      if (notify) notifyListeners();
      return;
    }

    final currentPh = _currentValue('pH');
    final currentEc = _currentValue('EC');
    final currentTemp = _currentValue('Temp');
    if (currentPh == null || currentEc == null || currentTemp == null) {
      isSensorOffline = true;
      _clearPredictiveData();
      if (notify) notifyListeners();
      return;
    }

    late final List<List<forecasting.ForecastingChartPoint>> results;
    try {
      results = await Future.wait([
        _forecastingService.getSharedForecastChartData(
          'ph',
          selectedHours: 12,
          baselineRecordedAt: latestSensorRecordedAt,
          currentPh: currentPh,
          currentEc: currentEc,
          currentTemp: currentTemp,
        ),
        _forecastingService.getSharedForecastChartData(
          'ec',
          selectedHours: 12,
          baselineRecordedAt: latestSensorRecordedAt,
          currentPh: currentPh,
          currentEc: currentEc,
          currentTemp: currentTemp,
        ),
      ]);
    } on ForecastBaselineUnavailableException catch (error) {
      if (_disposed || version != _forecastVersion) return;
      forecastIssue = error.message;
      _clearPredictiveData();
      if (notify) notifyListeners();
      return;
    } on ForecastEndpointUnavailableException catch (error) {
      if (_disposed || version != _forecastVersion) return;
      forecastIssue = error.message;
      _clearPredictiveData();
      if (notify) notifyListeners();
      return;
    }

    if (_disposed || version != _forecastVersion) return;
    forecastIssue = null;

    final phPoints = results[0];
    final ecPoints = results[1];
    phForecast = phPoints.map(_toDashboardPoint).toList();
    ecForecast = ecPoints.map(_toDashboardPoint).toList();

    final generatedAt = manilaNow();
    forecastGeneratedAt = generatedAt;
    final phSummary =
        ForecastInsightSummary(forecast: phPoints, minimum: 0, maximum: 1);
    final ecSummary =
        ForecastInsightSummary(forecast: ecPoints, minimum: 0, maximum: 1);
    forecastSummaries = [
      for (final hours in [4, 8, 12])
        if (phSummary.valueAt(hours) != null &&
            ecSummary.valueAt(hours) != null)
          ForecastHorizonSummary(
            hoursAhead: hours,
            phValue: phSummary.valueAt(hours)!,
            ecValue: ecSummary.valueAt(hours)!,
            predictedFor: generatedAt.add(Duration(hours: hours)),
          ),
    ];

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

  double? _currentValue(String labelFragment) {
    for (final status in parameterStatuses) {
      if (status.label.contains(labelFragment)) {
        if (status.isOffline) return null;
        return double.tryParse(status.currentValue);
      }
    }
    return null;
  }

  void _clearPredictiveData() {
    ++_forecastVersion;
    phForecast = [];
    ecForecast = [];
    forecastSummaries = [];
    forecastGeneratedAt = null;
    latestInsight = null;
    phPredictionInsight = null;
    ecPredictionInsight = null;
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
    final predicted =
        ForecastInsightSummary(forecast: points, minimum: 0, maximum: 1).points;
    return predicted.isEmpty ? fallback : predicted.last.value;
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
    _disposed = true;
    ++_telemetryVersion;
    ++_forecastVersion;
    final channel = _parameterChannel;
    if (channel != null) {
      _monitoringService.unsubscribe(channel);
    }
    final notificationChannel = _notificationChannel;
    if (notificationChannel != null) {
      _notificationService.unsubscribe(notificationChannel);
    }
    _freshnessTimer?.cancel();
    super.dispose();
  }
}
