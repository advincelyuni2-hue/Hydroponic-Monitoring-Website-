<<<<<<< HEAD
import 'package:flutter/material.dart';

import '../models/monitoring_models.dart';
import '../models/reports_models.dart';
import 'monitoring_service.dart';

class ReportsService {
  final MonitoringService _monitoringService;
  DateTimeRange? _cachedCollectionRange;
  DateTime? _collectionRangeFetchedAt;
  Future<DateTimeRange?>? _collectionRangeRequest;

  ReportsService({MonitoringService? monitoringService})
      : _monitoringService = monitoringService ?? MonitoringService();

  Future<DateTimeRange?> getCollectionDateRange() async {
    final fetchedAt = _collectionRangeFetchedAt;
    if (_cachedCollectionRange != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < const Duration(minutes: 1)) {
      return _cachedCollectionRange;
    }

    final request = _collectionRangeRequest ??=
        _monitoringService.getSensorCollectionDateRange();
    try {
      _cachedCollectionRange = await request;
      _collectionRangeFetchedAt = DateTime.now();
      return _cachedCollectionRange;
    } finally {
      if (identical(_collectionRangeRequest, request)) {
        _collectionRangeRequest = null;
      }
    }
  }

  Future<List<AnalyticsPoint>> getTrendData(
    String parameter,
    String timeframe,
  ) async =>
      (await getTrendDataForParameters([parameter], timeframe))[parameter]!;

  Future<Map<String, List<AnalyticsPoint>>> getTrendDataForParameters(
    List<String> parameters,
    String timeframe,
  ) async {
    final range = await _getSelectedRange(timeframe);
    if (range == null) {
      return {for (final parameter in parameters) parameter: const []};
    }

    final logs = await _monitoringService.getSensorHistory(
      start: range.start,
      end: range.end,
      aggregation: HistoryAggregation.daily,
    );
    return {
      for (final parameter in parameters)
        parameter: logs.reversed
            .where((log) => _valueIndex(parameter) < log.values.length)
            .map((log) {
              final value = _parseValue(log.values[_valueIndex(parameter)]);
              if (value == null) return null;
              return AnalyticsPoint(
                label: _shortDate(log.values.first),
                value: value,
                parameter: parameter,
              );
            })
            .whereType<AnalyticsPoint>()
            .toList(),
    };
  }

  Future<ReportSummaryData> getSummaryData() async {
    final range = await _getSelectedRange('30d');
    if (range == null) {
      throw StateError('No averaged sensor readings are available.');
    }
    final logs = await _monitoringService.getSensorHistory(
      start: range.start,
      end: range.end,
      aggregation: HistoryAggregation.daily,
    );

    final phValues = _values(logs, 2);
    final ecValues = _values(logs, 3);
    final tempValues = _values(logs, 4);

    return ReportSummaryData(
      avgPh: _average(phValues),
      phStatus: _status(_average(phValues), _firstRange(logs, 2)),
      avgEc: _average(ecValues),
      ecStatus: _status(_average(ecValues), _firstRange(logs, 3)),
      avgTemp: _average(tempValues),
      tempStatus: _status(_average(tempValues), _firstRange(logs, 4)),
      criticalAlertsCount: 0,
      alertsPeriod: 'Last 30 days',
    );
  }

  Future<TargetDistributionData> getTargetDistribution(
    String parameter,
  ) async {
    final range = await getCollectionDateRange();
    if (range == null) {
      throw StateError('No averaged sensor readings are available.');
    }
    final end = DateTime(range.end.year, range.end.month, range.end.day)
        .add(const Duration(days: 1));
    final logs = await _monitoringService.getSensorHistory(
      start: DateTime(range.start.year, range.start.month, range.start.day),
      end: end,
      aggregation: HistoryAggregation.daily,
    );
    final valueIndex = _valueIndex(parameter);
    var optimal = 0;
    var warning = 0;
    var critical = 0;

    for (final log in logs) {
      final value = valueIndex < log.values.length
          ? _parseValue(log.values[valueIndex])
          : null;
      final limits = log.ranges[valueIndex];
      if (value == null || limits == null) continue;
      final margin = (limits.maximum - limits.minimum).abs() * 0.1;
      if (value < limits.minimum || value > limits.maximum) {
        critical++;
      } else if (value <= limits.minimum + margin ||
          value >= limits.maximum - margin) {
        warning++;
      } else {
        optimal++;
      }
    }

    final total = optimal + warning + critical;
    if (total == 0) {
      return const TargetDistributionData(
        optimalPercentage: 0,
        warningPercentage: 0,
        criticalPercentage: 0,
      );
    }
    return TargetDistributionData(
      optimalPercentage: optimal * 100 / total,
      warningPercentage: warning * 100 / total,
      criticalPercentage: critical * 100 / total,
    );
  }

  Future<DateTimeRange?> _getSelectedRange(String timeframe) async {
    final collectionRange = await getCollectionDateRange();
    if (collectionRange == null) return null;
    final days = int.tryParse(timeframe.replaceAll('d', ''));
    if (days == null || days <= 0) {
      throw ArgumentError.value(timeframe, 'timeframe', 'Expected e.g. 7d.');
    }

    final latestDate = DateTime(
      collectionRange.end.year,
      collectionRange.end.month,
      collectionRange.end.day,
    );
    final end = latestDate.add(const Duration(days: 1));
    final requestedStart = end.subtract(Duration(days: days));
    final collectionStart = DateTime(
      collectionRange.start.year,
      collectionRange.start.month,
      collectionRange.start.day,
    );
    final start =
        requestedStart.isBefore(collectionStart) ? collectionStart : requestedStart;
    return DateTimeRange(start: start, end: end);
  }

  int _valueIndex(String parameter) => switch (parameter.toLowerCase()) {
        'ph' => 2,
        'ec' => 3,
        'temp' || 'temperature' => 4,
        _ => throw ArgumentError.value(parameter, 'parameter'),
      };

  List<double> _values(List<HistoryLogEntry> logs, int index) => logs
      .map((log) => index < log.values.length ? _parseValue(log.values[index]) : null)
      .whereType<double>()
      .toList();

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  HistoryValueRange? _firstRange(List<HistoryLogEntry> logs, int index) {
    for (final log in logs) {
      final range = log.ranges[index];
      if (range != null) return range;
    }
    return null;
  }

  String _status(double value, HistoryValueRange? range) {
    if (range == null) return 'No range configured';
    if (value < range.minimum || value > range.maximum) return 'Out of range';
    return 'In range';
  }

  double? _parseValue(String value) {
    final numeric = value.trim().split(RegExp(r'\s+')).first;
    return double.tryParse(numeric);
  }

  String _shortDate(String value) {
    final parts = value.split(' ');
    if (parts.length < 2) return value;
    final month = switch (parts.first) {
      'January' => 'Jan',
      'February' => 'Feb',
      'March' => 'Mar',
      'April' => 'Apr',
      'May' => 'May',
      'June' => 'Jun',
      'July' => 'Jul',
      'August' => 'Aug',
      'September' => 'Sep',
      'October' => 'Oct',
      'November' => 'Nov',
      'December' => 'Dec',
      _ => parts.first,
    };
    return '$month ${parts[1].replaceAll(',', '')}';
  }
}
=======
import '../models/reports_models.dart';

class ReportsService {
  /// Fetch summary card metrics
  Future<ReportSummaryData> getSummaryData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const ReportSummaryData(
      avgPh: 6.2,
      phStatus: 'In range',
      avgEc: 5.7,
      ecStatus: 'Stable',
      avgTemp: 24.5,
      tempStatus: 'In range',
      criticalAlertsCount: 3,
      alertsPeriod: 'This month',
    );
  }

  /// Fetch graph points matching trend curve
  Future<List<AnalyticsPoint>> getTrendData(
      String parameter, String timeframe) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      AnalyticsPoint(label: 'Jul 1', value: 6.4),
      AnalyticsPoint(label: 'Jul 5', value: 6.6),
      AnalyticsPoint(label: 'Jul 9', value: 6.9),
      AnalyticsPoint(label: 'Jul 13', value: 6.6),
      AnalyticsPoint(label: 'Jul 17', value: 6.2),
      AnalyticsPoint(label: 'Jul 21', value: 6.1),
      AnalyticsPoint(label: 'Jul 25', value: 6.5),
      AnalyticsPoint(label: 'Jul 29', value: 6.2),
    ];
  }

  /// Fetch actual vs predicted values for model evaluation
  Future<List<PredictedAnalyticsPoint>> getPredictionData(
      String parameter) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
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
  }

  /// Fetch target distribution percentage breakdown
  Future<TargetDistributionData> getTargetDistribution() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const TargetDistributionData(
      optimalPercentage: 88,
      warningPercentage: 8,
      criticalPercentage: 4,
    );
  }

  /// Fetch alert frequency by category
  Future<List<AlertFrequencyData>> getAlertFrequency() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      AlertFrequencyData(category: 'pH Drift', count: 5),
      AlertFrequencyData(category: 'EC Spike', count: 2),
      AlertFrequencyData(category: 'Humidity', count: 1),
      AlertFrequencyData(category: 'Offline', count: 1),
    ];
  }

  /// Fetch sensor calibration health status
  Future<List<SensorHealthItem>> getSensorHealth() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
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
  }
}
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
