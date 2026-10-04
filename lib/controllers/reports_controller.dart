import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../models/monitoring_models.dart';
import '../models/reports_models.dart';
import '../services/app_state.dart';
import '../services/monitoring_service.dart';
=======
import '../models/reports_models.dart';
import '../services/app_state.dart';
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
import '../services/pdf_report_service.dart';
import '../services/reports_service.dart';
import '../services/supabase_client.dart';
import '../services/user_service.dart';
<<<<<<< HEAD
import '../utils/manila_time.dart';
=======
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

class ReportsController extends ChangeNotifier {
  final ReportsService _reportsService = ReportsService();
  final UserService _userService = UserService();
<<<<<<< HEAD
  final MonitoringService _monitoringService = MonitoringService();
  final PdfReportService _pdfReportService = PdfReportService();

  bool isLoading = false;
  bool isTrendLoading = false;
  bool isDistributionLoading = false;
  String? trendError;
  String? distributionError;
  String? errorMessage;
  UserProfile? profile;

  String lastUpdatedTimestamp = 'Loading sensor history...';
=======
  final PdfReportService _pdfReportService = PdfReportService();

  bool isLoading = false;
  String? errorMessage;
  UserProfile? profile;

  // Formatted timestamp string for UI cards
  String lastUpdatedTimestamp = 'Oct 3, 2026, 6:22 PM';
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

  ReportSummaryData summary = const ReportSummaryData(
    avgPh: 6.2,
    phStatus: 'In range',
    avgEc: 5.7,
    ecStatus: 'Stable',
    avgTemp: 24.5,
    tempStatus: 'In range',
    criticalAlertsCount: 3,
    alertsPeriod: 'This month',
  );

<<<<<<< HEAD
  List<AnalyticsPoint> trendPoints = [];
  List<AnalyticsPoint> phTrendPoints = [];
  List<AnalyticsPoint> ecTrendPoints = [];
  List<PredictedAnalyticsPoint> predictionPoints = [];

  TargetDistributionData targetDistribution = const TargetDistributionData(
    optimalPercentage: 0,
    warningPercentage: 0,
    criticalPercentage: 0,
=======
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
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
<<<<<<< HEAD
  String selectedPredictionParameter = 'Both';
=======
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  String selectedTimeframe = '7d'; // '7d', '30d', '90d'
  String selectedDistributionParam = 'pH'; // 'pH', 'EC', 'Temp'

  RangeValues phRange = const RangeValues(5.5, 6.5);
<<<<<<< HEAD
  RangeValues ecRange = const RangeValues(1.2, 1.8);
=======
  RangeValues ecRange = const RangeValues(5.0, 6.0);
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

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

<<<<<<< HEAD
  int _trendRequest = 0;
  int _distributionRequest = 0;

=======
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  void setParameter(String param) {
    if (selectedParameter == param) return;
    selectedParameter = param;
    loadTrendData();
  }

<<<<<<< HEAD
  void setPredictionParameter(String param) {
    if (selectedPredictionParameter == param) return;
    selectedPredictionParameter = param;
    notifyListeners();
  }

=======
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  void setTimeframe(String tf) {
    if (selectedTimeframe == tf) return;
    selectedTimeframe = tf;
    loadTrendData();
  }

  void setDistributionParam(String param) {
<<<<<<< HEAD
    if (selectedDistributionParam == param) return;
    selectedDistributionParam = param;
    loadDistributionData();
=======
    selectedDistributionParam = param;
    notifyListeners();
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
<<<<<<< HEAD
    ecRange = const RangeValues(1.2, 1.8);
=======
    ecRange = const RangeValues(5.0, 6.0);
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    notifyListeners();
  }

  Future<void> generatePdfReport() async {
<<<<<<< HEAD
    final List<HistoryLogEntry> sensorLogs = includeSensorLogs
        ? await _monitoringService.getSensorLogs()
        : const <HistoryLogEntry>[];
    final List<HistoryLogEntry> calibrationLogs = includeCalibrationLogs
        ? await _monitoringService.getCalibrationLogs()
        : const <HistoryLogEntry>[];
    final trendSeries = await _reportsService.getTrendDataForParameters(
      const ['pH', 'EC'],
      selectedTimeframe,
    );
    final reportTrendPoints = [
      ...trendSeries['pH']!,
      ...trendSeries['EC']!,
    ];

    await _pdfReportService.generateAndShare(
      summary: summary,
      trendPoints: reportTrendPoints,
      predictionPoints: predictionPoints,
      sensorLogs: sensorLogs,
      calibrationLogs: calibrationLogs,
=======
    await _pdfReportService.generateAndShare(
      summary: summary,
      trendPoints: trendPoints,
      predictionPoints: predictionPoints,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
<<<<<<< HEAD
    final request = ++_trendRequest;
    isTrendLoading = true;
    trendError = null;
    notifyListeners();
    try {
      final trends = await _reportsService.getTrendDataForParameters(
        const ['pH', 'EC'],
        selectedTimeframe,
      );
      if (request != _trendRequest) return;
      phTrendPoints = trends['pH']!;
      ecTrendPoints = trends['EC']!;
      trendPoints = selectedParameter == 'pH' ? phTrendPoints : ecTrendPoints;
      if (trendPoints.isEmpty) {
        trendError = 'No sensor readings were found for this period.';
      }
    } catch (error) {
      if (request != _trendRequest) return;
      trendPoints = [];
      phTrendPoints = [];
      ecTrendPoints = [];
      trendError = 'Could not load sensor trends: $error';
    } finally {
      if (request == _trendRequest) {
        isTrendLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadDistributionData() async {
    final request = ++_distributionRequest;
    isDistributionLoading = true;
    distributionError = null;
    notifyListeners();
    try {
      final distribution = await _reportsService
          .getTargetDistribution(selectedDistributionParam);
      if (request != _distributionRequest) return;
      targetDistribution = distribution;
    } catch (error) {
      if (request != _distributionRequest) return;
      distributionError = 'Could not load frequency distribution: $error';
      targetDistribution = const TargetDistributionData(
        optimalPercentage: 0,
        warningPercentage: 0,
        criticalPercentage: 0,
      );
    } finally {
      if (request == _distributionRequest) {
        isDistributionLoading = false;
        notifyListeners();
      }
    }
=======
    try {
      final points = await _reportsService.getTrendData(
          selectedParameter, selectedTimeframe);
      if (points.isNotEmpty) {
        trendPoints = points;
      }
    } catch (_) {}
    notifyListeners();
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
<<<<<<< HEAD
      final range = await _reportsService.getCollectionDateRange();
      if (range != null) {
        lastUpdatedTimestamp = formatManilaDateTime(range.end);
      } else {
        lastUpdatedTimestamp = 'No sensor readings available';
      }
      summary = await _reportsService.getSummaryData();
      final trends = await _reportsService.getTrendDataForParameters(
        const ['pH', 'EC'],
        selectedTimeframe,
      );
      phTrendPoints = trends['pH']!;
      ecTrendPoints = trends['EC']!;
      trendPoints = selectedParameter == 'pH' ? phTrendPoints : ecTrendPoints;
      trendError = trendPoints.isEmpty
          ? 'No sensor readings were found for this period.'
          : null;
      targetDistribution = await _reportsService
          .getTargetDistribution(selectedDistributionParam);
    } catch (error) {
      errorMessage = 'Could not load report data: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
=======
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
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
