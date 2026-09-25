import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monitoring_models.dart';
import 'notification_service.dart';
import 'supabase_client.dart';

class MonitoringService {
  SupabaseClient get _client {
    final client = supabaseClient;
    if (client == null) {
      throw StateError('Supabase is not configured');
    }
    return client;
  }

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

  Future<List<ParameterStatus>> getParameterStatuses() async {
    final config = await _client
        .from('parameter_configurations')
        .select('ph_min, ph_max, ec_min, ec_max')
        .eq('id', 1)
        .maybeSingle();

    final phMin = (config?['ph_min'] as num?)?.toDouble() ?? 5.5;
    final phMax = (config?['ph_max'] as num?)?.toDouble() ?? 6.5;
    final ecMin = (config?['ec_min'] as num?)?.toDouble() ?? 1.2;
    final ecMax = (config?['ec_max'] as num?)?.toDouble() ?? 1.8;

    final readings = await Future.wait([
      _latestReading('ph_readings'),
      _latestReading('ec_readings'),
      _latestReading('temp_readings'),
    ]);

    final phStatus = _statusFromReading(
      label: 'pH Level',
      row: readings[0],
      unit: '',
      min: phMin,
      max: phMax,
      decimals: 2,
    );

    final ecStatus = _statusFromReading(
      label: 'EC Level',
      row: readings[1],
      unit: 'mS/cm',
      min: ecMin,
      max: ecMax,
      decimals: 2,
    );

    final tempStatus = _statusFromReading(
      label: 'Temperature',
      row: readings[2],
      unit: '°C',
      min: 18.0,
      max: 28.0,
      decimals: 1,
    );

    _checkAndTriggerThresholdAlerts(
        phStatus, ecStatus, tempStatus, phMin, phMax, ecMin, ecMax);

    return [phStatus, ecStatus, tempStatus];
  }

  void _checkAndTriggerThresholdAlerts(
    ParameterStatus ph,
    ParameterStatus ec,
    ParameterStatus temp,
    double phMin,
    double phMax,
    double ecMin,
    double ecMax,
  ) {
    double? phVal = double.tryParse(ph.currentValue);
    if (phVal != null) {
      _notificationService.evaluateAndCreateAlert(
        parameter: 'pH',
        currentValue: phVal,
        minIdeal: phMin,
        maxIdeal: phMax,
        unit: '',
        recommendation: phVal > phMax
            ? '3.5 mL of pH down solution gradually, followed by verification.'
            : 'Add pH up solution gradually.',
      );
    }

    double? ecVal = double.tryParse(ec.currentValue);
    if (ecVal != null) {
      _notificationService.evaluateAndCreateAlert(
        parameter: 'EC',
        currentValue: ecVal,
        minIdeal: ecMin,
        maxIdeal: ecMax,
        unit: 'mS/cm',
        recommendation: ecVal < ecMin
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
        maxIdeal: 28.0,
        unit: '°C',
        recommendation:
            'High water temperature may reduce oxygen absorption; check circulation fans.',
      );
    }
  }

  Future<Map<String, dynamic>?> _latestReading(String table) async {
    final rows = await _client
        .from(table)
        .select('value, recorded_at, status')
        .order('recorded_at', ascending: false)
        .limit(1);

    return rows.isEmpty ? null : rows.first;
  }

  ParameterStatus _statusFromReading({
    required String label,
    required Map<String, dynamic>? row,
    required String unit,
    required double min,
    required double max,
    required int decimals,
  }) {
    final value = (row?['value'] as num?)?.toDouble();
    final recordedAt = row?['recorded_at'] as String?;
    final status = value == null
        ? 'No data'
        : (value < min || value > max
            ? 'Critical'
            : (row?['status'] as String? ?? 'Normal'));

    return ParameterStatus(
      label: label,
      currentValue: value?.toStringAsFixed(decimals) ?? '-',
      unit: unit,
      idealRange:
          '${min.toStringAsFixed(decimals)} - ${max.toStringAsFixed(decimals)}',
      lastUpdated: recordedAt == null
          ? 'No data'
          : _formatTime(DateTime.parse(recordedAt).toLocal()),
      status: status,
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
  }

  RealtimeChannel subscribeToParameterChanges(void Function() onChange) {
    return _client
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
      _client.removeChannel(channel);

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

    final summaries = <int, _HistorySummary>{};
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
        summary.temp == null
            ? '-'
            : '${summary.temp!.toStringAsFixed(1)} °C',
        summary.status,
      ]);
    }).toList();
  }

  Future<void> deleteHistoryLogs({
    required DateTime start,
    required DateTime end,
  }) async {
    for (final table in ['ph_readings', 'ec_readings', 'temp_readings']) {
      await _client
          .from(table)
          .delete()
          .eq('is_average', true)
          .gte('recorded_at', start.toUtc().toIso8601String())
          .lt('recorded_at', end.toUtc().toIso8601String());
    }
  }

  Future<List<HistoryLogEntry>> getCalibrationHistory({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _client
        .from('calibration_logs')
        .select(
            'recorded_at, parameter, calibration_type, adjustment, performed_by, status')
        .gte('recorded_at', start.toUtc().toIso8601String())
        .lt('recorded_at', end.toUtc().toIso8601String())
        .order('recorded_at', ascending: false);

    return rows
        .map<HistoryLogEntry>((row) => HistoryLogEntry([
              _formatTime(
                  DateTime.parse(row['recorded_at'] as String).toLocal()),
              row['parameter'] as String? ?? 'Unknown',
              row['calibration_type'] as String? ?? 'Calibration',
              row['adjustment'] as String? ?? '',
              row['performed_by'] as String? ?? 'Unknown',
              row['status'] as String? ?? 'Completed',
            ]))
        .toList();
  }

  Future<void> deleteCalibrationLogs({
    required DateTime start,
    required DateTime end,
  }) async {
    await _client
        .from('calibration_logs')
        .delete()
        .gte('recorded_at', start.toUtc().toIso8601String())
        .lt('recorded_at', end.toUtc().toIso8601String());
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
      final page = await _client
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
    Map<int, _HistorySummary> summaries,
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
        () => _HistorySummary(bucket),
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
        return '${bucket.month}/${bucket.day} ${_formatTime(bucket)}';
      case HistoryAggregation.eightHours:
        final end = bucket.add(const Duration(hours: 8));
        return '${bucket.month}/${bucket.day} ${_formatTime(bucket)} ${_formatTime(end)}';
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
          'December',
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
}

class _HistorySummary {
  _HistorySummary(this.recordedAt);
  final DateTime recordedAt;
  double? ph;
  double? ec;
  double? temp;
  final List<String> _statuses = [];

  void add({required String parameter, required double value, String? status}) {
    switch (parameter) {
      case 'ph':
        ph = value;
        break;
      case 'ec':
        ec = value;
        break;
      case 'temp':
        temp = value;
        break;
    }
    if (status != null) _statuses.add(status);
  }

  String get status {
    if (_statuses.contains('Critical')) return 'Critical';
    if (_statuses.contains('Warning')) return 'Warning';
    if (_statuses.isNotEmpty) return _statuses.first;
    return 'Normal';
  }
}