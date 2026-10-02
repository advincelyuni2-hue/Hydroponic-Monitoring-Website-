import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reports_models.dart';
import 'supabase_client.dart';

class ReportsService {
  Future<PdfReportData> getPdfReportData({
    required DateTime anchorDate,
    required String timeframe,
    required bool includeSensorLogs,
  }) async {
    final rangeDays = switch (timeframe) {
      '7d' => 7,
      '90d' => 90,
      _ => 30,
    };
    final endDate = DateTime(anchorDate.year, anchorDate.month, anchorDate.day)
        .add(const Duration(days: 1));
    final startDate = endDate.subtract(Duration(days: rangeDays));
    final summaryStartDate = endDate.subtract(const Duration(days: 30));
    final generatedAt = DateTime.now();
    final alertStart = DateTime(generatedAt.year, generatedAt.month);
    final alertEnd = DateTime(generatedAt.year, generatedAt.month + 1);

    final client = supabaseClient;
    if (client == null) {
      return PdfReportData(
        startDate: startDate,
        endDate: endDate.subtract(const Duration(days: 1)),
        phReadings: const [],
        ecReadings: const [],
        temperatureReadings: const [],
        phSummaryReadings: const [],
        ecSummaryReadings: const [],
        calibrationLogs: const [],
        phMin: 5.5,
        phMax: 6.5,
        ecMin: 1.2,
        ecMax: 1.8,
        criticalAlertsCount: 0,
      );
    }

    final configurationFuture = client
        .from('parameter_configurations')
        .select('ph_min, ph_max, ec_min, ec_max')
        .eq('id', 1)
        .maybeSingle()
        .then((row) => row);
    final phTrendFuture =
        _fetchReportReadings(client, 'ph_readings', startDate, endDate, 'pH');
    final ecTrendFuture =
        _fetchReportReadings(client, 'ec_readings', startDate, endDate, 'EC');
    final phSummaryFuture = startDate == summaryStartDate
        ? phTrendFuture
        : _fetchReportReadings(
            client, 'ph_readings', summaryStartDate, endDate, 'pH');
    final ecSummaryFuture = startDate == summaryStartDate
        ? ecTrendFuture
        : _fetchReportReadings(
            client, 'ec_readings', summaryStartDate, endDate, 'EC');
    final alertsFuture = client
        .from('notifications')
        .select('message')
        .gte('created_at', alertStart.toUtc().toIso8601String())
        .lt('created_at', alertEnd.toUtc().toIso8601String())
        .then((rows) => rows);
    final temperatureFuture = includeSensorLogs
        ? _fetchReportReadings(
            client, 'temp_readings', startDate, endDate, 'Temperature')
        : Future.value(const <ReportReading>[]);
    final calibrationFuture = _fetchCalibrationLogs(client, startDate, endDate);

    final results = await Future.wait<Object?>([
      configurationFuture,
      phTrendFuture,
      ecTrendFuture,
      phSummaryFuture,
      ecSummaryFuture,
      alertsFuture,
      temperatureFuture,
      calibrationFuture,
    ]);

    final configuration = results[0] as Map<String, dynamic>?;
    final alerts = results[5] as List;
    final criticalAlertsCount = alerts.where((row) {
      final message = (row['message'] as String? ?? '').toLowerCase();
      return message.contains('critical') ||
          (message.contains('outside') && message.contains('range'));
    }).length;

    return PdfReportData(
      startDate: startDate,
      endDate: endDate.subtract(const Duration(days: 1)),
      phReadings: results[1] as List<ReportReading>,
      ecReadings: results[2] as List<ReportReading>,
      phSummaryReadings: results[3] as List<ReportReading>,
      ecSummaryReadings: results[4] as List<ReportReading>,
      temperatureReadings: results[6] as List<ReportReading>,
      calibrationLogs: results[7] as List<ReportCalibrationLog>,
      phMin: (configuration?['ph_min'] as num?)?.toDouble() ?? 5.5,
      phMax: (configuration?['ph_max'] as num?)?.toDouble() ?? 6.5,
      ecMin: (configuration?['ec_min'] as num?)?.toDouble() ?? 1.2,
      ecMax: (configuration?['ec_max'] as num?)?.toDouble() ?? 1.8,
      criticalAlertsCount: criticalAlertsCount,
    );
  }

  Future<List<ReportReading>> _fetchReportReadings(
    SupabaseClient client,
    String table,
    DateTime start,
    DateTime end,
    String parameter,
  ) async {
    const pageSize = 1000;
    final result = <ReportReading>[];
    var offset = 0;
    while (true) {
      final rows = await client
          .from(table)
          .select('value, recorded_at, status')
          .eq('is_average', true)
          .gte('recorded_at', start.toUtc().toIso8601String())
          .lt('recorded_at', end.toUtc().toIso8601String())
          .order('recorded_at', ascending: true)
          .range(offset, offset + pageSize - 1);
      for (final row in rows) {
        final value = row['value'];
        final recordedAt = row['recorded_at'];
        if (value is! num || recordedAt is! String) continue;
        result.add(ReportReading(
          recordedAt: DateTime.parse(recordedAt).toLocal(),
          value: value.toDouble(),
          parameter: parameter,
          status: row['status'] as String? ?? 'Recorded',
        ));
      }
      if (rows.length < pageSize) break;
      offset += pageSize;
    }
    return result;
  }

  Future<List<ReportCalibrationLog>> _fetchCalibrationLogs(
    SupabaseClient client,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await client
        .from('calibration_logs')
        .select(
          'recorded_at, parameter, calibration_type, adjustment, performed_by, status',
        )
        .gte('recorded_at', start.toUtc().toIso8601String())
        .lt('recorded_at', end.toUtc().toIso8601String())
        .order('recorded_at', ascending: true);
    return rows.map<ReportCalibrationLog>((row) {
      return ReportCalibrationLog(
        recordedAt:
            DateTime.parse(row['recorded_at'] as String).toLocal(),
        parameter: row['parameter'] as String? ?? 'Unknown',
        calibrationType:
            row['calibration_type'] as String? ?? 'Calibration',
        adjustment: row['adjustment'] as String? ?? '',
        performedBy: row['performed_by'] as String? ?? 'Unknown',
        status: row['status'] as String? ?? 'Completed',
      );
    }).toList();
  }

  /// Fetch summary card metrics
  Future<ReportSummaryData> getSummaryData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ReportSummaryData(
      avgPh: 6.2,
      phStatus: 'In range',
      avgEc: 5.7,
      ecStatus: 'Stable',
      criticalAlertsCount: 3,
      alertsPeriod: 'This month',
    );
  }

  /// Fetch graph points matching trend curve
  Future<List<AnalyticsPoint>> getTrendData(
      String parameter, String timeframe) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final values = parameter == 'EC'
        ? const [5.4, 5.6, 5.8, 5.5, 5.2, 5.1, 5.5, 5.3]
        : const [6.4, 6.6, 6.9, 6.6, 6.2, 6.1, 6.5, 6.2];
    final points = switch (timeframe) {
      '7d' => 4,
      '90d' => 12,
      _ => 8,
    };
    return List.generate(points, (index) {
      final sourceIndex = index % values.length;
      final day = timeframe == '90d' ? index * 7 + 1 : index * 4 + 1;
      return AnalyticsPoint(
        label: 'Jul $day',
        value: values[sourceIndex] + (index ~/ values.length) * 0.1,
      );
    });
  }

  /// Fetch actual vs predicted values for model evaluation
  Future<List<PredictedAnalyticsPoint>> getPredictionData(
      String parameter) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
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
  Future<TargetDistributionData> getTargetDistribution(
      [String parameter = 'pH']) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return switch (parameter) {
      'EC' => const TargetDistributionData(
          optimalPercentage: 76,
          warningPercentage: 16,
          criticalPercentage: 8,
        ),
      'Air' => const TargetDistributionData(
          optimalPercentage: 68,
          warningPercentage: 22,
          criticalPercentage: 10,
        ),
      _ => const TargetDistributionData(
          optimalPercentage: 88,
          warningPercentage: 8,
          criticalPercentage: 4,
        ),
    };
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
