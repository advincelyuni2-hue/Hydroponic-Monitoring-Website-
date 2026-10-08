import '../models/reports_models.dart';
import '../utils/manila_time.dart';
import 'supabase_client.dart';

/// Compares forecasts saved when they were generated with the sensor reading
/// recorded at their target time. This avoids evaluating a fresh prediction
/// against old data and keeps intervention-affected samples identifiable.
class ModelEvaluationService {
  static const String modelName = String.fromEnvironment(
    'FORECAST_MODEL_NAME',
    defaultValue: 'Forecast model',
  );

  Future<ModelEvaluation> evaluate({int horizonHours = 12}) async {
    Future<dynamic> loadRows(String columns) => supabase
        .from('forecast_prediction_evaluations')
        .select(columns)
        .eq('horizon_hours', horizonHours)
        .order('target_at', ascending: false)
        .limit(500);

    const baseColumns =
        'parameter, horizon_hours, predicted_value, actual_value, '
        'target_at, evaluation_status, model_version, intervention_count';
    dynamic rows;
    try {
      rows = await loadRows('$baseColumns, intervention_action_type, '
          'intervention_performed_at');
    } catch (_) {
      // Older deployments may not yet have the action-detail view columns.
      rows = await loadRows(baseColumns);
    }

    var pendingCount = 0;
    var evaluatedCount = 0;
    var intervenedCount = 0;
    var missingActualCount = 0;
    var storedModelName = modelName;
    final samplesByTarget = <String, _MutableEvaluationSample>{};
    final records = <ForecastEvaluationRecord>[];

    for (final raw in (rows as List).cast<Map<String, dynamic>>()) {
      final status = raw['evaluation_status']?.toString() ?? 'pending';
      if (status == 'evaluated') {
        evaluatedCount++;
      } else if (status == 'intervened') {
        intervenedCount++;
      } else if (status == 'missing_actual') {
        missingActualCount++;
      } else {
        pendingCount++;
      }

      final version = raw['model_version']?.toString().trim();
      if (version != null && version.isNotEmpty) storedModelName = version;

      final predicted = (raw['predicted_value'] as num?)?.toDouble();
      final actual = (raw['actual_value'] as num?)?.toDouble();
      final targetRaw = raw['target_at']?.toString();
      final actionRaw = raw['intervention_performed_at']?.toString();
      if (predicted != null && targetRaw != null) {
        records.add(ForecastEvaluationRecord(
          parameter: raw['parameter']?.toString() ?? '',
          targetLabel: formatManilaDateTime(
            toManilaTime(parseSupabaseTimestamp(targetRaw)),
          ),
          predictedValue: predicted,
          actualValue: actual,
          status: status,
          interventionCount: (raw['intervention_count'] as num?)?.toInt() ?? 0,
          actionType: raw['intervention_action_type']?.toString(),
          actionTimeLabel: actionRaw == null
              ? null
              : formatManilaDateTime(
                  toManilaTime(parseSupabaseTimestamp(actionRaw)),
                ),
        ));
      }

      // Intervention-affected forecasts remain counted, but are excluded from
      // accuracy so a farmer's corrective action is not scored as model error.
      if (status != 'evaluated') continue;
      if (predicted == null || actual == null || targetRaw == null) continue;

      final target = parseSupabaseTimestamp(targetRaw);
      final key = target.toUtc().toIso8601String();
      final sample = samplesByTarget.putIfAbsent(
        key,
        () => _MutableEvaluationSample(
          target: target,
          label: _label(target),
        ),
      );
      if (raw['parameter'] == 'ph') {
        sample.phActual = actual;
        sample.phPredicted = predicted;
      } else if (raw['parameter'] == 'ec') {
        sample.ecActual = actual;
        sample.ecPredicted = predicted;
      }
    }

    final orderedSamples = samplesByTarget.values.toList()
      ..sort((a, b) => a.target.compareTo(b.target));
    final samples = orderedSamples.map((sample) => sample.freeze()).toList();

    return ModelEvaluation(
      samples: samples,
      records: records,
      horizonHours: horizonHours,
      modelName: storedModelName,
      pendingCount: pendingCount,
      evaluatedCount: evaluatedCount,
      intervenedCount: intervenedCount,
      missingActualCount: missingActualCount,
    );
  }

  String _label(DateTime time) {
    final local = toManilaTime(time);
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

class _MutableEvaluationSample {
  final DateTime target;
  final String label;
  double? phActual;
  double? phPredicted;
  double? ecActual;
  double? ecPredicted;

  _MutableEvaluationSample({required this.target, required this.label});

  EvaluationSample freeze() => EvaluationSample(
        label: label,
        phActual: phActual,
        phPredicted: phPredicted,
        ecActual: ecActual,
        ecPredicted: ecPredicted,
      );
}
