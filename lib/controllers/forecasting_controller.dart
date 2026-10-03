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

  String selectedBothInsightParam = 'pH'; // Inner tab selection when in 'Both' view

  double currentPh = 6.5;
  double currentEc = 1.5;
  double currentTemp = 24.0;

  List<ForecastingChartPoint> phPoints = [];
  List<ForecastingChartPoint> ecPoints = [];

  PredictionInsightDetail? phInsightDetail;
  PredictionInsightDetail? ecInsightDetail;

  ForecastingController() {
    loadData();
  }

  String get parameterKey => selectedTab.startsWith('pH')
      ? 'ph'
      : (selectedTab.startsWith('EC') ? 'ec' : 'both');

  /// Active single insight detail to display
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

      // Auto-focus the inner tab on whichever parameter has an active warning/critical badge
      if (ecInsightDetail?.statusBadge.toLowerCase() != 'stable' &&
          phInsightDetail?.statusBadge.toLowerCase() == 'stable') {
        selectedBothInsightParam = 'EC';
      } else {
        selectedBothInsightParam = 'pH';
      }

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
    _resolveInsightState(param, isApplied: true);
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
    _resolveInsightState(param, isApplied: false);
  }

  void _resolveInsightState(String param, {required bool isApplied}) {
    final updatedDetail = PredictionInsightDetail(
      statusLabel: param == 'ph' ? 'pH Level' : 'EC Level',
      statusBadge: 'Stable',
      warningText: param == 'ph'
          ? 'pH levels are stable and within optimal bounds.'
          : 'EC levels are stable and within safe parameters.',
      temperature: '${currentTemp.toStringAsFixed(1)} °C',
      ecLevel: param == 'ph'
          ? '${currentEc.toStringAsFixed(1)} mS/cm'
          : '${currentPh.toStringAsFixed(1)} pH',
      calloutText: isApplied
          ? 'Recent intervention logged: parameter fix applied successfully.'
          : 'Insight dismissed by operator.',
      currentPh: param == 'ph' ? currentPh : currentEc,
      targetPh: param == 'ph' ? 6.5 : 1.5,
      suggestedFixes: const ['No recommendation for now'],
    );

    if (param == 'ph') {
      phInsightDetail = updatedDetail;
    } else {
      ecInsightDetail = updatedDetail;
    }
    notifyListeners();
  }
}