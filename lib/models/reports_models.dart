class ReportSummaryData {
  final double avgPh;
  final String phStatus;
  final double avgEc;
  final String ecStatus;
  final double avgTemp;
  final String tempStatus;
  final int criticalAlertsCount;
  final String alertsPeriod;

  const ReportSummaryData({
    required this.avgPh,
    required this.phStatus,
    required this.avgEc,
    required this.ecStatus,
    required this.avgTemp,
    required this.tempStatus,
    required this.criticalAlertsCount,
    required this.alertsPeriod,
  });
}

class AnalyticsPoint {
  final String label; // e.g. "Jul 1"
  final double value; // e.g. 6.4
  final String? parameter;

  const AnalyticsPoint({
    required this.label,
    required this.value,
    this.parameter,
  });
}

class PredictedAnalyticsPoint {
  final String label;
  final double actualValue;
  final double predictedValue;

  double get delta => (actualValue - predictedValue).abs();

  const PredictedAnalyticsPoint({
    required this.label,
    required this.actualValue,
    required this.predictedValue,
  });
}

class TargetDistributionData {
  final double optimalPercentage;
  final double warningPercentage;
  final double criticalPercentage;

  const TargetDistributionData({
    required this.optimalPercentage,
    required this.warningPercentage,
    required this.criticalPercentage,
  });
}

class AlertFrequencyData {
  final String category;
  final int count;

  const AlertFrequencyData({
    required this.category,
    required this.count,
  });
}

class SensorHealthItem {
  final String sensorName;
  final int daysSinceCalibration;
  final int healthPercentage;
  final String statusLabel;

  const SensorHealthItem({
    required this.sensorName,
    required this.daysSinceCalibration,
    required this.healthPercentage,
    required this.statusLabel,
  });
}

class AlertStats {
  final int criticalCount;
  final int activeCount;
  final int resolvedCount;
  final List<AlertFrequencyData> byCategory;

  const AlertStats({
    required this.criticalCount,
    required this.activeCount,
    required this.resolvedCount,
    required this.byCategory,
  });

  static const empty = AlertStats(
    criticalCount: 0,
    activeCount: 0,
    resolvedCount: 0,
    byCategory: [],
  );
}

class EvaluationSample {
  final String label;
  final double? phActual;
  final double? phPredicted;
  final double? ecActual;
  final double? ecPredicted;

  const EvaluationSample({
    required this.label,
    this.phActual,
    this.phPredicted,
    this.ecActual,
    this.ecPredicted,
  });
}

class ForecastEvaluationRecord {
  final String parameter;
  final String targetLabel;
  final double predictedValue;
  final double? actualValue;
  final String status;
  final int interventionCount;
  final String? actionType;
  final String? actionTimeLabel;

  const ForecastEvaluationRecord({
    required this.parameter,
    required this.targetLabel,
    required this.predictedValue,
    required this.actualValue,
    required this.status,
    required this.interventionCount,
    this.actionType,
    this.actionTimeLabel,
  });
}

class ModelEvaluation {
  final List<EvaluationSample> samples;
  final List<ForecastEvaluationRecord> records;
  final int horizonHours;
  final String modelName;
  final int pendingCount;
  final int evaluatedCount;
  final int intervenedCount;
  final int missingActualCount;
  final int calibrationExcludedCount;

  const ModelEvaluation({
    required this.samples,
    this.records = const [],
    required this.horizonHours,
    required this.modelName,
    this.pendingCount = 0,
    this.evaluatedCount = 0,
    this.intervenedCount = 0,
    this.missingActualCount = 0,
    this.calibrationExcludedCount = 0,
  });

  static const empty = ModelEvaluation(
    samples: [],
    horizonHours: 12,
    modelName: 'Forecast model',
  );

  int get storedPredictionCount =>
      pendingCount +
      evaluatedCount +
      intervenedCount +
      missingActualCount +
      calibrationExcludedCount;

  /// 100 minus the mean absolute percentage error, for 'pH', 'EC' or 'Both'.
  double? accuracyFor(String parameter) {
    final errors = <double>[];
    for (final s in samples) {
      if (parameter != 'EC') _addError(errors, s.phActual, s.phPredicted);
      if (parameter != 'pH') _addError(errors, s.ecActual, s.ecPredicted);
    }
    if (errors.isEmpty) return null;
    final mape = errors.reduce((a, b) => a + b) / errors.length;
    return (100 - mape).clamp(0, 100).toDouble();
  }

  static void _addError(
      List<double> errors, double? actual, double? predicted) {
    if (actual == null || predicted == null || actual == 0) return;
    errors.add((actual - predicted).abs() / actual.abs() * 100);
  }
}
