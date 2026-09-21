

class ParameterStatus {
  final String label;
  final String currentValue;
  final String unit;
  final String idealRange;
  final String lastUpdated;

  ParameterStatus({
    required this.label,
    required this.currentValue,
    required this.unit,
    required this.idealRange,
    required this.lastUpdated,
  });
}


class ForecastPoint {
  final double hour;
  final double value;
  final bool isPredicted;

  ForecastPoint({
    required this.hour,
    required this.value,
    required this.isPredicted,
  });
}

class LatestInsight {
  final String warningTitle;
  final String warningDetail;
  final String expectedIn;
  final String humidity;
  final String ecStatus;

  LatestInsight({
    required this.warningTitle,
    required this.warningDetail,
    required this.expectedIn,
    required this.humidity,
    required this.ecStatus,
  });
}


class PredictionInsightDetail {
  final String statusLabel; // e.g. "pH Level"
  final String statusBadge; // "Warning" | "Critical" | "Normal"
  final String warningText;
  final String airHumidity; // e.g. "75%"
  final String ecLevel; // e.g. "5.8 mS/cm"
  final String calloutText;
  final double currentPh;
  final double targetPh;
  final List<String> suggestedFixes;

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

class HistoryLogEntry {
  final List<String> values;

  const HistoryLogEntry(this.values);
}