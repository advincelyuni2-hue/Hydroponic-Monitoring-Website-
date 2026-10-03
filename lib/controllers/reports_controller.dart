import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../models/reports_models.dart';
import '../services/app_state.dart';
import '../services/monitoring_service.dart';
import '../services/pdf_report_service.dart';
import '../services/reports_service.dart';
import '../services/supabase_client.dart';
import '../services/user_service.dart';
import '../utils/manila_time.dart';

class ReportsController extends ChangeNotifier {
  final ReportsService _reportsService = ReportsService();
  final UserService _userService = UserService();
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

  List<AnalyticsPoint> trendPoints = [];
  List<AnalyticsPoint> phTrendPoints = [];
  List<AnalyticsPoint> ecTrendPoints = [];
  List<PredictedAnalyticsPoint> predictionPoints = [];

  TargetDistributionData targetDistribution = const TargetDistributionData(
    optimalPercentage: 0,
    warningPercentage: 0,
    criticalPercentage: 0,
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
  String selectedPredictionParameter = 'Both';
  String selectedTimeframe = '7d'; // '7d', '30d', '90d'
  String selectedDistributionParam = 'pH'; // 'pH', 'EC', 'Temp'

  RangeValues phRange = const RangeValues(5.5, 6.5);
  RangeValues ecRange = const RangeValues(1.2, 1.8);

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

  int _trendRequest = 0;
  int _distributionRequest = 0;

  void setParameter(String param) {
    if (selectedParameter == param) return;
    selectedParameter = param;
    loadTrendData();
  }

  void setPredictionParameter(String param) {
    if (selectedPredictionParameter == param) return;
    selectedPredictionParameter = param;
    notifyListeners();
  }

  void setTimeframe(String tf) {
    if (selectedTimeframe == tf) return;
    selectedTimeframe = tf;
    loadTrendData();
  }

  void setDistributionParam(String param) {
    if (selectedDistributionParam == param) return;
    selectedDistributionParam = param;
    loadDistributionData();
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
    ecRange = const RangeValues(1.2, 1.8);
    notifyListeners();
  }

  Future<void> generatePdfReport() async {
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
