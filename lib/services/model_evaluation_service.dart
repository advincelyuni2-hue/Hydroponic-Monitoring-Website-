import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/reports_models.dart';
import '../utils/manila_time.dart';
import 'forecasting_service.dart';
import 'supabase_client.dart';

/// The ONE place where the Reports screen connects to the forecast model.
/// It calls the same endpoint as the Forecasting screen
/// (ForecastingService.backendApiUrl, set with --dart-define FORECAST_API_URL).
/// When a new model is deployed behind that URL, nothing here has to change.
/// Optionally set --dart-define=FORECAST_MODEL_NAME=... to show its name.
class ModelEvaluationService {
  static const String modelName = String.fromEnvironment(
    'FORECAST_MODEL_NAME',
    defaultValue: 'Forecast model',
  );

  static const int sampleCount = 8; // how many past moments are tested
  static const Duration _tolerance = Duration(minutes: 45);

  Future<ModelEvaluation> evaluate({int horizonHours = 12}) async {
    final readings = await Future.wait([
      _loadReadings('ph_readings'),
      _loadReadings('ec_readings'),
      _loadReadings('temp_readings'),
    ]);
    final ph = readings[0];
    final ec = readings[1];
    final temp = readings[2];

    if (ph.isEmpty || ec.isEmpty) {
      return ModelEvaluation(
        samples: const [],
        horizonHours: horizonHours,
        modelName: modelName,
      );
    }

    final latest = ph.first.time;
    final jobs = <Future<EvaluationSample?>>[];

    for (var i = sampleCount; i >= 1; i--) {
      final testTime = latest.subtract(Duration(hours: horizonHours * i));
      final targetTime = testTime.add(Duration(hours: horizonHours));

      jobs.add(
        _evaluateOne(
          testTime,
          targetTime,
          ph,
          ec,
          temp,
          horizonHours,
        ),
      );
    }

    final results = await Future.wait(jobs);

    return ModelEvaluation(
      samples: results.whereType<EvaluationSample>().toList(),
      horizonHours: horizonHours,
      modelName: modelName,
    );
  }

  Future<EvaluationSample?> _evaluateOne(
    DateTime testTime,
    DateTime targetTime,
    List<_Reading> ph,
    List<_Reading> ec,
    List<_Reading> temp,
    int horizonHours,
  ) async {
    final phNow = _nearest(ph, testTime);
    final ecNow = _nearest(ec, testTime);
    if (phNow == null || ecNow == null) return null;

    final tempNow = _nearest(temp, testTime)?.value ?? 24.0;

    final phThen = _nearest(ph, targetTime);
    final ecThen = _nearest(ec, targetTime);
    if (phThen == null && ecThen == null) return null;

    final predicted = await Future.wait([
      _predict('ph', phNow.value, ecNow.value, tempNow, horizonHours),
      _predict('ec', phNow.value, ecNow.value, tempNow, horizonHours),
    ]);

    if (predicted[0] == null && predicted[1] == null) return null;

    return EvaluationSample(
      label: _label(targetTime),
      phActual: phThen?.value,
      phPredicted: predicted[0],
      ecActual: ecThen?.value,
      ecPredicted: predicted[1],
    );
  }

  /// Same request the Forecasting screen makes.
  Future<double?> _predict(
    String parameter,
    double ph,
    double ec,
    double temp,
    int horizonHours,
  ) async {
    try {
      final uri = Uri.parse(ForecastingService.backendApiUrl).replace(
        queryParameters: {
          'parameter': parameter,
          'ph': ph.toString(),
          'ec': ec.toString(),
          'temp': temp.toString(),
          'horizon': horizonHours.toString(),
        },
      );

      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) return null;

      final body = json.decode(response.body) as Map<String, dynamic>;

      if (body['error_fallback'] != null) {
        debugPrint('Model returned a fallback: ${body['error_fallback']}');
        return null;
      }

      final raw = body['predictions'] as List;
      final predictions =
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (predictions.isEmpty) return null;

      predictions.sort(
        (a, b) => ((a['hour'] as num) - horizonHours)
            .abs()
            .compareTo(((b['hour'] as num) - horizonHours).abs()),
      );

      return (predictions.first['value'] as num).toDouble();
    } catch (_) {
      return null;
    }
  }

  Future<List<_Reading>> _loadReadings(String table) async {
    final rows = await supabase
        .from(table)
        .select('value, recorded_at')
        .eq('is_average', false)
        .order('recorded_at', ascending: false)
        .limit(1000);
    return [
      for (final row in rows)
        if (row['value'] is num && row['recorded_at'] is String)
          _Reading(
            parseSupabaseTimestamp(row['recorded_at'] as String),
            (row['value'] as num).toDouble(),
          ),
    ];
  }

  _Reading? _nearest(List<_Reading> readings, DateTime target) {
    _Reading? best;
    var bestGap = _tolerance;
    for (final reading in readings) {
      final gap = reading.time.difference(target).abs();
      if (gap <= bestGap) {
        best = reading;
        bestGap = gap;
      }
    }
    return best;
  }

  String _label(DateTime time) {
    final local = toSensorManilaTime(time);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '${months[local.month - 1]} ${local.day}, '
        '$hour ${local.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _Reading {
  final DateTime time;
  final double value;
  const _Reading(this.time, this.value);
}
