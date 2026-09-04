
class ForecastingChartPoint {
  final double hour; // negative = past, 0 = current time, positive = predicted
  final double value;
  final bool isPredicted;

  ForecastingChartPoint({
    required this.hour,
    required this.value,
    required this.isPredicted,
  });
}

class PredictionInsightDetail {
  final String statusLabel; // e.g., "pH Level"
  final String statusBadge; // e.g., "Warning"
  final String warningText; // e.g., "pH is expected to rise above safe levels in 45 minutes."
  final String airHumidity; // e.g., "75%"
  final String ecLevel; // e.g., "5.8 mS/cm"
  final String calloutText; // e.g., "High humidity is slowing evaporation..."
  final double currentPh; // e.g., 7.0
  final double targetPh; // e.g., 6.5
  final List<String> suggestedFixes; // e.g., ["4.5 ml of pH down solution", ...]

  PredictionInsightDetail({
    required this.statusLabel,
    required this.statusBadge,
    required this.warningText,
    required this.airHumidity,
    required this.ecLevel,
    required this.calloutText,
    required this.currentPh,
    required this.targetPh,
    required this.suggestedFixes,
  });
}