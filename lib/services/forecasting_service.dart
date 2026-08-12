import '../models/forecasting_models.dart';

class ForecastingService {
  /// Mock chart data matching the Figma curve
  Future<List<ForecastingChartPoint>> getForecastChartData(String type) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Sample points representing historical 12h -> Current Time -> Predicted 12h
    return [
      ForecastingChartPoint(hour: -12, value: 7.0, isPredicted: false),
      ForecastingChartPoint(hour: -6, value: 7.0, isPredicted: false),
      ForecastingChartPoint(hour: -5, value: 6.75, isPredicted: false),
      ForecastingChartPoint(hour: 0, value: 6.75, isPredicted: false), // Current time point
      ForecastingChartPoint(hour: 3, value: 6.75, isPredicted: true),
      ForecastingChartPoint(hour: 4, value: 6.5, isPredicted: true),
      ForecastingChartPoint(hour: 12, value: 6.5, isPredicted: true),
    ];
  }

  /// Mock insights data matching the Figma panel
  Future<PredictionInsightDetail> getPredictionInsight() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return PredictionInsightDetail(
      statusLabel: 'pH Level',
      statusBadge: 'Warning',
      warningText: 'pH is expected to rise above safe levels in 45 minutes.',
      airHumidity: '75%',
      ecLevel: '5.8 mS/cm',
      calloutText:
          'High humidity is slowing evaporation, letting dissolved solids build up and push pH higher.',
      currentPh: 7.0,
      targetPh: 6.5,
      suggestedFixes: [
        '4.5 ml of pH down solution',
        '0.5 ml of A and B nutrient concentrate',
      ],
    );
  }
}