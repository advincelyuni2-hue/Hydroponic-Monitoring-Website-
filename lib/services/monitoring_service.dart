import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monitoring_models.dart';
import 'notification_service.dart';
import 'supabase_client.dart';

enum HistoryAggregation { tenMinutes, eightHours, daily }

class MonitoringService {
  final NotificationService _notificationService = NotificationService();

  static const List<String> sensorLogColumns = [
    'Time',
    'Parameter',
    'Recorded Value',
    'Status',
    'Action Taken',
  ];

  static const List<String> calibrationLogColumns = [
    'Time',
    'Parameter',
    'Calibration Type',
    'Adjustment',
    'Performed By',
    'Status',
  ];

  /// Powers the "Parameter Status" cards and evaluates active thresholds
  Future<List<ParameterStatus>> getParameterStatuses() async {
    final readings = await Future.wait([
      _getLatestReading('ph_readings'),
      _getLatestReading('ec_readings'),
      _getLatestReading('temp_readings'),
    ]);

    final phStatus = _toParameterStatus('pH Level', readings[0], '', '5.5 - 6.5');
    final ecStatus = _toParameterStatus('EC Level', readings[1], 'mS/cm', '1.2 - 1.8');
    final tempStatus = _toParameterStatus('Temperature', readings[2], '°C', '18.0 - 24.0');

    // Auto-evaluate thresholds and create database alert entries if breached
    _checkAndTriggerThresholdAlerts(phStatus, ecStatus, tempStatus);

    return [phStatus, ecStatus, tempStatus];
  }

  void _checkAndTriggerThresholdAlerts(
    ParameterStatus ph,
    ParameterStatus ec,
    ParameterStatus temp,
  ) {
    double? phVal = double.tryParse(ph.currentValue);
    if (phVal != null) {
      _notificationService.evaluateAndCreateAlert(
        parameter: 'pH',
        currentValue: phVal,
        minIdeal: 5.5,
        maxIdeal: 6.5,
        unit: '',
        recommendation: phVal > 6.5
            ? '3.5 mL of pH down solution gradually, followed by verification.'
            : 'Add pH up solution gradually.',
      );
    }

    double? ecVal = double.tryParse(ec.currentValue);
    if (ecVal != null) {
      _notificationService.evaluateAndCreateAlert(
        parameter: 'EC',
        currentValue: ecVal,
        minIdeal: 1.2,
        maxIdeal: 1.8,
        unit: 'mS/cm',
        recommendation: ecVal < 1.2
            ? '1.0 mL of A and B nutrient solution replenishment.'
            : 'Evaluate water dilution to normalize concentration.',
      );
    }

    double? tempVal = double.tryParse(temp.currentValue);
    if (tempVal != null) {
      _notificationService.evaluateAndCreateAlert(
        parameter: 'Temperature',
        currentValue: tempVal,
        minIdeal: 18.0,
        maxIdeal: 24.0,
        unit: '°C',
        recommendation:
            'High water temperature may reduce oxygen absorption; check circulation fans.',
      );
    }
  }

  /// Helper method for manual testing in browser / UI
  Future<void> testTriggerAlert({
    required String parameter,
    required double testValue,
    required String recommendation,
  }) async {
    double minIdeal = parameter == 'pH'
        ? 5.5
        : (parameter == 'EC' ? 1.2 : 18.0);
    double maxIdeal = parameter == 'pH'
        ? 6.5
        : (parameter == 'EC' ? 1.8 : 24.0);
    String unit = parameter == 'pH'
        ? ''
        : (parameter == 'EC' ? 'mS/cm' : '°C');

    await _notificationService.evaluateAndCreateAlert(
      parameter: parameter,
      currentValue: testValue,
      minIdeal: minIdeal,
      maxIdeal: maxIdeal,
      unit: unit,
      recommendation: recommendation,
    );
  }

  Future<Map<String, dynamic>> _getLatestReading(String table) async {
    final rows = await supabase
        .from(table)
        .select('value, recorded_at')
        .eq('is_average', false)
        .order('recorded_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      throw StateError('No non-average readings found in $table');
    }
    return rows.first;
  }

  ParameterStatus _toParameterStatus(
    String label,
    Map<String, dynamic> row,
    String unit,
    String idealRange,
  ) {
    final value = (row['value'] as num).toDouble();
    final timestamp = DateTime.parse(row['recorded_at'] as String).toLocal();

    return ParameterStatus(
      label: label,
      currentValue: value.toStringAsFixed(label == 'pH Level' ? 2 : 1),
      unit: unit,
      idealRange: idealRange,
      lastUpdated: formatTime(timestamp),
    );
  }

  String formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
  }

  RealtimeChannel subscribeToParameterChanges(void Function() onChange) {
    return supabase
        .channel('dashboard-parameter-readings')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'ph_readings',
          filter: const PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'is_average',
            value: false,
          ),
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'ec_readings',
          filter: const PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'is_average',
            value: false,
          ),
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'temp_readings',
          filter: const PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'is_average',
            value: false,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) =>
      supabase.removeChannel(channel);

  Future<List<HistoryLogEntry>> getSensorHistory({
    required DateTime start,
    required DateTime end,
    required HistoryAggregation aggregation,
  }) async {
    final results = await Future.wait([
      _getAverageReadings('ph_readings', start, end),
      _getAverageReadings('ec_readings', start, end),
      _getAverageReadings('temp_readings', start, end),
    ]);

    final summaries = <int, HistorySummary>{};
    _mergeAverageRows(summaries, results[0], 'ph', aggregation);
    _mergeAverageRows(summaries, results[1], 'ec', aggregation);
    _mergeAverageRows(summaries, results[2], 'temp', aggregation);

    final ordered = summaries.values.toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return ordered.map((summary) {
      return HistoryLogEntry([
        _historyLabel(summary.recordedAt, aggregation),
        summary.ph?.toStringAsFixed(2) ?? '-',
        summary.ec == null ? '-' : '${summary.ec!.toStringAsFixed(2)} mS/cm',
        summary.temp == null ? '-' : '${summary.temp!.toStringAsFixed(1)} °C',
        summary.status,
      ]);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getAverageReadings(
    String table,
    DateTime start,
    DateTime end,
  ) async {
    const pageSize = 1000;
    final allRows = <Map<String, dynamic>>[];
    var from = 0;

    while (true) {
      final page = await supabase
          .from(table)
          .select('value, recorded_at, status')
          .eq('is_average', true)
          .gte('recorded_at', start.toUtc().toIso8601String())
          .lt('recorded_at', end.toUtc().toIso8601String())
          .order('recorded_at', ascending: true)
          .range(from, from + pageSize - 1);

      allRows.addAll(page);
      if (page.length < pageSize) break;
      from += pageSize;
    }

    return allRows;
  }

  void _mergeAverageRows(
    Map<int, HistorySummary> summaries,
    List<Map<String, dynamic>> rows,
    String parameter,
    HistoryAggregation aggregation,
  ) {
    for (final row in rows) {
      final timestamp =
          DateTime.parse(row['recorded_at'] as String).toLocal();
      final bucket = _historyBucket(timestamp, aggregation);
      final bucketKey = bucket.millisecondsSinceEpoch;

      final summary = summaries.putIfAbsent(
        bucketKey,
        () => HistorySummary(bucket),
      );

      summary.add(
        parameter: parameter,
        value: (row['value'] as num).toDouble(),
        status: row['status'] as String?,
      );
    }
  }

  DateTime _historyBucket(
    DateTime timestamp,
    HistoryAggregation aggregation,
  ) {
    switch (aggregation) {
      case HistoryAggregation.tenMinutes:
        return DateTime(
          timestamp.year,
          timestamp.month,
          timestamp.day,
          timestamp.hour,
          timestamp.minute,
        );
      case HistoryAggregation.eightHours:
        return DateTime(
          timestamp.year,
          timestamp.month,
          timestamp.day,
          (timestamp.hour ~/ 8) * 8,
        );
      case HistoryAggregation.daily:
        return DateTime(timestamp.year, timestamp.month, timestamp.day);
    }
  }

  String _historyLabel(
    DateTime bucket,
    HistoryAggregation aggregation,
  ) {
    switch (aggregation) {
      case HistoryAggregation.tenMinutes:
        return '${bucket.month}/${bucket.day} ${formatTime(bucket)}';
      case HistoryAggregation.eightHours:
        final end = bucket.add(const Duration(hours: 8));
        return '${bucket.month}/${bucket.day} ${formatTime(bucket)} - ${formatTime(end)}';
      case HistoryAggregation.daily:
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        return '${months[bucket.month - 1]} ${bucket.day}, ${bucket.year}';
    }
  }

  Future<LatestInsight> getLatestInsight() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return LatestInsight(
      warningTitle: 'pH Drift Warning',
      warningDetail: 'pH will drop below 5.5',
      expectedIn: 'Expected in 45 min',
      humidity: '78%',
      ecStatus: 'Stable',
    );
  }

  Future<List<ForecastPoint>> getForecastData(String parameter) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (parameter == 'ph') {
      return [
        ForecastPoint(hour: -12, value: 7.2, isPredicted: false),
        ForecastPoint(hour: -8, value: 7.2, isPredicted: false),
        ForecastPoint(hour: -4, value: 6.9, isPredicted: false),
        ForecastPoint(hour: 0, value: 6.9, isPredicted: false),
        ForecastPoint(hour: 4, value: 6.9, isPredicted: true),
        ForecastPoint(hour: 8, value: 6.5, isPredicted: true),
        ForecastPoint(hour: 12, value: 6.5, isPredicted: true),
      ];
    }
    return [
      ForecastPoint(hour: -12, value: 6.0, isPredicted: false),
      ForecastPoint(hour: -8, value: 6.0, isPredicted: false),
      ForecastPoint(hour: -4, value: 5.7, isPredicted: false),
      ForecastPoint(hour: 0, value: 5.7, isPredicted: false),
      ForecastPoint(hour: 4, value: 5.7, isPredicted: true),
      ForecastPoint(hour: 8, value: 5.4, isPredicted: true),
      ForecastPoint(hour: 12, value: 5.4, isPredicted: true),
    ];
  }

  Future<PredictionInsightDetail> getPredictionInsight(String parameter) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (parameter == 'ph') {
      return PredictionInsightDetail(
        statusLabel: 'pH Level',
        statusBadge: 'Warning',
        warningText: 'pH is expected to rise above safe levels in 45 minutes.',
        airHumidity: '75%',
        ecLevel: '5.8 mS/cm',
        calloutText:
            'High humidity is slowing evaporation, letting dissolved solids build up and push pH higher.',
        currentPh: 6.9,
        targetPh: 6.5,
        suggestedFixes: [
          '4.5 ml of pH down solution',
          '0.5 ml of A and B nutrient concentrate'
        ],
      );
    }
    return PredictionInsightDetail(
      statusLabel: 'EC Level',
      statusBadge: 'Normal',
      warningText: 'EC levels are stable and within the ideal range.',
      airHumidity: '75%',
      ecLevel: '5.8 mS/cm',
      calloutText:
          'Nutrient concentration has remained steady over the last 12 hours.',
      currentPh: 5.8,
      targetPh: 6.0,
      suggestedFixes: ['No action needed right now.'],
    );
  }

  Future<List<HistoryLogEntry>> getSensorLogs() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      const HistoryLogEntry(['8:00 AM', 'pH', '6.5', 'Stable', 'Add pH up solution']),
      const HistoryLogEntry(['7:45 AM', 'EC', '5.8 mS/cm', 'Stable', 'None']),
      const HistoryLogEntry(['7:30 AM', 'Temperature', '24.6 °C', 'Stable', 'None']),
      const HistoryLogEntry(['7:15 AM', 'pH', '6.3', 'Warning', 'Monitor closely']),
      const HistoryLogEntry(['7:00 AM', 'EC', '5.9 mS/cm', 'Stable', 'None']),
      const HistoryLogEntry(['6:45 AM', 'Temperature', '26.8 °C', 'Critical', 'Alert sent to admin']),
      const HistoryLogEntry(['6:30 AM', 'pH', '6.6', 'Stable', 'None']),
      const HistoryLogEntry(['6:15 AM', 'EC', '5.7 mS/cm', 'Stable', 'None']),
    ];
  }

  Future<List<HistoryLogEntry>> getCalibrationLogs() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      const HistoryLogEntry(['8:00 AM', 'pH', '2-Point Calibration', '+0.2', 'Auto-system', 'Success']),
      const HistoryLogEntry(['Yesterday, 6:00 PM', 'EC', '1-Point Calibration', '-0.1 mS/cm', 'Alveus', 'Success']),
      const HistoryLogEntry(['2 days ago, 8:00 AM', 'Temperature', 'Sensor Reset', '0.0 °C', 'Auto-system', 'Success']),
      const HistoryLogEntry(['3 days ago, 8:00 AM', 'pH', '2-Point Calibration', '+0.1', 'Auto-system', 'Failed']),
    ];
  }
}

class HistorySummary {
  final DateTime recordedAt;
  double _phTotal = 0;
  int _phCount = 0;
  double _ecTotal = 0;
  int _ecCount = 0;
  double _tempTotal = 0;
  int _tempCount = 0;
  String status = 'Stable';

  HistorySummary(this.recordedAt);

  double? get ph => _phCount == 0 ? null : _phTotal / _phCount;
  double? get ec => _ecCount == 0 ? null : _ecTotal / _ecCount;
  double? get temp => _tempCount == 0 ? null : _tempTotal / _tempCount;

  void add({
    required String parameter,
    required double value,
    required String? status,
  }) {
    if (parameter == 'ph') {
      _phTotal += value;
      _phCount++;
    } else if (parameter == 'ec') {
      _ecTotal += value;
      _ecCount++;
    } else if (parameter == 'temp') {
      _tempTotal += value;
      _tempCount++;
    }

    if (_severity(status) > _severity(this.status)) {
      this.status = status!;
    }
  }

  int _severity(String? value) {
    switch (value?.toLowerCase()) {
      case 'critical':
        return 3;
      case 'warning':
        return 2;
      case 'stable':
      case 'normal':
        return 1;
      default:
        return 0;
    }
  }
}