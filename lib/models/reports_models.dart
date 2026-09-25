class ReportSummaryData {
  final double avgPh;
  final String phStatus;
  final double avgEc;
  final String ecStatus;
  final int criticalAlertsCount;
  final String alertsPeriod;

  const ReportSummaryData({
    required this.avgPh,
    required this.phStatus,
    required this.avgEc,
    required this.ecStatus,
    required this.criticalAlertsCount,
    required this.alertsPeriod,
  });
}

class AnalyticsPoint {
  final String label; // e.g. "Jul 1"
  final double value; // e.g. 6.4

  const AnalyticsPoint({required this.label, required this.value});
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