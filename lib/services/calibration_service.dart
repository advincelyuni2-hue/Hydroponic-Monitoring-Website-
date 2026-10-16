import 'package:supabase_flutter/supabase_flutter.dart';

class CalibrationSample {
  final int id;
  final DateTime recordedAt;
  final double voltage;

  const CalibrationSample(this.id, this.recordedAt, this.voltage);

  factory CalibrationSample.fromJson(Map<String, dynamic> row) =>
      CalibrationSample(
        (row['id'] as num).toInt(),
        DateTime.parse(row['recorded_at'] as String),
        (row['voltage'] as num).toDouble(),
      );
}

class CalibrationStability {
  final bool stable;
  final String reason;
  final double? averageVoltage;
  final double? voltageRange;
  final int sampleCount;

  const CalibrationStability({
    required this.stable,
    required this.reason,
    this.averageVoltage,
    this.voltageRange,
    required this.sampleCount,
  });

  /// Engineering starting limits, not a manufacturer tolerance. Verify these
  /// against the installed ESP32 ADC and probe before relying on auto-capture.
  static CalibrationStability evaluate(
    List<CalibrationSample> samples, {
    required String parameter,
  }) {
    final window =
        samples.length > 6 ? samples.sublist(samples.length - 6) : samples;
    if (window.length < 6) {
      return CalibrationStability(
        stable: false,
        reason: 'Collecting ${window.length}/6 readings',
        sampleCount: window.length,
      );
    }
    final elapsed = window.last.recordedAt.difference(window.first.recordedAt);
    if (elapsed < const Duration(seconds: 45)) {
      return CalibrationStability(
        stable: false,
        reason: 'Waiting for at least 45 seconds of readings',
        sampleCount: window.length,
      );
    }
    final values = window.map((sample) => sample.voltage).toList();
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final variation = high - low;
    final limit = parameter == 'ph' ? 0.012 : 0.020;
    return CalibrationStability(
      stable: variation <= limit,
      reason: variation <= limit
          ? 'Stable; confirm the probe is in the labelled solution'
          : 'Still settling (${variation.toStringAsFixed(3)} V variation)',
      averageVoltage: values.reduce((a, b) => a + b) / values.length,
      voltageRange: variation,
      sampleCount: window.length,
    );
  }
}

class CalibrationSession {
  final String id;
  final String parameter;
  final String operatorName;
  final String createdBy;

  const CalibrationSession({
    required this.id,
    required this.parameter,
    required this.operatorName,
    required this.createdBy,
  });

  factory CalibrationSession.fromJson(Map<String, dynamic> row) =>
      CalibrationSession(
        id: row['id'] as String,
        parameter: row['parameter'] as String,
        operatorName: row['operator_name'] as String,
        createdBy: row['created_by'] as String,
      );
}

class CalibrationService {
  CalibrationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<CalibrationSession?> activeSession() async {
    final state = await _client
        .from('calibration_device_state')
        .select('active_session_id')
        .eq('device_id', 'hydroponic-esp32')
        .single();
    final id = state['active_session_id'] as String?;
    if (id == null) return null;
    final row = await _client
        .from('calibration_sessions')
        .select('id, parameter, operator_name, created_by')
        .eq('id', id)
        .single();
    return CalibrationSession.fromJson(row);
  }

  Future<CalibrationSession> start(String parameter) async {
    final id = await _client.rpc('begin_calibration', params: {
      'target_parameter': parameter,
    }) as String;
    final row = await _client
        .from('calibration_sessions')
        .select('id, parameter, operator_name, created_by')
        .eq('id', id)
        .single();
    return CalibrationSession.fromJson(row);
  }

  Future<List<CalibrationSample>> latestSamples(String sessionId) async {
    final rows = await _client
        .from('calibration_samples')
        .select('id, recorded_at, voltage')
        .eq('session_id', sessionId)
        .order('id', ascending: false)
        .limit(15);
    return rows
        .map((row) => CalibrationSample.fromJson(row))
        .toList()
        .reversed
        .toList();
  }

  Future<Map<String, Map<String, dynamic>>> points(String sessionId) async {
    final rows = await _client
        .from('calibration_points')
        .select('standard_label, voltage, captured_at')
        .eq('session_id', sessionId);
    return {
      for (final row in rows) row['standard_label'] as String: row,
    };
  }

  Future<void> capture({
    required CalibrationSession session,
    required String label,
    required double expectedValue,
    required String expectedUnit,
    required CalibrationStability stability,
    double? solutionTemperatureC,
  }) async {
    if (!stability.stable || stability.averageVoltage == null) {
      throw StateError(
          'Wait for a stable reading before capturing this point.');
    }
    await _client.from('calibration_points').insert({
      'session_id': session.id,
      'standard_label': label,
      'expected_value': expectedValue,
      'expected_unit': expectedUnit,
      'voltage': stability.averageVoltage,
      'voltage_range': stability.voltageRange,
      'sample_count': stability.sampleCount,
      'solution_temperature_c': solutionTemperatureC,
    });
  }

  Future<void> finish(String sessionId) => _client.rpc(
        'finish_calibration',
        params: {'session_id_value': sessionId},
      );

  Future<bool> latestCoefficientApplied() async {
    final state = await _client
        .from('calibration_device_state')
        .select('coefficients_version, applied_version')
        .eq('device_id', 'hydroponic-esp32')
        .single();
    return (state['coefficients_version'] as num).toInt() ==
        (state['applied_version'] as num).toInt();
  }

  Future<void> cancel(String sessionId) => _client.rpc(
        'cancel_calibration',
        params: {'session_id_value': sessionId},
      );
}
