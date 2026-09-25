import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../services/reports_service.dart';
import '../services/user_service.dart';
import '../services/pdf_report_service.dart';
import '../services/app_state.dart';
import '../services/supabase_client.dart';

class ReportsController extends ChangeNotifier {
  final ReportsService _reportsService = ReportsService();
  final UserService _userService = UserService();
  final PdfReportService _pdfReportService = PdfReportService();

  bool isLoading = false;
  String? errorMessage;

  UserProfile? profile;

  ReportSummaryData summary = ReportSummaryData(
    avgPh: 6.2,
    phStatus: 'In range',
    avgEc: 5.7,
    ecStatus: 'Stable',
    criticalAlertsCount: 3,
    alertsPeriod: 'This month',
  );

  List<AnalyticsPoint> trendPoints = [
    AnalyticsPoint(label: 'Jul 1', value: 6.4),
    AnalyticsPoint(label: 'Jul 5', value: 6.6),
    AnalyticsPoint(label: 'Jul 9', value: 6.9),
    AnalyticsPoint(label: 'Jul 13', value: 6.6),
    AnalyticsPoint(label: 'Jul 17', value: 6.2),
    AnalyticsPoint(label: 'Jul 21', value: 6.1),
    AnalyticsPoint(label: 'Jul 25', value: 6.5),
    AnalyticsPoint(label: 'Jul 29', value: 6.2),
  ];

  List<PredictedAnalyticsPoint> predictionPoints = [
    PredictedAnalyticsPoint(
        label: 'Jul 1', actualValue: 6.4, predictedValue: 6.3),
    PredictedAnalyticsPoint(
        label: 'Jul 5', actualValue: 6.6, predictedValue: 6.5),
    PredictedAnalyticsPoint(
        label: 'Jul 9', actualValue: 6.9, predictedValue: 6.8),
    PredictedAnalyticsPoint(
        label: 'Jul 13', actualValue: 6.5, predictedValue: 6.6),
    PredictedAnalyticsPoint(
        label: 'Jul 17', actualValue: 6.2, predictedValue: 6.1),
    PredictedAnalyticsPoint(
        label: 'Jul 21', actualValue: 6.1, predictedValue: 6.2),
    PredictedAnalyticsPoint(
        label: 'Jul 25', actualValue: 6.5, predictedValue: 6.4),
    PredictedAnalyticsPoint(
        label: 'Jul 29', actualValue: 6.2, predictedValue: 6.3),
  ];

  TargetDistributionData targetDistribution = const TargetDistributionData(
    optimalPercentage: 88,
    warningPercentage: 8,
    criticalPercentage: 4,
  );

  List<AlertFrequencyData> alertFrequency = const [
    AlertFrequencyData(category: 'pH Drift', count: 5),
    AlertFrequencyData(category: 'EC Spike', count: 2),
    AlertFrequencyData(category: 'Humidity', count: 1),
    AlertFrequencyData(category: 'Offline', count: 1),
  ];

  int fixedAlertsCount = 8;
  int activeAlertsCount = 1;

  List<SensorHealthItem> sensorHealthList = const [
    SensorHealthItem(
      sensorName: 'pH Probe',
      daysSinceCalibration: 5,
      healthPercentage: 92,
      statusLabel: 'Good',
    ),
    SensorHealthItem(
      sensorName: 'EC Sensor',
      daysSinceCalibration: 26,
      healthPercentage: 45,
      statusLabel: 'Cal Due Soon',
    ),
    SensorHealthItem(
      sensorName: 'Air Humidity',
      daysSinceCalibration: 0,
      healthPercentage: 100,
      statusLabel: 'Factory Cal',
    ),
  ];

  String selectedParameter = 'pH'; // 'pH' or 'EC'
  String selectedTimeframe = '7d'; // '7d', '30d', '90d'
  String selectedDistributionParam = 'pH';

  RangeValues phRange = const RangeValues(5.5, 6.5);
  RangeValues ecRange = const RangeValues(5.0, 6.0);

  bool includeSensorLogs = true;
  bool includeCalibrationLogs = false;
  bool includePhOptimization = true;
  bool includeEcOptimization = false;
  bool includeAllAnalytics = false;
  bool recommendationApplied = false;
  bool recommendationDismissed = false;

  ReportsController() {
    loadData();
  }

  void setParameter(String param) {
    if (selectedParameter == param) return;
    selectedParameter = param;
    loadTrendData();
  }

  void setTimeframe(String tf) {
    if (selectedTimeframe == tf) return;
    selectedTimeframe = tf;
    loadTrendData();
  }

  void setDistributionParam(String param) {
    selectedDistributionParam = param;
    notifyListeners();
  }

  void updatePhRange(RangeValues values) {
    phRange = values;
    notifyListeners();
  }

  void updateEcRange(RangeValues values) {
    ecRange = values;
    notifyListeners();
  }

  void toggleSensorLogs(bool? val) {
    includeSensorLogs = val ?? false;
    notifyListeners();
  }

  void toggleCalibrationLogs(bool? val) {
    includeCalibrationLogs = val ?? false;
    notifyListeners();
  }

  void togglePhOptimization(bool? val) {
    includePhOptimization = val ?? false;
    notifyListeners();
  }

  void toggleEcOptimization(bool? val) {
    includeEcOptimization = val ?? false;
    notifyListeners();
  }

  void toggleAllAnalytics(bool? val) {
    includeAllAnalytics = val ?? false;
    notifyListeners();
  }

  void dismissReportGeneration() {
    includeSensorLogs = false;
    includeCalibrationLogs = false;
    includePhOptimization = false;
    includeEcOptimization = false;
    includeAllAnalytics = false;
    notifyListeners();
  }

  void revertRanges() {
    phRange = const RangeValues(5.5, 6.5);
    ecRange = const RangeValues(5.0, 6.0);
    notifyListeners();
  }

  Future<void> generatePdfReport() async {
    await _pdfReportService.generateAndShare(
      summary: summary,
      trendPoints: trendPoints,
      predictionPoints: predictionPoints,
      phRange: phRange,
      ecRange: ecRange,
      selectedParameter: selectedParameter,
      includeSensorLogs: includeSensorLogs,
      includeCalibrationLogs: includeCalibrationLogs,
      includePhOptimization: includePhOptimization,
      includeEcOptimization: includeEcOptimization,
      includeAllAnalytics: includeAllAnalytics,
    );
  }

  void applyRecommendation() {
    recommendationApplied = true;
    recommendationDismissed = false;
    notifyListeners();
  }

  void dismissRecommendation() {
    recommendationDismissed = true;
    recommendationApplied = false;
    notifyListeners();
  }

  Future<void> loadTrendData() async {
    try {
      final points = await _reportsService.getTrendData(
          selectedParameter, selectedTimeframe);
      if (points.isNotEmpty) {
        trendPoints = points;
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _userService.getProfile(
        supabaseClient?.auth.currentUser?.id ??
            appProfile.value?.id ??
            'mock-user-id',
      );
    } catch (_) {}

    try {
      summary = await _reportsService.getSummaryData();
    } catch (_) {}

    try {
      final t = await _reportsService.getTrendData(
          selectedParameter, selectedTimeframe);
      if (t.isNotEmpty) trendPoints = t;
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }
}
