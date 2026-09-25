import '../models/reports_models.dart';

class ReportsService {
  Future<ReportSummaryData> getSummaryData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const ReportSummaryData(
      avgPh: 6.2,
      phStatus: 'In range',
      avgEc: 5.7,
      ecStatus: 'Stable',
      criticalAlertsCount: 3,
      alertsPeriod: 'This month',
    );
  }

  Future<List<AnalyticsPoint>> getTrendData(
      String parameter, String timeframe) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      AnalyticsPoint(label: 'Jul 1', value: 6.4),
      AnalyticsPoint(label: 'Jul 5', value: 6.6),
      AnalyticsPoint(label: 'Jul 9', value: 6.9),
      AnalyticsPoint(label: 'Jul 13', value: 6.6),
      AnalyticsPoint(label: 'Jul 17', value: 6.2),
      AnalyticsPoint(label: 'Jul 21', value: 6.1),
      AnalyticsPoint(label: 'Jul 25', value: 6.5),
      AnalyticsPoint(label: 'Jul 29', value: 6.2),
    ];
  }

  Future<List<PredictedAnalyticsPoint>> getPredictionData(
      String parameter) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
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

  Future<TargetDistributionData> getTargetDistribution() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const TargetDistributionData(
      optimalPercentage: 88,
      warningPercentage: 8,
      criticalPercentage: 4,
    );
  }

  Future<List<AlertFrequencyData>> getAlertFrequency() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      AlertFrequencyData(category: 'pH Drift', count: 5),
      AlertFrequencyData(category: 'EC Spike', count: 2),
      AlertFrequencyData(category: 'Humidity', count: 1),
      AlertFrequencyData(category: 'Offline', count: 1),
    ];
  }

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