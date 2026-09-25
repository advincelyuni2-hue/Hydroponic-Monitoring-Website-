class ForecastingChartPoint {
  final double hour; // negative = past, 0 = current, positive = predicted
  final double value;
  final bool isPredicted;

  ForecastingChartPoint({
    required this.hour,
    required this.value,
    required this.isPredicted,
  });

  factory ForecastingChartPoint.fromJson(Map<String, dynamic> json) {
    return ForecastingChartPoint(
      hour: (json['hour'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      isPredicted: json['is_predicted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'value': value,
    'is_predicted': isPredicted,
  };
}

class PredictionInsightDetail {
  final String statusLabel; // e.g., "pH Level" or "EC Level"
  final String statusBadge; // e.g., "Warning", "Normal", "Critical"
  final String warningText; // e.g., "pH is expected to rise above safe levels in 45 minutes."
  final String temperature; // Updated from airHumidity -> e.g., "24.5 °C"
  final String ecLevel; // e.g., "5.8 mS/cm"
  final String calloutText; // Explanation of contributing factors
  final double currentPh;
  final double targetPh;
  final List<String> suggestedFixes;

  PredictionInsightDetail({
    required this.statusLabel,
    required this.statusBadge,
    required this.warningText,
    required this.temperature,
    required this.ecLevel,
    required this.calloutText,
    required this.currentPh,
    required this.targetPh,
    required this.suggestedFixes,
  });

  factory PredictionInsightDetail.fromJson(Map<String, dynamic> json) {
    return PredictionInsightDetail(
      statusLabel: json['status_label'] ?? 'pH Level',
      statusBadge: json['status_badge'] ?? 'Normal',
      warningText: json['warning_text'] ?? '',
      temperature: json['temperature'] ?? '0 °C',
      ecLevel: json['ec_level'] ?? '0.0 mS/cm',
      calloutText: json['callout_text'] ?? '',
      currentPh: (json['current_ph'] as num?)?.toDouble() ?? 0.0,
      targetPh: (json['target_ph'] as num?)?.toDouble() ?? 0.0,
      suggestedFixes: List<String>.from(json['suggested_fixes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'status_label': statusLabel,
    'status_badge': statusBadge,
    'warning_text': warningText,
    'temperature': temperature,
    'ec_level': ecLevel,
    'callout_text': calloutText,
    'current_ph': currentPh,
    'target_ph': targetPh,
    'suggested_fixes': suggestedFixes,
  };
}