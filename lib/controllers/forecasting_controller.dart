import 'package:flutter/material.dart';
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

  String selectedTab = 'pH Forecast'; // 'pH Forecast', 'EC Forecast', or 'Both'
  int selectedHours = 12;

  double currentPh = 6.5;
  double currentEc = 1.5;
  double currentTemp = 24.0;

  List<ForecastingChartPoint> phPoints = [];
  List<ForecastingChartPoint> ecPoints = [];
  PredictionInsightDetail? insightDetail;

  ForecastingController() {
    loadData();
  }

  String get parameterKey => selectedTab.startsWith('pH')
      ? 'ph'
      : (selectedTab.startsWith('EC') ? 'ec' : 'both');

  /// Dynamic chart points for single-parameter views
  List<ForecastingChartPoint> get chartPoints =>
      selectedTab.startsWith('EC') ? ecPoints : phPoints;

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final statuses = await monitoringService.getParameterStatuses();
      for (var status in statuses) {
        if (status.label.contains('pH')) {
          currentPh = double.tryParse(status.currentValue) ?? 6.5;
        } else if (status.label.contains('EC')) {
          currentEc = double.tryParse(status.currentValue) ?? 1.5;
        } else if (status.label.contains('Temp')) {
          currentTemp = double.tryParse(status.currentValue) ?? 24.0;
        }
      }

      final userId = supabaseClient?.auth.currentUser?.id ??
          appProfile.value?.id ??
          'mock-user-id';

      // Fetch Profile, pH Chart Data, and EC Chart Data concurrently
      final results = await Future.wait([
        userService.getProfile(userId),
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

      profile = results[0] as UserProfile;
      phPoints = results[1] as List<ForecastingChartPoint>;
      ecPoints = results[2] as List<ForecastingChartPoint>;

      final predictedPhPoints =
          phPoints.where((p) => p.isPredicted).toList();
      final predictedEcPoints =
          ecPoints.where((p) => p.isPredicted).toList();

      final double predictedPh = predictedPhPoints.isNotEmpty
          ? predictedPhPoints.last.value
          : currentPh;
      final double predictedEc = predictedEcPoints.isNotEmpty
          ? predictedEcPoints.last.value
          : currentEc;

      final activeParamKey = parameterKey == 'both' ? 'ph' : parameterKey;

      insightDetail = await forecastingService.getPredictionInsight(
        activeParamKey,
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

  Future<void> applyFix() async {
    if (insightDetail == null) return;
    await forecastingService.saveActionLog(
      parameter: parameterKey == 'both' ? 'ph' : parameterKey,
      forecastCondition: insightDetail!.warningText,
      horizonHours: selectedHours,
      currentPh: currentPh,
      currentEc: currentEc,
      currentTemp: currentTemp,
      suggestedFixes: insightDetail!.suggestedFixes,
    );
    _clearSuggestedFixesOnly();
  }

  Future<void> dismissFix() async {
    if (insightDetail == null) return;
    await forecastingService.saveDismissedActionLog(
      parameter: parameterKey == 'both' ? 'ph' : parameterKey,
      forecastCondition: insightDetail!.warningText,
      horizonHours: selectedHours,
      currentPh: currentPh,
      currentEc: currentEc,
      currentTemp: currentTemp,
      suggestedFixes: insightDetail!.suggestedFixes,
    );
    _clearSuggestedFixesOnly();
  }

  void _clearSuggestedFixesOnly() {
    if (insightDetail == null) return;
    insightDetail = PredictionInsightDetail(
      statusLabel: insightDetail!.statusLabel,
      statusBadge: insightDetail!.statusBadge,
      warningText: insightDetail!.warningText,
      temperature: insightDetail!.temperature,
      ecLevel: insightDetail!.ecLevel,
      calloutText: insightDetail!.calloutText,
      currentPh: insightDetail!.currentPh,
      targetPh: insightDetail!.targetPh,
      suggestedFixes: ['No recommendation for now'],
    );
    notifyListeners();
  }
}