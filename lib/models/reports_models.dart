
class ReportSummaryData {
  final double avgPh;
  final String phStatus;
  final double avgEc;
  final String ecStatus;
  final int criticalAlertsCount;
  final String alertsPeriod;

  ReportSummaryData({
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

  AnalyticsPoint({required this.label, required this.value});
}

class ReportReading {
  final DateTime recordedAt;
  final double value;
  final String parameter;
  final String status;

  const ReportReading({
    required this.recordedAt,
    required this.value,
    required this.parameter,
    required this.status,
  });
}

class ReportCalibrationLog {
  final DateTime recordedAt;
  final String parameter;
  final String calibrationType;
  final String adjustment;
  final String performedBy;
  final String status;

  const ReportCalibrationLog({
    required this.recordedAt,
    required this.parameter,
    required this.calibrationType,
    required this.adjustment,
    required this.performedBy,
    required this.status,
  });
}

class PdfReportData {
  final DateTime startDate;
  final DateTime endDate;
  final List<ReportReading> phReadings;
  final List<ReportReading> ecReadings;
  final List<ReportReading> temperatureReadings;
  final List<ReportReading> phSummaryReadings;
  final List<ReportReading> ecSummaryReadings;
  final List<ReportCalibrationLog> calibrationLogs;
  final double phMin;
  final double phMax;
  final double ecMin;
  final double ecMax;
  final int criticalAlertsCount;

  const PdfReportData({
    required this.startDate,
    required this.endDate,
    required this.phReadings,
    required this.ecReadings,
    required this.temperatureReadings,
    required this.phSummaryReadings,
    required this.ecSummaryReadings,
    required this.calibrationLogs,
    required this.phMin,
    required this.phMax,
    required this.ecMin,
    required this.ecMax,
    required this.criticalAlertsCount,
  });
}

class PredictedAnalyticsPoint {
  final String label;
  final double actualValue;
  final double predictedValue;

  double get delta => (actualValue - predictedValue).abs();

  PredictedAnalyticsPoint({
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

  const AlertFrequencyData({required this.category, required this.count});
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