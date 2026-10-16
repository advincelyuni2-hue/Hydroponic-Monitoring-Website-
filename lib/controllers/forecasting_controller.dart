import 'dart:async';
import '../models/forecast_insight_summary.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/forecasting_models.dart';
import '../services/app_state.dart';
import '../services/forecasting_service.dart';
import '../services/monitoring_service.dart';
import '../services/supabase_client.dart';
import '../services/user_service.dart';

class ForecastingController extends ChangeNotifier {
  final ForecastingService forecastingService = ForecastingService();
  final MonitoringService monitoringService = MonitoringService();
  final UserService userService = UserService();

  bool isLoading = true;
  String? errorMessage;
  UserProfile? profile;

  // Default initial view set to 'Both' so user lands on the combined graph
  String selectedTab = 'Both'; // 'pH Forecast', 'EC Forecast', or 'Both'
  int selectedHours = 12;
  String selectedBothInsightParam =
      'pH'; // Inner tab selection when in 'Both' view

  double currentPh = 6.5;
  double currentEc = 1.5;
  double currentTemp = 24.0;

  List<ForecastingChartPoint> phPoints = [];
  List<ForecastingChartPoint> ecPoints = [];

  List<ForecastingChartPoint> phInsightPoints = [];
  List<ForecastingChartPoint> ecInsightPoints = [];
  int _loadVersion = 0;
  bool _disposed = false;
  bool get isPhInsight => selectedTab == 'Both'
      ? selectedBothInsightParam == 'pH'
      : selectedTab.startsWith('pH');
  List<ForecastingChartPoint> get activeInsightPoints =>
      isPhInsight ? phInsightPoints : ecInsightPoints;

  PredictionInsightDetail? phInsightDetail;
  PredictionInsightDetail? ecInsightDetail;
  bool isSensorOffline = false;
  bool isCalibrating = false;
  String? forecastIssue;
  DateTime? latestSensorRecordedAt;
  Timer? _freshnessTimer;
  RealtimeChannel? _parameterChannel;

  ForecastingController() {
    loadData();
    _parameterChannel = monitoringService.subscribeToParameterChanges(loadData);
    _freshnessTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshFreshness(),
    );
  }

  String get parameterKey => selectedTab.startsWith('pH')
      ? 'ph'
      : (selectedTab.startsWith('EC') ? 'ec' : 'both');

  /// Active single insight detail to display based on inner tab or primary tab selection
  PredictionInsightDetail? get activeInsightDetail {
    return isPhInsight ? phInsightDetail : ecInsightDetail;
  }

  Future<void> loadData() async {
    final version = ++_loadVersion;
    final hours = selectedHours;
    isLoading = true;
    errorMessage = null;
    forecastIssue = null;
    notifyListeners();

    try {
      final snapshot = await monitoringService.getTelemetrySnapshot();
      if (_disposed || version != _loadVersion) return;
      final statuses = snapshot.statuses;
      isSensorOffline = snapshot.isOffline;
      isCalibrating = snapshot.isCalibrating;
      latestSensorRecordedAt = snapshot.latestRecordedAt;

      final userId = supabaseClient?.auth.currentUser?.id ??
          appProfile.value?.id ??
          'mock-user-id';
      final loadedProfile = await userService.getProfile(userId);
      if (_disposed || version != _loadVersion) return;
      profile = loadedProfile;

      if (isSensorOffline) {
        _clearForecastData();
        isLoading = false;
        notifyListeners();
        return;
      }

      for (var status in statuses) {
        if (status.label.contains('pH')) {
          currentPh = double.parse(status.currentValue);
        } else if (status.label.contains('EC')) {
          currentEc = double.parse(status.currentValue);
        } else if (status.label.contains('Temp')) {
          currentTemp = double.parse(status.currentValue);
        }
      }

      final results = await Future.wait([
        forecastingService.getSharedForecastChartData(
          'ph',
          selectedHours: hours,
          baselineRecordedAt: latestSensorRecordedAt,
          currentPh: currentPh,
          currentEc: currentEc,
          currentTemp: currentTemp,
        ),
        forecastingService.getSharedForecastChartData(
          'ec',
          selectedHours: hours,
          baselineRecordedAt: latestSensorRecordedAt,
          currentPh: currentPh,
          currentEc: currentEc,
          currentTemp: currentTemp,
        ),
        if (hours != 12)
          for (final parameter in ['ph', 'ec'])
            forecastingService.getSharedForecastChartData(parameter,
                selectedHours: 12,
                baselineRecordedAt: latestSensorRecordedAt,
                currentPh: currentPh,
                currentEc: currentEc,
                currentTemp: currentTemp),
      ]);
      if (_disposed || version != _loadVersion) return;
      phInsightPoints = results[hours == 12 ? 0 : 2];
      ecInsightPoints = results[hours == 12 ? 1 : 3];
      phPoints = results[0];
      ecPoints = results[1];

      final predictedPhPoints = ForecastInsightSummary(
              forecast: phInsightPoints, minimum: 0, maximum: 1)
          .points;
      final predictedEcPoints = ForecastInsightSummary(
              forecast: ecInsightPoints, minimum: 0, maximum: 1)
          .points;

      final double predictedPh = predictedPhPoints.isNotEmpty
          ? predictedPhPoints.last.value
          : currentPh;
      final double predictedEc = predictedEcPoints.isNotEmpty
          ? predictedEcPoints.last.value
          : currentEc;

      final insightResults = await Future.wait([
        forecastingService.getPredictionInsight(
          'ph',
          currentPh: currentPh,
          currentEc: currentEc,
          currentTemp: currentTemp,
          predictedPh: predictedPh,
          predictedEc: predictedEc,
          horizonHours: 12,
        ),
        forecastingService.getPredictionInsight(
          'ec',
          currentPh: currentPh,
          currentEc: currentEc,
          currentTemp: currentTemp,
          predictedPh: predictedPh,
          predictedEc: predictedEc,
          horizonHours: 12,
        ),
      ]);

      if (_disposed || version != _loadVersion) return;
      phInsightDetail = insightResults[0];
      ecInsightDetail = insightResults[1];

      // Auto-focus the inner insight tab on whichever parameter has an active alert
      if (ecInsightDetail?.statusBadge.toLowerCase() != 'stable' &&
          phInsightDetail?.statusBadge.toLowerCase() == 'stable') {
        selectedBothInsightParam = 'EC';
      } else {
        selectedBothInsightParam = 'pH';
      }

      isLoading = false;
      notifyListeners();
    } on ForecastBaselineUnavailableException catch (error) {
      if (_disposed || version != _loadVersion) return;
      forecastIssue = error.message;
      _clearForecastData();
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    } on ForecastEndpointUnavailableException catch (error) {
      if (_disposed || version != _loadVersion) return;
      forecastIssue = error.message;
      _clearForecastData();
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_disposed || version != _loadVersion) return;
      errorMessage = 'Failed to load forecasting data';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshFreshness() async {
    final version = _loadVersion;
    try {
      final snapshot = await monitoringService.getTelemetrySnapshot();
      if (_disposed || version != _loadVersion) return;
      final wasOffline = isSensorOffline;
      final previousRecordedAt = latestSensorRecordedAt;
      isSensorOffline = snapshot.isOffline;
      isCalibrating = snapshot.isCalibrating;
      latestSensorRecordedAt = snapshot.latestRecordedAt;
      if (isSensorOffline) {
        ++_loadVersion;
        isLoading = false;
        forecastIssue = null;
        _clearForecastData();
        notifyListeners();
      } else if (wasOffline ||
          forecastIssue != null ||
          previousRecordedAt != snapshot.latestRecordedAt) {
        await loadData();
      }
    } catch (_) {
      // A database/network error is not proof that the sensor is offline.
    }
  }

  void _clearForecastData() {
    phPoints = [];
    ecPoints = [];
    phInsightPoints = [];
    ecInsightPoints = [];
    phInsightDetail = null;
    ecInsightDetail = null;
  }

  void selectTab(String tab) {
    if (selectedTab == tab) return;
    selectedTab = tab;
    notifyListeners();
  }

  void setBothInsightParam(String param) {
    if (selectedBothInsightParam == param) return;
    selectedBothInsightParam = param;
    notifyListeners();
  }

  void selectHours(int hours) {
    if (selectedHours == hours) return;
    selectedHours = hours;
    loadData();
  }

  Future<void> applyFix(PredictionInsightDetail detail) async {
    final param = detail.statusLabel.contains('pH') ? 'ph' : 'ec';
    await forecastingService.saveActionLog(
      parameter: param,
      forecastCondition: detail.warningText,
      horizonHours: selectedHours,
      currentPh: currentPh,
      currentEc: currentEc,
      currentTemp: currentTemp,
      suggestedFixes: detail.suggestedFixes,
    );
    await loadData();
  }

  Future<void> dismissFix(PredictionInsightDetail detail) async {
    final param = detail.statusLabel.contains('pH') ? 'ph' : 'ec';
    await forecastingService.saveDismissedActionLog(
      parameter: param,
      forecastCondition: detail.warningText,
      horizonHours: selectedHours,
      currentPh: currentPh,
      currentEc: currentEc,
      currentTemp: currentTemp,
      suggestedFixes: detail.suggestedFixes,
    );
    await loadData();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_loadVersion;
    _freshnessTimer?.cancel();
    final channel = _parameterChannel;
    if (channel != null) {
      monitoringService.unsubscribe(channel);
    }
    super.dispose();
  }
}
