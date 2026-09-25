class ParameterStatus {
  final String label;
  final String currentValue;
  final String unit;
  final String idealRange;
  final String lastUpdated;
  final String status; // 'Normal', 'Warning', 'Critical'

  ParameterStatus({
    required this.label,
    required this.currentValue,
    required this.unit,
    required this.idealRange,
    required this.lastUpdated,
    this.status = 'Normal',
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

class HistoryLogEntry {
  final List<String> values;
  const HistoryLogEntry(this.values);
}

enum HistoryAggregation {
  tenMinutes,
  eightHours,
  daily,
}