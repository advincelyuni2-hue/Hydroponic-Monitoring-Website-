import 'package:flutter/material.dart';
import '../models/forecasting_models.dart';
import '../models/monitoring_models.dart' hide PredictionInsightDetail;
import '../services/forecasting_service.dart';
import '../services/monitoring_service.dart';
import '../services/user_service.dart';

class ForecastingController extends ChangeNotifier {
  final ForecastingService _forecastingService = ForecastingService();
  final MonitoringService _monitoringService = MonitoringService();
  final UserService userService = UserService();

  bool isLoading = true;
  String? errorMessage;
  UserProfile? profile;

  String selectedTab = 'pH Forecast';
  int selectedHours = 12;

  double currentPh = 6.5;
  double currentEc = 1.5;
  double currentTemp = 24.0;

  List<ForecastingChartPoint> chartPoints = [];
  PredictionInsightDetail? insightDetail;

  ForecastingController() {
    loadData();
  }

  String get parameterKey => selectedTab.startsWith('pH') ? 'ph' : 'ec';

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final statuses = await _monitoringService.getParameterStatuses();

      for (var status in statuses) {
        if (status.label.contains('pH')) {
          currentPh = double.tryParse(status.currentValue) ?? 6.5;
        } else if (status.label.contains('EC')) {
          currentEc = double.tryParse(status.currentValue) ?? 1.5;
        } else if (status.label.contains('Temp')) {
          currentTemp = double.tryParse(status.currentValue) ?? 24.0;
        }
      }

      final results = await Future.wait([
        userService.getProfile('mock-user-id'),
        _forecastingService.getForecastChartData(
          parameterKey,
          selectedHours: selectedHours,
          currentPh: currentPh,
          currentEc: currentEc,
          currentTemp: currentTemp,
        ),
      ]);

      profile = results[0] as UserProfile;
      chartPoints = results[1] as List<ForecastingChartPoint>;

      final predictedPoints = chartPoints.where((p) => p.isPredicted).toList();
      double? predictedPh = parameterKey == 'ph' && predictedPoints.isNotEmpty
          ? predictedPoints.last.value
          : currentPh;
      double? predictedEc = parameterKey == 'ec' && predictedPoints.isNotEmpty
          ? predictedPoints.last.value
          : currentEc;

      insightDetail = await _forecastingService.getPredictionInsight(
        parameterKey,
        currentPh: currentPh,
        currentEc: currentEc,
        currentTemp: currentTemp,
        predictedPh: predictedPh,
        predictedEc: predictedEc,
      );

      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to load forecasting data';
      isLoading = false;
      notifyListeners();
    }
  }

  void selectTab(String tab) {
    if (selectedTab == tab) return;
    selectedTab = tab;
    loadData();
  }

  void selectHours(int hours) {
    if (selectedHours == hours) return;
    selectedHours = hours;
    loadData();
  }

  /// Saves to action_logs and updates suggested fix text in UI
  Future<void> applyFix() async {
    if (insightDetail == null) return;

    await _forecastingService.saveActionLog(
      parameter: parameterKey,
      forecastCondition: insightDetail!.warningText,
      horizonHours: selectedHours,
      currentPh: currentPh,
      currentEc: currentEc,
      currentTemp: currentTemp,
      suggestedFixes: insightDetail!.suggestedFixes,
    );

    _clearSuggestedFixesOnly();
  }

  /// Saves to dismissed_action_logs without altering status or condition parameters
  Future<void> dismissFix() async {
    if (insightDetail == null) return;

    await _forecastingService.saveDismissedActionLog(
      parameter: parameterKey,
      forecastCondition: insightDetail!.warningText,
      horizonHours: selectedHours,
      currentPh: currentPh,
      currentEc: currentEc,
      currentTemp: currentTemp,
      suggestedFixes: insightDetail!.suggestedFixes,
    );

    _clearSuggestedFixesOnly();
  }

  /// Keeps status, statusBadge, and warning text identical; updates suggestedFixes only
  void _clearSuggestedFixesOnly() {
    if (insightDetail == null) return;

    insightDetail = PredictionInsightDetail(
      statusLabel: insightDetail!.statusLabel,
      statusBadge: insightDetail!.statusBadge, // Unchanged
      warningText: insightDetail!.warningText, // Unchanged
      temperature: insightDetail!.temperature, // Unchanged
      ecLevel: insightDetail!.ecLevel,         // Unchanged
      calloutText: insightDetail!.calloutText, // Unchanged
      currentPh: insightDetail!.currentPh,     // Unchanged
      targetPh: insightDetail!.targetPh,       // Unchanged
      suggestedFixes: ['No recommendation for now'],
    );

    notifyListeners();
  }
}