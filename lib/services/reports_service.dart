import 'package:flutter/material.dart';

import '../models/monitoring_models.dart';
import '../models/reports_models.dart';
import 'monitoring_service.dart';
import 'supabase_client.dart';

class ReportsService {
  final MonitoringService _monitoringService;
  DateTimeRange? _cachedCollectionRange;
  DateTime? _collectionRangeFetchedAt;
  Future<DateTimeRange?>? _collectionRangeRequest;

  ReportsService({MonitoringService? monitoringService})
      : _monitoringService = monitoringService ?? MonitoringService();

  Future<({RangeValues ph, RangeValues ec})> getParameterRanges() async {
    final row = await supabase
        .from('parameter_configurations')
        .select('ph_min, ph_max, ec_min, ec_max')
        .eq('id', 1)
        .maybeSingle();
    if (row == null) {
      throw StateError('No parameter configuration is available.');
    }

    double readRangeValue(String key) {
      final value = row[key];
      if (value is! num || !value.isFinite) {
        throw StateError('Invalid parameter configuration value: $key.');
      }
      return value.toDouble();
    }

    return (
      ph: RangeValues(readRangeValue('ph_min'), readRangeValue('ph_max')),
      ec: RangeValues(readRangeValue('ec_min'), readRangeValue('ec_max')),
    );
  }

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

    var criticalAlerts = 0;
    try {
      criticalAlerts = (await getAlertStats()).criticalCount;
    } catch (e) {
      debugPrint('Critical alert count failed: $e');
    }

    return ReportSummaryData(
      avgPh: _average(phValues),
      phStatus: _status(_average(phValues), _firstRange(logs, 2)),
      avgEc: _average(ecValues),
      ecStatus: _status(_average(ecValues), _firstRange(logs, 3)),
      avgTemp: _average(tempValues),
      tempStatus: _status(_average(tempValues), _firstRange(logs, 4)),
      criticalAlertsCount: criticalAlerts,
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
    /// Critical alerts from the notifications table (last [days] days).
  Future<AlertStats> getAlertStats({int days = 30}) async {
    final since = DateTime.now()
        .toUtc()
        .subtract(Duration(days: days))
        .toIso8601String();
    final rows = await supabase
        .from('notifications')
        .select()
        .gte('created_at', since)
        .order('created_at', ascending: false)
        .limit(1000);

    final counts = <String, int>{'pH': 0, 'EC': 0, 'Temperature': 0, 'Other': 0};
    var critical = 0;
    var active = 0;
    var resolved = 0;

    for (final row in rows) {
      final type = (row['type'] ?? '').toString().toLowerCase();
      final text = '${row['title'] ?? ''} ${row['message'] ?? ''}'.toLowerCase();
      if (type != 'critical' && !text.contains('critical')) continue;

      critical++;
      if (row['is_resolved'] == true) {
        resolved++;
      } else {
        active++;
      }
      final category = _alertCategory(row['parameter']) ??
          _alertCategory(row['title']) ??
          _alertCategory(row['message']) ??
          'Other';
      counts[category] = (counts[category] ?? 0) + 1;
    }

    return AlertStats(
      criticalCount: critical,
      activeCount: active,
      resolvedCount: resolved,
      byCategory: [
        for (final entry in counts.entries)
          if (entry.key != 'Other' || entry.value > 0)
            AlertFrequencyData(category: entry.key, count: entry.value),
      ],
    );
  }

  String? _alertCategory(dynamic value) {
    final text = (value ?? '').toString().toLowerCase();
    if (text.trim().isEmpty) return null;
    if (RegExp(r'\bp\s*h\b').hasMatch(text)) return 'pH';
    if (RegExp(r'\bec\b').hasMatch(text)) return 'EC';
    if (text.contains('temperature') || RegExp(r'\btemp\b').hasMatch(text)) {
      return 'Temperature';
    }
    return null;
  }

  /// Sensor calibration status from the calibration_logs table.
  Future<List<SensorHealthItem>> getSensorHealth() async {
    final rows = await supabase
        .from('calibration_logs')
        .select('recorded_at, parameter, status')
        .order('recorded_at', ascending: false)
        .limit(500);
    final now = DateTime.now().toUtc();
    return [
      _healthFor('pH Probe', 'ph', rows, now),
      _healthFor('EC Sensor', 'ec', rows, now),
      _healthFor('Temperature Sensor', 'temp', rows, now),
    ];
  }

  SensorHealthItem _healthFor(
    String name,
    String key,
    List<Map<String, dynamic>> rows,
    DateTime now,
  ) {
    Map<String, dynamic>? latest;
    for (final row in rows) {
      final parameter = (row['parameter'] ?? '').toString().toLowerCase();
      final matches = switch (key) {
        'temp' => parameter.contains('temp'),
        'ec' => parameter.contains('ec') || parameter.contains('conductiv'),
        _ => parameter.contains('ph'),
      };
      if (matches) {
        latest = row; // rows are newest first
        break;
      }
    }

    final when = latest == null
        ? null
        : DateTime.tryParse('${latest['recorded_at']}')?.toUtc();
    if (latest == null || when == null) {
      return SensorHealthItem(
        sensorName: name,
        daysSinceCalibration: -1,
        healthPercentage: 0,
        statusLabel: 'No records',
      );
    }

    final days = now.difference(when).inDays;
    var health = (100 - days * 100 / 30).round().clamp(0, 100);
    var label = days <= 14 ? 'Good' : (days <= 30 ? 'Due soon' : 'Overdue');
    final status = (latest['status'] ?? '').toString().toLowerCase();
    if (status.contains('fail')) {
      health = health > 40 ? 40 : health;
      label = 'Last cal failed';
    }
    return SensorHealthItem(
      sensorName: name,
      daysSinceCalibration: days,
      healthPercentage: health,
      statusLabel: label,
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
