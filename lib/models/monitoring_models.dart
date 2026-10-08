import '../utils/parameter_severity.dart';
import '../utils/sensor_value_format.dart';

class ParameterStatus {
  final String label;
  final String currentValue;
  final String unit;
  final String idealRange;
  final String lastUpdated;
  final String status;

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
  final bool isFallback;

  ForecastPoint({
    required this.hour,
    required this.value,
    required this.isPredicted,
    this.isFallback = false,
  });
}

class ForecastHorizonSummary {
  final int hoursAhead;
  final double phValue;
  final double ecValue;
  final DateTime predictedFor;

  const ForecastHorizonSummary({
    required this.hoursAhead,
    required this.phValue,
    required this.ecValue,
    required this.predictedFor,
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
  final Map<int, HistoryValueRange> ranges;
  final DateTime? recordStart;
  final Duration? recordDuration;

  const HistoryLogEntry(
    this.values, {
    this.ranges = const {},
    this.recordStart,
    this.recordDuration,
  });
}

class HistoryValueRange {
  final double minimum;
  final double maximum;
  final double? value;
  final String unit;
  final double warningMargin;

  const HistoryValueRange({
    required this.minimum,
    required this.maximum,
    required this.value,
    this.unit = '',
    this.warningMargin = 0,
  });

  bool get isHigh => value != null && value! > maximum;
  bool get isLow => value != null && value! < minimum;
  bool get isCriticalHigh => value != null && value! > maximum + warningMargin;
  bool get isCriticalLow => value != null && value! < minimum - warningMargin;
  bool get isWarning =>
      value != null && (isHigh || isLow) && !isCriticalHigh && !isCriticalLow;
  String get severity => value == null
      ? 'Stable'
      : parameterSeverityLabel(
          classifyParameterValue(
            value: value!,
            stableMin: minimum,
            stableMax: maximum,
            warningMargin: warningMargin,
          ),
        );
  String get label {
    final decimals = unit == '°C' ? 1 : sensorValueDecimalPlaces;
    return '${minimum.toStringAsFixed(decimals)}–${maximum.toStringAsFixed(decimals)}${unit.isEmpty ? '' : ' $unit'}';
  }
}
