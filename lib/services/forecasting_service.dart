import 'dart:convert';
import 'app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/forecasting_models.dart';
import 'supabase_client.dart';
import '../utils/manila_time.dart';

/// The model service rejected its own sensor baseline. This does not prove
/// that the app's independently fetched realtime sensor feed is offline.
class ForecastBaselineUnavailableException implements Exception {
  final DateTime? modelLastRecordedAt;
  const ForecastBaselineUnavailableException({this.modelLastRecordedAt});

  String get message {
    final lastSeen = modelLastRecordedAt == null
        ? 'The model did not report a last reading.'
        : 'Model last received '
            '${formatManilaDateTime(toManilaTime(modelLastRecordedAt!))}.';
    return 'The model service cannot find a recent sensor reading. $lastSeen '
        'Check that the website and model use the same Supabase project '
        'and that the model server clock is correct.';
  }
}

class ForecastEndpointUnavailableException implements Exception {
  final String message;
  const ForecastEndpointUnavailableException(this.message);
}

class ForecastingService {
  static const String backendApiUrl = String.fromEnvironment(
    'FORECAST_API_URL',
    defaultValue: 'http://127.0.0.1:8000/api/predict/forecast',
  );

  Future<List<ForecastingChartPoint>> getForecastChartData(
    String parameter, {
    required int selectedHours,
    double currentPh = 6.5,
    double currentEc = 1.5,
    double currentTemp = 24.0,
  }) async {
    final deployedWeb =
        kIsWeb && Uri.base.host != 'localhost' && Uri.base.host != '127.0.0.1';
    final endpoint = Uri.parse(backendApiUrl);
    if (deployedWeb &&
        (endpoint.host == 'localhost' || endpoint.host == '127.0.0.1')) {
      throw const ForecastEndpointUnavailableException(
        'The deployed website is still configured to call localhost. '
        'Rebuild it with FORECAST_API_URL set to the public HTTPS model endpoint.',
      );
    }
    if (deployedWeb &&
        Uri.base.scheme == 'https' &&
        endpoint.scheme != 'https') {
      throw const ForecastEndpointUnavailableException(
        'The deployed website uses HTTPS but FORECAST_API_URL does not. '
        'Rebuild it with the public HTTPS model endpoint.',
      );
    }

    final chartPoints = <ForecastingChartPoint>[];
    final requestTime = DateTime.now().toUtc();
    final baselineVal = parameter == 'ph' ? currentPh : currentEc;

    try {
      final valueColumn = parameter == 'ph' ? 'avg_ph' : 'avg_ec';
      final cutoff = requestTime
          .subtract(Duration(hours: selectedHours))
          .subtract(sensorStoredUtcCorrection);

      final response = await supabase
          .from('sensor_history')
          .select('$valueColumn, recorded_at')
          .gte('recorded_at', cutoff.toIso8601String())
          .order('recorded_at', ascending: false)
          .limit(500);

      final rows = List<Map<String, dynamic>>.from(response).reversed.toList();

      for (final row in rows) {
        final recordedAt = DateTime.parse(row['recorded_at'] as String)
            .toUtc()
            .add(sensorStoredUtcCorrection);
        final hoursAgo = recordedAt.difference(requestTime).inSeconds / 3600.0;

        chartPoints.add(
          ForecastingChartPoint(
            hour: hoursAgo,
            value: (row[valueColumn] as num).toDouble(),
            isPredicted: false,
          ),
        );
      }

      _ensureHistoricalBaseline(
        chartPoints,
        selectedHours,
        baselineVal,
      );

      final uri = endpoint.replace(queryParameters: {
        'parameter': parameter.toLowerCase(),
        'ph': currentPh.toString(),
        'ec': currentEc.toString(),
        'temp': currentTemp.toString(),
        'horizon': selectedHours.toString(),
      });

      final apiResponse =
          await http.get(uri).timeout(Duration(seconds: deployedWeb ? 45 : 10));

      if (apiResponse.statusCode == 200) {
        final data = json.decode(apiResponse.body);
        final List predictions = data['predictions'];

        for (final prediction in predictions) {
          chartPoints.add(
            ForecastingChartPoint(
              hour: (prediction['hour'] as num).toDouble(),
              value: (prediction['value'] as num).toDouble(),
              isPredicted: true,
            ),
          );
        }

        return chartPoints;
      }

      if (apiResponse.statusCode == 409) {
        DateTime? lastRecordedAt;
        var modelSensorOffline = false;
        try {
          final body = json.decode(apiResponse.body) as Map<String, dynamic>;
          final detail = body['detail'];
          if (detail is Map && detail['code'] == 'sensor_offline') {
            modelSensorOffline = true;
            lastRecordedAt = DateTime.tryParse('${detail['last_recorded_at']}');
          }
        } catch (_) {}
        if (modelSensorOffline) {
          throw ForecastBaselineUnavailableException(
            modelLastRecordedAt: lastRecordedAt,
          );
        }
      }

      if (apiResponse.statusCode == 503) {
        try {
          final body = json.decode(apiResponse.body) as Map<String, dynamic>;
          final detail = body['detail'];
          if (detail is Map &&
              detail['code'] == 'model_database_unconfigured') {
            throw const ForecastEndpointUnavailableException(
              'The model server is missing SUPABASE_SERVICE_ROLE_KEY. '
              'Set it in the backend environment and redeploy the model service.',
            );
          }
        } on ForecastEndpointUnavailableException {
          rethrow;
        } catch (_) {}
      }

      if (deployedWeb) {
        throw ForecastEndpointUnavailableException(
          'The forecast service returned HTTP ${apiResponse.statusCode}. '
          'Check its /api/predict/forecast endpoint and Supabase connection.',
        );
      }

      return _withFallbackPredictions(
        chartPoints,
        selectedHours,
        baselineVal,
      );
    } on ForecastBaselineUnavailableException {
      rethrow;
    } on ForecastEndpointUnavailableException {
      rethrow;
    } catch (_) {
      if (deployedWeb) {
        throw const ForecastEndpointUnavailableException(
          'The deployed website could not load a model forecast. '
          'Check the public HTTPS FORECAST_API_URL and backend logs.',
        );
      }
      return _withFallbackPredictions(
        chartPoints,
        selectedHours,
        baselineVal,
      );
    }
  }

  /// Checks if an intervention was applied or dismissed recently
  Future<String?> checkRecentIntervention(
      String parameter, int horizonHours) async {
    try {
      final cutoff = DateTime.now()
          .toUtc()
          .subtract(Duration(hours: horizonHours))
          .toIso8601String();

      final actionLog = await supabase
          .from('action_logs')
          .select('id, created_at')
          .eq('parameter', parameter)
          .gte('created_at', cutoff)
          .limit(1);

      if (actionLog.isNotEmpty) return 'applied';

      final dismissedLog = await supabase
          .from('dismissed_action_logs')
          .select('id, created_at')
          .eq('parameter', parameter)
          .gte('created_at', cutoff)
          .limit(1);

      if (dismissedLog.isNotEmpty) return 'dismissed';
    } catch (_) {}
    return null;
  }

  Future<PredictionInsightDetail> getPredictionInsight(
    String parameter, {
    double currentPh = 6.5,
    double currentEc = 1.5,
    double currentTemp = 24.0,
    double? predictedPh,
    double? predictedEc,
    int horizonHours = 12,
  }) async {
    final recentIntervention =
        await checkRecentIntervention(parameter, horizonHours);

    if (recentIntervention != null) {
      final isPh = parameter == 'ph';
      final isApplied = recentIntervention == 'applied';
      return PredictionInsightDetail(
        statusLabel: isPh ? 'pH Level' : 'EC Level',
        statusBadge: 'Stable',
        warningText: isPh
            ? 'pH levels are stable and within optimal bounds.'
            : 'EC levels are stable and within safe parameters.',
        temperature: '${currentTemp.toStringAsFixed(1)} °C',
        ecLevel: isPh
            ? '${currentEc.toStringAsFixed(1)} mS/cm'
            : '${currentPh.toStringAsFixed(1)} pH',
        calloutText: isApplied
            ? 'Recent intervention logged: parameter fix applied successfully.'
            : 'Insight dismissed by operator.',
        currentPh: isPh ? currentPh : currentEc,
        targetPh: isPh ? 6.5 : 1.5,
        suggestedFixes: const ['No recommendation for now'],
      );
    }

    final insight = runFlutterDSS(
      parameter: parameter,
      currentPh: currentPh,
      currentEc: currentEc,
      currentTemp: currentTemp,
      predictedPh: predictedPh ?? currentPh,
      predictedEc: predictedEc ?? currentEc,
    );

    await saveForecastToSupabase(insight, parameter);
    return insight;
  }

  PredictionInsightDetail runFlutterDSS({
    required String parameter,
    required double currentPh,
    required double currentEc,
    required double currentTemp,
    required double predictedPh,
    required double predictedEc,
  }) {
    bool isPh = parameter == 'ph';
    final cfg = appParameterRanges.value;

    bool isPhCriticalHigh = predictedPh >= 8.0 || currentPh >= 8.0;
    bool isPhCriticalLow = predictedPh <= 5.0 || currentPh <= 5.0;
    bool isPhWarningHigh = predictedPh > cfg.phMax && !isPhCriticalHigh;
    bool isPhWarningLow = predictedPh < cfg.phMin && !isPhCriticalLow;

    bool isEcCriticalLow = predictedEc <= 0.8 || currentEc <= 0.8;
    bool isEcCriticalHigh = predictedEc >= 2.2 || currentEc >= 2.2;
    bool isEcWarningLow = predictedEc < cfg.ecMin && !isEcCriticalLow;
    bool isEcWarningHigh = predictedEc > cfg.ecMax && !isEcCriticalHigh;

    double targetPh = (cfg.phMin + cfg.phMax) / 2;
    double targetEc = (cfg.ecMin + cfg.ecMax) / 2;

    String statusBadge = 'Stable';
    String warningText = '';
    List<String> fixes = [];

    if (isPh) {
      if (isPhCriticalHigh || (isPhWarningHigh && isEcCriticalLow)) {
        statusBadge = 'Critical';
        warningText =
            'pH level is critically elevated outside safe operating limits.';
        fixes = [
          'Immediate action required: Add appropriate pH-down dosing solution.',
          'Flush or re-balance nutrient solution if pH remains above 8.0.',
          'Verify sensor calibration before secondary adjustments.',
        ];
      } else if (isPhCriticalLow) {
        statusBadge = 'Critical';
        warningText = 'pH level has dropped to a critical low threshold.';
        fixes = [
          'Immediate action required: Add appropriate pH-up solution gradually.',
          'Check root zone health and re-verify probe reading.',
        ];
      } else if (isPhWarningHigh && isEcWarningLow) {
        statusBadge = 'Warning';
        warningText = 'pH is predicted high while EC is predicted low.';
        fixes = [
          'Correct pH condition using an appropriate pH-down solution.',
          'Review nutrient concentration before nutrient replenishment.',
        ];
      } else if (isPhWarningHigh) {
        statusBadge = 'Warning';
        warningText =
            'pH is expected to rise above safe levels within horizon.';
        double phDiff = (predictedPh - targetPh).abs();
        double suggestedMl = (phDiff * 10).clamp(1.0, 15.0);
        fixes = [
          'Apply ${suggestedMl.toStringAsFixed(1)} mL of pH-down solution gradually.',
          'Verify with sensor measurement after application.',
        ];
      } else if (isPhWarningLow) {
        statusBadge = 'Warning';
        warningText = 'pH is expected to drop below optimal bounds.';
        fixes = [
          'Gradual pH increase using an appropriate pH-up solution.',
          'Verify through sensor measurement.',
        ];
      } else {
        statusBadge = 'Stable';
        warningText = 'pH levels are predicted to remain stable.';
        fixes = ['No recommendation for now'];
      }
    } else {
      if (isEcCriticalLow || (isEcWarningLow && isPhCriticalHigh)) {
        statusBadge = 'Critical';
        warningText =
            'EC level is critically low; severe nutrient depletion detected.';
        fixes = [
          'Immediate action required: Replenish concentrated nutrient solution.',
          'Check stock solution reservoirs and dosing pumps.',
          'Re-verify pH stability after nutrient dosage.',
        ];
      } else if (isEcCriticalHigh) {
        statusBadge = 'Critical';
        warningText = 'EC level is critically high; risk of nutrient burn.';
        fixes = [
          'Immediate action required: Dilute reservoir with fresh water.',
          'Inspect system for high evaporation rates.',
        ];
      } else if (isEcWarningLow && isPhWarningHigh) {
        statusBadge = 'Warning';
        warningText = 'EC is predicted low while pH is predicted high.';
        fixes = [
          'Inspect nutrient solution strength and replenish nutrients.',
          'Reassess pH condition after nutrient replenishment.',
        ];
      } else if (isEcWarningHigh) {
        statusBadge = 'Warning';
        warningText = 'EC level is predicted above ideal concentration.';
        fixes = [
          'Dilute solution with fresh water to normalize EC concentration.',
          'Verify EC through sensor measurement.',
        ];
      } else if (isEcWarningLow) {
        statusBadge = 'Warning';
        warningText = 'EC level is expected to drop below ideal concentration.';
        fixes = [
          'Inspect nutrient solution strength.',
          'Replenish nutrients according to standard procedure.',
        ];
      } else {
        statusBadge = 'Stable';
        warningText = 'EC levels are stable and within safe parameters.';
        fixes = ['No recommendation for now'];
      }
    }

    String calloutText = '';
    if (currentTemp > 25.0 && (isPhCriticalHigh || isPhWarningHigh)) {
      calloutText =
          'High temperature (${currentTemp.toStringAsFixed(1)} °C) is accelerating chemical drift, pushing pH higher.';
    } else if (currentTemp > 25.0 && (isEcCriticalHigh || isEcWarningHigh)) {
      calloutText =
          'High temperature (${currentTemp.toStringAsFixed(1)} °C) is increasing evaporation rates, raising EC concentration.';
    } else if (isEcCriticalLow || isEcWarningLow) {
      calloutText =
          'Active root uptake of mineral salts has depleted EC below optimal levels.';
    } else {
      calloutText =
          'Parameters are operating within balanced environmental thresholds.';
    }

    return PredictionInsightDetail(
      statusLabel: isPh ? 'pH Level' : 'EC Level',
      statusBadge: statusBadge,
      warningText: warningText,
      temperature: '${currentTemp.toStringAsFixed(1)} °C',
      ecLevel: isPh
          ? '${currentEc.toStringAsFixed(1)} mS/cm'
          : '${currentPh.toStringAsFixed(1)} pH',
      calloutText: calloutText,
      currentPh: isPh ? currentPh : currentEc,
      targetPh: isPh ? targetPh : targetEc,
      suggestedFixes: fixes,
    );
  }

  Future<void> saveActionLog({
    required String parameter,
    required String forecastCondition,
    required int horizonHours,
    required double currentPh,
    required double currentEc,
    required double currentTemp,
    required List<String> suggestedFixes,
  }) async {
    try {
      await supabase.from('action_logs').insert({
        'parameter': parameter,
        'forecast_condition': forecastCondition,
        'horizon_hours': horizonHours,
        'current_ph': currentPh,
        'current_ec': currentEc,
        'current_temp': currentTemp,
        'suggested_fixes': suggestedFixes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> saveDismissedActionLog({
    required String parameter,
    required String forecastCondition,
    required int horizonHours,
    required double currentPh,
    required double currentEc,
    required double currentTemp,
    required List<String> suggestedFixes,
  }) async {
    try {
      await supabase.from('dismissed_action_logs').insert({
        'parameter': parameter,
        'forecast_condition': forecastCondition,
        'horizon_hours': horizonHours,
        'current_ph': currentPh,
        'current_ec': currentEc,
        'current_temp': currentTemp,
        'suggested_fixes': suggestedFixes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> saveForecastToSupabase(
    PredictionInsightDetail insight,
    String parameter,
  ) async {
    try {
      await supabase.from('forecast_logs').insert({
        'parameter': parameter,
        'status_badge': insight.statusBadge,
        'warning_text': insight.warningText,
        'temperature': insight.temperature,
        'ec_level': insight.ecLevel,
        'callout_text': insight.calloutText,
        'current_val': insight.currentPh,
        'target_val': insight.targetPh,
        'suggested_fixes': insight.suggestedFixes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  List<ForecastingChartPoint> _withFallbackPredictions(
    List<ForecastingChartPoint> actualPoints,
    int hours,
    double baselineVal,
  ) {
    final points = [...actualPoints];
    _ensureHistoricalBaseline(points, hours, baselineVal);
    final step = hours / 3.0;

    return [
      ...points,
      ForecastingChartPoint(
        hour: step,
        value: baselineVal + 0.1,
        isPredicted: true,
      ),
      ForecastingChartPoint(
        hour: step * 2,
        value: baselineVal + 0.2,
        isPredicted: true,
      ),
      ForecastingChartPoint(
        hour: hours.toDouble(),
        value: baselineVal + 0.3,
        isPredicted: true,
      ),
    ];
  }

  void _ensureHistoricalBaseline(
    List<ForecastingChartPoint> points,
    int hours,
    double baselineVal,
  ) {
    if (points.any((point) => !point.isPredicted)) return;

    for (var offset = -hours; offset <= 0; offset++) {
      points.add(
        ForecastingChartPoint(
          hour: offset.toDouble(),
          value: baselineVal,
          isPredicted: false,
          isFallback: true,
        ),
      );
    }
  }
}
