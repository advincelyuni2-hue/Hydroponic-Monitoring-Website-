import 'dart:async';

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
    if (selectedTab == 'Both') {
      return selectedBothInsightParam == 'pH'
          ? (phInsightDetail ?? ecInsightDetail)
          : (ecInsightDetail ?? phInsightDetail);
    } else if (selectedTab.startsWith('EC')) {
      return ecInsightDetail;
    } else {
      return phInsightDetail;
    }
  }

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    forecastIssue = null;
    notifyListeners();

    try {
      final snapshot = await monitoringService.getTelemetrySnapshot();
      final statuses = snapshot.statuses;
      isSensorOffline = snapshot.isOffline;
      isCalibrating = snapshot.isCalibrating;
      latestSensorRecordedAt = snapshot.latestRecordedAt;

      final userId = supabaseClient?.auth.currentUser?.id ??
          appProfile.value?.id ??
          'mock-user-id';
      profile = await userService.getProfile(userId);

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
        forecastingService.getForecastChartData(
          'ph',
          selectedHours: selectedHours,
          currentPh: currentPh,
          currentEc: currentEc,
          currentTemp: currentTemp,
        ),
        forecastingService.getForecastChartData(
          'ec',
          selectedHours: selectedHours,
          currentPh: currentPh,
          currentEc: currentEc,
          currentTemp: currentTemp,
        ),
      ]);

      phPoints = results[0];
      ecPoints = results[1];

      final predictedPhPoints = phPoints.where((p) => p.isPredicted).toList();
      final predictedEcPoints = ecPoints.where((p) => p.isPredicted).toList();

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
          horizonHours: selectedHours,
        ),
        forecastingService.getPredictionInsight(
          'ec',
          currentPh: currentPh,
          currentEc: currentEc,
          currentTemp: currentTemp,
          predictedPh: predictedPh,
          predictedEc: predictedEc,
          horizonHours: selectedHours,
        ),
      ]);

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
      forecastIssue = error.message;
      _clearForecastData();
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    } on ForecastEndpointUnavailableException catch (error) {
      forecastIssue = error.message;
      _clearForecastData();
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to load forecasting data';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshFreshness() async {
    try {
      final snapshot = await monitoringService.getTelemetrySnapshot();
      final wasOffline = isSensorOffline;
      isSensorOffline = snapshot.isOffline;
      isCalibrating = snapshot.isCalibrating;
      latestSensorRecordedAt = snapshot.latestRecordedAt;
      if (isSensorOffline) {
        forecastIssue = null;
        _clearForecastData();
        notifyListeners();
      } else if (wasOffline || forecastIssue != null) {
        await loadData();
      }
    } catch (_) {
      // A database/network error is not proof that the sensor is offline.
    }
  }

  void _clearForecastData() {
    phPoints = [];
    ecPoints = [];
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
    _freshnessTimer?.cancel();
    final channel = _parameterChannel;
    if (channel != null) {
      monitoringService.unsubscribe(channel);
    }
    super.dispose();
  }
}
