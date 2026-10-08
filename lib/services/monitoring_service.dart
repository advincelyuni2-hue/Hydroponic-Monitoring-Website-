import '../models/monitoring_models.dart';
import 'app_state.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../utils/manila_time.dart';
import '../utils/parameter_severity.dart';
import '../utils/sensor_value_format.dart';

enum HistoryAggregation { fiveMinutes, eightHours, daily }

class MonitoringService {
  static const Duration sensorOfflineAfter = Duration(minutes: 10);

  static bool isSensorReadingOffline(
    DateTime? latestRecordedAt, {
    DateTime? now,
  }) {
    if (latestRecordedAt == null) return true;
    return (now ?? DateTime.now().toUtc())
            .toUtc()
            .difference(latestRecordedAt.toUtc()) >
        sensorOfflineAfter;
  }

  /// Column headers for the "Sensor logs" tab on the History Logs screen.
  static const List<String> sensorLogColumns = [
    'Time',
    'Parameter',
    'Recorded Value',
    'Status',
    'Action Taken',
  ];

  static const List<String> interventionLogColumns = [
    'Date',
    'Time',
    'Parameter',
    'Action taken',
    'Amount',
    'Notes',
    'Source',
  ];

  Future<List<HistoryLogEntry>> getInterventionHistory({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await supabase
        .from('action_logs')
        .select('performed_at, parameter, action_type, amount, amount_unit, '
            'notes, source')
        .inFilter('source', ['notification_fix', 'manual_fix'])
        .gte('performed_at', manilaWallTimeToUtc(start).toIso8601String())
        .lt('performed_at', manilaWallTimeToUtc(end).toIso8601String())
        .order('performed_at', ascending: false);

    return rows.map<HistoryLogEntry>(interventionEntryFromRow).toList();
  }

  static HistoryLogEntry interventionEntryFromRow(Map<String, dynamic> row) {
    final recordedAt = parseSupabaseTimestamp(row['performed_at'].toString());
    final local = toManilaTime(recordedAt);
    final date = formatManilaDateTime(local).split(', ').take(2).join(', ');
    final action = row['action_type']?.toString().trim();
    final amount = row['amount'];
    final amountText = amount == null
        ? '—'
        : '$amount ${row['amount_unit']?.toString() ?? 'mL'}';
    final notes = row['notes']?.toString().trim();
    return HistoryLogEntry([
      date,
      formatManilaClockTime(local),
      row['parameter']?.toString() ?? '—',
      action == null || action.isEmpty ? '—' : action,
      amountText,
      notes == null || notes.isEmpty ? '—' : notes,
      row['source'] == 'notification_fix' ? 'Notification' : 'Manual',
    ]);
  }

  /// Column headers for the "Calibration logs" tab. Different shape from
  /// Sensor logs — a calibration event records what was adjusted and who
  /// performed it, not a raw reading.
  static const List<String> calibrationLogColumns = [
    'Time',
    'Parameter',
    'Calibration Type',
    'Adjustment',
    'Performed By',
    'Status',
  ];

  /// Powers the "Parameter Status" cards (pH / EC / Temperature).
  Future<List<ParameterStatus>> getParameterStatuses() async {
    return (await getTelemetrySnapshot()).statuses;
  }

  Future<TelemetrySnapshot> getTelemetrySnapshot() async {
    final ranges = await _getParameterRanges();
    final reading = await _getLatestFiveMinuteReadingOrNull();
    if (reading == null) {
      return TelemetrySnapshot(
        statuses: _offlineStatuses(ranges, null),
        latestRecordedAt: null,
        isOffline: true,
      );
    }

    final timestampUtc =
        parseSupabaseTimestamp(reading['recorded_at'] as String).toUtc();
    final isOffline = isSensorReadingOffline(timestampUtc);
    final timestamp = toManilaTime(timestampUtc);

    if (isOffline) {
      return TelemetrySnapshot(
        statuses: _offlineStatuses(ranges, timestampUtc),
        latestRecordedAt: timestampUtc,
        isOffline: true,
      );
    }

    final statuses = [
      _toParameterStatus(
        'pH Level',
        (reading['avg_ph'] as num).toDouble(),
        timestamp,
        '',
        ranges.phMin,
        ranges.phMax,
        0.5,
        sensorValueDecimalPlaces,
      ),
      _toParameterStatus(
        'EC Level',
        (reading['avg_ec'] as num).toDouble(),
        timestamp,
        'mS/cm',
        ranges.ecMin,
        ranges.ecMax,
        0.5,
        sensorValueDecimalPlaces,
      ),
      _toParameterStatus(
        'Temperature',
        (reading['avg_temp'] as num).toDouble(),
        timestamp,
        '°C',
        18.0,
        24.0,
        5.0,
        1,
      ),
    ];
    return TelemetrySnapshot(
      statuses: statuses,
      latestRecordedAt: timestampUtc,
      isOffline: false,
    );
  }

  Future<_ParameterRanges> _getParameterRanges() async {
    try {
      final row = await supabase
          .from('parameter_configurations')
          .select('ph_min, ph_max, ec_min, ec_max')
          .eq('id', 1)
          .maybeSingle();
      if (row != null) {
        final loaded = _ParameterRanges(
          phMin: (row['ph_min'] as num?)?.toDouble() ?? 5.5,
          phMax: (row['ph_max'] as num?)?.toDouble() ?? 6.5,
          ecMin: (row['ec_min'] as num?)?.toDouble() ?? 1.2,
          ecMax: (row['ec_max'] as num?)?.toDouble() ?? 1.8,
        );
        appParameterRanges.value = ParameterRangeConfig(
          phMin: loaded.phMin,
          phMax: loaded.phMax,
          ecMin: loaded.ecMin,
          ecMax: loaded.ecMax,
        );
        return loaded;
      }
    } catch (_) {
      // Older deployments may not have the admin configuration table yet.
    }
    return const _ParameterRanges();
  }

  Future<Map<String, dynamic>?> _getLatestFiveMinuteReadingOrNull() async {
    final rows = await supabase
        .from('sensor_history')
        .select('id, avg_ph, avg_ec, avg_temp, recorded_at')
        .order('recorded_at', ascending: false)
        .limit(1);

    return rows.isEmpty ? null : rows.first;
  }

  List<ParameterStatus> _offlineStatuses(
    _ParameterRanges ranges,
    DateTime? latestRecordedAt,
  ) {
    final lastUpdated = latestRecordedAt == null
        ? 'No sensor data received'
        : formatManilaDateTime(toManilaTime(latestRecordedAt));

    ParameterStatus offline(
      String label,
      String unit,
      double minimum,
      double maximum,
      int decimals,
    ) {
      return ParameterStatus(
        label: label,
        currentValue: 'No data',
        unit: unit,
        idealRange:
            '${minimum.toStringAsFixed(decimals)} - ${maximum.toStringAsFixed(decimals)}',
        lastUpdated: lastUpdated,
        status: 'Offline',
        isOffline: true,
        latestRecordedAt: latestRecordedAt,
      );
    }

    return [
      offline(
          'pH Level', '', ranges.phMin, ranges.phMax, sensorValueDecimalPlaces),
      offline('EC Level', 'mS/cm', ranges.ecMin, ranges.ecMax,
          sensorValueDecimalPlaces),
      offline('Temperature', '°C', 18, 24, 1),
    ];
  }

  ParameterStatus _toParameterStatus(
    String label,
    double value,
    DateTime timestamp,
    String unit,
    double minimum,
    double maximum,
    double warningMargin,
    int decimals,
  ) {
    return ParameterStatus(
      label: label,
      currentValue: value.toStringAsFixed(decimals),
      unit: unit,
      idealRange:
          '${minimum.toStringAsFixed(decimals)} - ${maximum.toStringAsFixed(decimals)}',
      lastUpdated: formatManilaDateTime(timestamp),
      status: _severityLabel(value, minimum, maximum, warningMargin),
      latestRecordedAt: manilaWallTimeToUtc(timestamp),
    );
  }

  String _severityLabel(
    double value,
    double minimum,
    double maximum,
    double warningMargin,
  ) {
    return parameterSeverityLabel(
      classifyParameterValue(
        value: value,
        stableMin: minimum,
        stableMax: maximum,
        warningMargin: warningMargin,
      ),
    );
  }

  RealtimeChannel subscribeToParameterChanges(void Function() onChange) {
    return supabase
        .channel('dashboard-parameter-readings')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'sensor_history',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) =>
      supabase.removeChannel(channel);

  Future<DateTimeRange?> getSensorCollectionDateRange() async {
    final boundaries = await Future.wait([
      _getReadingBoundary(ascending: true),
      _getReadingBoundary(ascending: false),
    ]);
    if (boundaries[0] == null || boundaries[1] == null) return null;
    return DateTimeRange(start: boundaries[0]!, end: boundaries[1]!);
  }

  Future<DateTime?> _getReadingBoundary({required bool ascending}) async {
    final rows = await supabase
        .from('sensor_history')
        .select('recorded_at')
        .order('recorded_at', ascending: ascending)
        .limit(1);
    if (rows.isEmpty) return null;
    return toManilaTime(
      parseSupabaseTimestamp(rows.first['recorded_at'] as String),
    );
  }

  Future<List<HistoryLogEntry>> getSensorHistory({
    required DateTime start,
    required DateTime end,
    required HistoryAggregation aggregation,
  }) async {
    final results = await _getFiveMinuteHistory(start, end);
    final ranges = await _getParameterRanges();

    final summaries = <int, _HistorySummary>{};
    for (final row in results) {
      final timestamp = toManilaTime(
        parseSupabaseTimestamp(row['recorded_at'] as String),
      );
      final bucket = _historyBucket(timestamp, aggregation);
      final summary = summaries.putIfAbsent(
        bucket.millisecondsSinceEpoch,
        () => _HistorySummary(bucket),
      );
      summary.addSnapshot(
        ph: (row['avg_ph'] as num).toDouble(),
        ec: (row['avg_ec'] as num).toDouble(),
        temp: (row['avg_temp'] as num).toDouble(),
      );
    }

    final ordered = summaries.values.toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return ordered.map((summary) {
      final phRange = HistoryValueRange(
        minimum: ranges.phMin,
        maximum: ranges.phMax,
        value: summary.ph,
        warningMargin: 0.5,
      );
      final ecRange = HistoryValueRange(
        minimum: ranges.ecMin,
        maximum: ranges.ecMax,
        value: summary.ec,
        unit: 'mS/cm',
        warningMargin: 0.5,
      );
      final tempRange = HistoryValueRange(
        minimum: 18,
        maximum: 24,
        value: summary.temp,
        unit: '°C',
        warningMargin: 5,
      );
      final statuses = [
        _severityLabel(summary.ph!, ranges.phMin, ranges.phMax, 0.5),
        _severityLabel(summary.ec!, ranges.ecMin, ranges.ecMax, 0.5),
        _severityLabel(summary.temp!, 18, 24, 5),
      ];
      final overallStatus = statuses.contains('Critical')
          ? 'Critical'
          : statuses.contains('Warning')
              ? 'Warning'
              : 'Stable';
      return HistoryLogEntry(
        [
          _historyDate(summary.recordedAt),
          _historyTime(summary.recordedAt, aggregation),
          summary.ph == null ? '—' : formatSensorValue(summary.ph!),
          summary.ec == null ? '—' : '${formatSensorValue(summary.ec!)} mS/cm',
          summary.temp == null ? '—' : '${summary.temp!.toStringAsFixed(1)} °C',
          overallStatus,
        ],
        ranges: {
          2: phRange,
          3: ecRange,
          4: tempRange,
        },
        recordStart: summary.recordedAt,
        recordDuration: switch (aggregation) {
          HistoryAggregation.fiveMinutes => const Duration(minutes: 5),
          HistoryAggregation.eightHours => const Duration(hours: 8),
          HistoryAggregation.daily => const Duration(days: 1),
        },
      );
    }).toList();
  }

  Future<List<HistoryLogEntry>> getCalibrationHistory({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await supabase
        .from('calibration_logs')
        .select(
          'recorded_at, parameter, calibration_type, adjustment, performed_by, status',
        )
        .gte('recorded_at', manilaWallTimeToUtc(start).toIso8601String())
        .lt('recorded_at', manilaWallTimeToUtc(end).toIso8601String())
        .order('recorded_at', ascending: false);
    return rows.map<HistoryLogEntry>((row) {
      final recordedAt = toManilaTime(
        parseSupabaseTimestamp(row['recorded_at'] as String),
      );
      return HistoryLogEntry([
        '${_historyDate(recordedAt)} ${formatManilaClockTime(recordedAt)}',
        row['parameter'] as String? ?? 'Unknown',
        row['calibration_type'] as String? ?? 'Calibration',
        row['adjustment'] as String? ?? '',
        row['performed_by'] as String? ?? 'Unknown',
        row['status'] as String? ?? 'Completed',
      ], recordStart: recordedAt);
    }).toList();
  }

  Future<void> deleteHistoryLogs({
    required DateTime start,
    required DateTime end,
  }) async {
    await supabase
        .from('sensor_history')
        .delete()
        .gte('recorded_at', manilaWallTimeToUtc(start).toIso8601String())
        .lt('recorded_at', manilaWallTimeToUtc(end).toIso8601String());
  }

  Future<void> deleteSingleSensorHistoryBucket({
    required DateTime start,
    required DateTime end,
  }) async {
    final storedStart =
        sensorManilaWallTimeToStoredUtc(start).toIso8601String();
    final storedEnd = sensorManilaWallTimeToStoredUtc(end).toIso8601String();

    final results = await Future.wait([
      supabase
          .from('ph_readings')
          .delete()
          .eq('is_average', true)
          .gte('recorded_at', storedStart)
          .lt('recorded_at', storedEnd)
          .select('recorded_at'),
      supabase
          .from('ec_readings')
          .delete()
          .eq('is_average', true)
          .gte('recorded_at', storedStart)
          .lt('recorded_at', storedEnd)
          .select('recorded_at'),
      supabase
          .from('temp_readings')
          .delete()
          .eq('is_average', true)
          .gte('recorded_at', storedStart)
          .lt('recorded_at', storedEnd)
          .select('recorded_at'),
    ]);

    if (results.every((deletedRows) => deletedRows.isEmpty)) {
      throw StateError('No sensor history records matched the selected entry.');
    }
  }

  Future<void> deleteCalibrationLogs({
    required DateTime start,
    required DateTime end,
  }) async {
    await supabase
        .from('calibration_logs')
        .delete()
        .gte('recorded_at', manilaWallTimeToUtc(start).toIso8601String())
        .lt('recorded_at', manilaWallTimeToUtc(end).toIso8601String());
  }

  Future<void> deleteCalibrationLog(DateTime recordedAt) async {
    final deletedRows = await supabase
        .from('calibration_logs')
        .delete()
        .eq(
          'recorded_at',
          manilaWallTimeToUtc(recordedAt).toIso8601String(),
        )
        .select('recorded_at');

    if (deletedRows.isEmpty) {
      throw StateError('No calibration log matched the selected entry.');
    }
  }

  Future<void> updateSensorHistoryBucket({
    required DateTime start,
    required DateTime end,
    required double ph,
    required double ec,
    required double temperature,
  }) async {
    final results = await supabase
        .from('sensor_history')
        .update({
          'avg_ph': ph,
          'median_ph': ph,
          'min_ph': ph,
          'max_ph': ph,
          'latest_ph': ph,
          'std_ph': 0,
          'avg_ec': ec,
          'median_ec': ec,
          'min_ec': ec,
          'max_ec': ec,
          'latest_ec': ec,
          'std_ec': 0,
          'avg_temp': temperature,
          'median_temp': temperature,
          'min_temp': temperature,
          'max_temp': temperature,
          'latest_temp': temperature,
          'std_temp': 0,
        })
        .gte('recorded_at', manilaWallTimeToUtc(start).toIso8601String())
        .lt('recorded_at', manilaWallTimeToUtc(end).toIso8601String())
        .select('recorded_at');
    if (results.isEmpty) {
      throw StateError('No sensor history records matched the selected entry.');
    }
  }

  Future<List<Map<String, dynamic>>> _getFiveMinuteHistory(
    DateTime start,
    DateTime end,
  ) async {
    const pageSize = 1000;
    final allRows = <Map<String, dynamic>>[];
    var from = 0;

    while (true) {
      final page = await supabase
          .from('sensor_history')
          .select('avg_ph, avg_ec, avg_temp, recorded_at')
          .gte(
            'recorded_at',
            manilaWallTimeToUtc(start).toIso8601String(),
          )
          .lt(
            'recorded_at',
            manilaWallTimeToUtc(end).toIso8601String(),
          )
          .order('recorded_at', ascending: true)
          .range(from, from + pageSize - 1);
      allRows.addAll(page);
      if (page.length < pageSize) break;
      from += pageSize;
    }

    return allRows;
  }

  DateTime _historyBucket(
    DateTime timestamp,
    HistoryAggregation aggregation,
  ) {
    switch (aggregation) {
      case HistoryAggregation.fiveMinutes:
        // Each database row is one atomic five-minute ESP32 summary.
        return DateTime(
          timestamp.year,
          timestamp.month,
          timestamp.day,
          timestamp.hour,
          (timestamp.minute ~/ 5) * 5,
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

  String _historyDate(DateTime bucket) {
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

  String _historyTime(
    DateTime bucket,
    HistoryAggregation aggregation,
  ) {
    switch (aggregation) {
      case HistoryAggregation.fiveMinutes:
        return formatManilaClockTime(bucket);
      case HistoryAggregation.eightHours:
        final end = bucket.add(const Duration(hours: 8));
        return '${formatManilaClockTime(bucket)} - '
            '${formatManilaClockTime(end)}';
      case HistoryAggregation.daily:
        return '';
    }
  }

  /// Powers the "Latest Insight" card.
  Future<LatestInsight> getLatestInsight() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: replace with real prediction/insight data (e.g. from an ML
    // model output stored in Supabase, or computed server-side)
    return LatestInsight(
      warningTitle: 'pH Drift Warning',
      warningDetail: 'pH will drop below 5.5',
      expectedIn: 'Expected in 45 min',
      humidity: '78%',
      ecStatus: 'Stable',
    );
  }

  /// Powers the "pH Forecast Overview" / "EC Forecast Overview" charts on
  /// the dashboard, AND the bigger chart on the Forecasting screen —
  /// same method, same data, so both screens can never drift out of sync
  /// with each other.
  /// `parameter` is 'ph' or 'ec'.
  Future<List<ForecastPoint>> getForecastData(String parameter) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // TODO: replace with real historical + predicted data, e.g.:
    //   final past = await supabase.from('readings')...
    //   final predicted = await supabase.from('ml_predictions')...
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

  /// Powers the "Prediction Insights" panel on the Forecasting screen.
  /// `parameter` is 'ph' or 'ec'.
  Future<PredictionInsightDetail> getPredictionInsight(String parameter) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: replace with a real ML/prediction query, e.g.:
    //   final response = await supabase.from('ml_predictions')...
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
          '0.5 ml of A and B nutrient concentrate',
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

  /// Powers the "Sensor logs" tab on the History Logs screen.
  Future<List<HistoryLogEntry>> getSensorLogs() async {
    final today = manilaNow();
    final end = DateTime(today.year, today.month, today.day)
        .add(const Duration(days: 1));
    final start = end.subtract(const Duration(days: 30));
    return getSensorHistory(
      start: start,
      end: end,
      aggregation: HistoryAggregation.daily,
    );
  }

  /// Powers the "Calibration logs" tab on the History Logs screen.
  Future<List<HistoryLogEntry>> getCalibrationLogs() async {
    final response = await supabase
        .from('calibration_logs')
        .select(
          'recorded_at, parameter, calibration_type, adjustment, performed_by, status',
        )
        .order('recorded_at', ascending: false)
        .limit(500);

    return response.map((row) {
      final recordedAt = toManilaTime(
        parseSupabaseTimestamp(row['recorded_at'] as String),
      );
      return HistoryLogEntry([
        '${_historyDate(recordedAt)} ${_historyTime(recordedAt, HistoryAggregation.fiveMinutes)}',
        row['parameter'] as String,
        row['calibration_type'] as String,
        row['adjustment'] as String,
        row['performed_by'] as String,
        row['status'] as String,
      ]);
    }).toList();
  }
}

class _ParameterRanges {
  final double phMin;
  final double phMax;
  final double ecMin;
  final double ecMax;

  const _ParameterRanges({
    this.phMin = 5.5,
    this.phMax = 6.5,
    this.ecMin = 1.2,
    this.ecMax = 1.8,
  });
}

class _HistorySummary {
  final DateTime recordedAt;
  double _phTotal = 0;
  int _phCount = 0;
  double _ecTotal = 0;
  int _ecCount = 0;
  double _tempTotal = 0;
  int _tempCount = 0;
  _HistorySummary(this.recordedAt);

  double? get ph => _phCount == 0 ? null : _phTotal / _phCount;
  double? get ec => _ecCount == 0 ? null : _ecTotal / _ecCount;
  double? get temp => _tempCount == 0 ? null : _tempTotal / _tempCount;

  void addSnapshot({
    required double ph,
    required double ec,
    required double temp,
  }) {
    _phTotal += ph;
    _phCount++;
    _ecTotal += ec;
    _ecCount++;
    _tempTotal += temp;
    _tempCount++;
  }
}
