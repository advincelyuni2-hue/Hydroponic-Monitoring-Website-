import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import '../models/monitoring_models.dart';
import '../models/reports_models.dart';
import 'dart:async';
import '../services/model_evaluation_service.dart';
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
  final ModelEvaluationService _evaluationService = ModelEvaluationService();
  bool _disposed = false;

  String? _reportHistoryRangeCacheKey;
  final Map<String, List<HistoryLogEntry>> _reportHistoryCache = {};
  String? _lastPdfBytesCacheKey;
  Uint8List? _lastPdfBytes;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  bool isLoading = false;
  bool isDistributionLoading = false;
  String? distributionError;
  String? errorMessage;
  UserProfile? profile;
  int _distributionRequest = 0;
  int _trendRequest = 0;

  String lastUpdatedTimestamp = 'Loading sensor history...';

  String get alertsDateRange {
    final end = manilaNow();
    final start = end.subtract(const Duration(days: 30));

    String formatDate(DateTime date) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final year = (date.year % 100).toString().padLeft(2, '0');
      return '$month/$day/$year';
    }

    return '${formatDate(start)} – ${formatDate(end)}';
  }

  ReportSummaryData summary = const ReportSummaryData(
    avgPh: 6.2,
    phStatus: 'In range',
    avgEc: 5.7,
    ecStatus: 'Stable',
    avgTemp: 24.5,
    tempStatus: 'In range',
    criticalAlertsCount: 0,
    alertsPeriod: 'Last 30 days',
  );

  List<AnalyticsPoint> trendPoints = [
    const AnalyticsPoint(label: 'Jul 1', value: 6.4),
    const AnalyticsPoint(label: 'Jul 5', value: 6.6),
    const AnalyticsPoint(label: 'Jul 9', value: 6.9),
    const AnalyticsPoint(label: 'Jul 13', value: 6.6),
    const AnalyticsPoint(label: 'Jul 17', value: 6.2),
    const AnalyticsPoint(label: 'Jul 21', value: 6.1),
    const AnalyticsPoint(label: 'Jul 25', value: 6.5),
    const AnalyticsPoint(label: 'Jul 29', value: 6.2),
  ];

  // Kept empty for PDF compatibility; model predictions are not report data.
  List<PredictedAnalyticsPoint> predictionPoints = [];
  List<AnalyticsPoint> phTrendPoints = [];
  List<AnalyticsPoint> ecTrendPoints = [];
  String selectedPredictionParameter = 'Both';
  int selectedPredictionHorizon = 12;

  void setPredictionHorizon(int hours) {
    if (![4, 8, 12].contains(hours) || selectedPredictionHorizon == hours) {
      return;
    }

    selectedPredictionHorizon = hours;
    unawaited(loadModelEvaluation());
  }

  bool isTrendLoading = false;
  String? trendError;

  TargetDistributionData targetDistribution = const TargetDistributionData(
    optimalPercentage: 0,
    warningPercentage: 0,
    criticalPercentage: 0,
  );

  List<AlertFrequencyData> alertFrequency = const [];
  int fixedAlertsCount = 0;
  int activeAlertsCount = 0;
  List<SensorHealthItem> sensorHealthList = const [];

  ModelEvaluation modelEvaluation = ModelEvaluation.empty;
  bool isEvaluationLoading = false;
  String? evaluationError;

  String selectedParameter = 'pH'; // 'pH' or 'EC'
  String selectedTimeframe = '7d'; // '7d', '30d', '90d'
  String selectedDistributionParam = 'pH'; // 'pH', 'EC', 'Temp'

  RangeValues phRange = const RangeValues(5.5, 6.5);
  RangeValues ecRange = const RangeValues(1.2, 1.8);

  bool includeSensorLogs = true;
  bool includeCalibrationLogs = true;
  bool includePhOptimization = true;
  bool includeEcOptimization = true;
  bool includeAllAnalytics = true;
  bool includeInsightsAndDecisionSupport = true;
  bool includeInterventionLogs = true;

  bool recommendationApplied = false;
  bool recommendationDismissed = false;

  ReportsController() {
    PdfReportService.preloadLogos();
    loadData();
  }

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
    loadTargetDistribution();
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

  void toggleInsightsAndDecisionSupport(bool? val) {
    includeInsightsAndDecisionSupport = val ?? false;
    notifyListeners();
  }

  void toggleAllAnalytics(bool? val) {
    includeAllAnalytics = val ?? false;
    notifyListeners();
  }

  void toggleInterventionLogs(bool? val) {
    includeInterventionLogs = val ?? false;
    notifyListeners();
  }

  void setAllReportSections(bool value) {
    if (includeSensorLogs == value &&
        includeCalibrationLogs == value &&
        includeInterventionLogs == value &&
        includePhOptimization == value &&
        includeEcOptimization == value &&
        includeAllAnalytics == value &&
        includeInsightsAndDecisionSupport == value) {
      return;
    }

    includeSensorLogs = value;
    includeCalibrationLogs = value;
    includeInterventionLogs = value;
    includePhOptimization = value;
    includeEcOptimization = value;
    includeAllAnalytics = value;
    includeInsightsAndDecisionSupport = value;
    notifyListeners();
  }

  void dismissReportGeneration() {
    includeSensorLogs = false;
    includeCalibrationLogs = false;
    includePhOptimization = false;
    includeEcOptimization = false;
    includeAllAnalytics = false;
    includeInsightsAndDecisionSupport = false;
    includeInterventionLogs = false;
    notifyListeners();
  }

  void revertRanges() {
    final cfg = appParameterRanges.value;
    phRange = RangeValues(cfg.phMin, cfg.phMax);
    ecRange = RangeValues(cfg.ecMin, cfg.ecMax);
    notifyListeners();
  }

  Future<void> loadTargetDistribution() async {
    final request = ++_distributionRequest;
    final parameter = selectedDistributionParam;
    isDistributionLoading = true;
    distributionError = null;
    notifyListeners();

    try {
      final distribution =
          await _reportsService.getTargetDistribution(parameter);
      if (request == _distributionRequest) {
        targetDistribution = distribution;
      }
    } catch (error) {
      if (request == _distributionRequest) {
        targetDistribution = const TargetDistributionData(
          optimalPercentage: 0,
          warningPercentage: 0,
          criticalPercentage: 0,
        );
        distributionError = error.toString();
      }
    } finally {
      if (request == _distributionRequest) {
        isDistributionLoading = false;
        notifyListeners();
      }
    }
  }

  Future<List<HistoryLogEntry>> _getCachedReportHistory({
    required DateTime start,
    required DateTime end,
    required String dataKey,
    required Future<List<HistoryLogEntry>> Function() fetch,
  }) async {
    final rangeKey = '${start.toIso8601String()}|${end.toIso8601String()}';

    // A different selected range must use newly fetched records.
    if (_reportHistoryRangeCacheKey != rangeKey) {
      _reportHistoryRangeCacheKey = rangeKey;
      _reportHistoryCache.clear();
    }

    final cacheKey = '$rangeKey|$dataKey';
    final cachedRows = _reportHistoryCache[cacheKey];
    if (cachedRows != null) return cachedRows;

    final rows = await fetch();
    _reportHistoryCache[cacheKey] = rows;
    return rows;
  }

  /// Builds the PDF using the selected date range and report options.
  Future<Uint8List> buildPdfBytes({
    required DateTimeRange dateRange,
    required HistoryAggregation aggregation,
    required PdfPageFormat pageFormat,
  }) async {
    final includeSensorLogsForBuild = includeSensorLogs;
    final includeCalibrationLogsForBuild = includeCalibrationLogs;
    final includeInterventionLogsForBuild = includeInterventionLogs;
    final includePhOptimizationForBuild = includePhOptimization;
    final includeEcOptimizationForBuild = includeEcOptimization;
    final includeAllAnalyticsForBuild = includeAllAnalytics;
    final includeInsightsForBuild = includeInsightsAndDecisionSupport;

    final needsSensorHistory =
        includeSensorLogsForBuild || includeAllAnalyticsForBuild;

    final results = await Future.wait<List<HistoryLogEntry>>([
      needsSensorHistory
          ? _getCachedReportHistory(
              start: dateRange.start,
              end: dateRange.end,
              dataKey: 'sensor:$aggregation',
              fetch: () => _monitoringService.getSensorHistory(
                start: dateRange.start,
                end: dateRange.end,
                aggregation: aggregation,
              ),
            )
          : Future.value(<HistoryLogEntry>[]),
      includeCalibrationLogsForBuild
          ? _getCachedReportHistory(
              start: dateRange.start,
              end: dateRange.end,
              dataKey: 'calibration',
              fetch: () => _monitoringService.getCalibrationHistory(
                start: dateRange.start,
                end: dateRange.end,
              ),
            )
          : Future.value(<HistoryLogEntry>[]),
      includeInterventionLogsForBuild
          ? _getCachedReportHistory(
              start: dateRange.start,
              end: dateRange.end,
              dataKey: 'intervention',
              fetch: () => _monitoringService.getInterventionHistory(
                start: dateRange.start,
                end: dateRange.end,
              ),
            )
          : Future.value(<HistoryLogEntry>[]),
    ]);

    final reportSensorData = results[0];
    final sensorLogs =
        includeSensorLogsForBuild ? reportSensorData : <HistoryLogEntry>[];
    final calibrationLogs = results[1];
    final interventionLogs = results[2];

    List<AnalyticsPoint> trendFor(int valueIndex, String parameter) {
      return reportSensorData.reversed
          .where((log) => log.values.length > valueIndex)
          .map((log) {
            final value = double.tryParse(
              log.values[valueIndex].trim().split(RegExp(r'\s+')).first,
            );
            if (value == null) return null;
            return AnalyticsPoint(
              label: log.values.first,
              value: value,
              parameter: parameter,
            );
          })
          .whereType<AnalyticsPoint>()
          .toList();
    }

    final profileName = profile?.name.trim();
    final downloadedBy = profileName != null && profileName.isNotEmpty
        ? profileName
        : (supabaseClient?.auth.currentUser?.email ?? 'Current user');

    final pdfCacheKey = [
      dateRange.start.toIso8601String(),
      dateRange.end.toIso8601String(),
      aggregation.name,
      pageFormat.width,
      pageFormat.height,
      includeSensorLogsForBuild,
      includeCalibrationLogsForBuild,
      includeInterventionLogsForBuild,
      includePhOptimizationForBuild,
      includeEcOptimizationForBuild,
      includeAllAnalyticsForBuild,
      includeInsightsForBuild,
      phRange.start,
      phRange.end,
      ecRange.start,
      ecRange.end,
      downloadedBy,
    ].join('|');

    if (_lastPdfBytesCacheKey == pdfCacheKey && _lastPdfBytes != null) {
      return _lastPdfBytes!;
    }

    final bytes = await _pdfReportService.buildReport(
      downloadedBy: downloadedBy,
      pageFormat: pageFormat,
      summary: summary,
      phTrendPoints: trendFor(2, 'pH'),
      ecTrendPoints: trendFor(3, 'EC'),
      predictionPoints: predictionPoints,
      sensorLogs: sensorLogs,
      calibrationLogs: calibrationLogs,
      interventionLogs: interventionLogs,
      phRange: phRange,
      ecRange: ecRange,
      includeSensorLogs: includeSensorLogsForBuild,
      includeCalibrationLogs: includeCalibrationLogsForBuild,
      includeInterventionLogs: includeInterventionLogsForBuild,
      includePhOptimization: includePhOptimizationForBuild,
      includeEcOptimization: includeEcOptimizationForBuild,
      includeAllAnalytics: includeAllAnalyticsForBuild,
      includeInsightsAndDecisionSupport: includeInsightsForBuild,
    );

    _lastPdfBytesCacheKey = pdfCacheKey;
    _lastPdfBytes = bytes;
    return bytes;
  }

  /// Builds the PDF and downloads it.
  Future<void> generatePdfReport({
    required DateTimeRange dateRange,
    required HistoryAggregation aggregation,
    required PdfPageFormat pageFormat,
  }) async {
    final bytes = await buildPdfBytes(
      dateRange: dateRange,
      aggregation: aggregation,
      pageFormat: pageFormat,
    );
    await _pdfReportService.downloadPdf(bytes);
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

  Future<void> _loadAlerts() async {
    try {
      final stats = await _reportsService.getAlertStats();
      alertFrequency = stats.byCategory;
      activeAlertsCount = stats.activeCount;
      fixedAlertsCount = stats.resolvedCount;
    } catch (error) {
      debugPrint('Alert stats failed: $error');
      alertFrequency = const [];
      activeAlertsCount = 0;
      fixedAlertsCount = 0;
    }
  }

  Future<void> _loadSensorHealth() async {
    try {
      sensorHealthList = await _reportsService.getSensorHealth();
    } catch (error) {
      debugPrint('Sensor health failed: $error');
      sensorHealthList = const [];
    }
  }

  Future<void> loadModelEvaluation() async {
    isEvaluationLoading = true;
    evaluationError = null;
    notifyListeners();
    try {
      modelEvaluation = await _evaluationService.evaluate(
        horizonHours: selectedPredictionHorizon,
      );
      if (modelEvaluation.samples.isEmpty) {
        evaluationError = modelEvaluation.records.isNotEmpty
            ? 'No un-intervened comparisons are ready yet. Pending and '
                'intervened forecasts are listed below.'
            : 'No stored predictions are available for the selected '
                '${selectedPredictionHorizon}h horizon yet. New forecasts are '
                'saved and compared automatically when their target time arrives.';
      }
    } catch (error) {
      modelEvaluation = ModelEvaluation.empty;
      evaluationError = 'Could not evaluate the forecast model: $error';
    } finally {
      isEvaluationLoading = false;
      notifyListeners();
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
      summary = await _reportsService.getSummaryData();
    } catch (_) {}

    try {
      final ranges = await _reportsService.getParameterRanges();
      phRange = ranges.ph;
      ecRange = ranges.ec;
    } catch (_) {
      final cfg = appParameterRanges.value;
      phRange = RangeValues(cfg.phMin, cfg.phMax);
      ecRange = RangeValues(cfg.ecMin, cfg.ecMax);
    }

    await loadTargetDistribution();

    await loadTrendData();

    await Future.wait([_loadAlerts(), _loadSensorHealth()]);

    try {
      final collectionRange = await _reportsService.getCollectionDateRange();
      lastUpdatedTimestamp = collectionRange == null
          ? 'No sensor readings available'
          : formatManilaDateTime(collectionRange.end);
    } catch (_) {
      lastUpdatedTimestamp = 'Unavailable';
    }

    isLoading = false;
    notifyListeners();

    // Runs in the background so the page doesn't wait for the model.
    unawaited(loadModelEvaluation());
  }
}
