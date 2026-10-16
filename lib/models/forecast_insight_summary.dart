import 'forecasting_models.dart';
import '../utils/sensor_value_format.dart';
import '../utils/parameter_severity.dart';

/// Presentation-independent analysis of genuine, forward-looking model points.
class ForecastInsightSummary {
  final List<ForecastingChartPoint> points;
  final double minimum;
  final double maximum;

  ForecastInsightSummary({
    required List<ForecastingChartPoint> forecast,
    required this.minimum,
    required this.maximum,
  }) : points = forecast
            .where((p) =>
                p.isPredicted &&
                !p.isFallback &&
                p.hour.isFinite &&
                p.value.isFinite &&
                p.hour >= 0 &&
                p.hour <= 12)
            .toList()
          ..sort((a, b) => a.hour.compareTo(b.hour));

  double? valueAt(int hour) {
    for (final point in points) {
      if ((point.hour - hour).abs() < 0.000001) return point.value;
    }
    return null;
  }

  bool outside(double value) => value < minimum || value > maximum;

  /// Same pH/EC warning margin and classifier as MonitoringService.
  ParameterSeverity? severityAt(int hour) {
    final value = valueAt(hour);
    return value == null
        ? null
        : classifyParameterValue(
            value: value,
            stableMin: minimum,
            stableMax: maximum,
            warningMargin: 0.5);
  }

  ParameterSeverity? get severity {
    ParameterSeverity? result;
    for (final point in points) {
      final next = classifyParameterValue(
          value: point.value,
          stableMin: minimum,
          stableMax: maximum,
          warningMargin: 0.5);
      if (result == null || next.index > result.index) result = next;
    }
    return result;
  }

  bool get hasViolation => points.any((p) => outside(p.value));

  String get trend {
    if (points.length < 2) return 'Unavailable';
    final delta = points.last.value - points.first.value;
    final tolerance = (maximum - minimum).abs() * 0.02;
    if (delta.abs() <= tolerance) return 'Stable';
    return delta > 0 ? 'Rising' : 'Falling';
  }

  /// First actual boundary violation, including trajectories that later recover.
  ({double? threshold, double? hour, bool alreadyExceeded}) get crossing {
    if (points.isEmpty) {
      return (threshold: null, hour: null, alreadyExceeded: false);
    }
    if (outside(points.first.value)) {
      return (
        threshold: points.first.value < minimum ? minimum : maximum,
        hour: points.first.hour,
        alreadyExceeded: true,
      );
    }
    for (var i = 1; i < points.length; i++) {
      final before = points[i - 1];
      final after = points[i];
      if (!outside(after.value)) continue;
      final boundary = after.value < minimum ? minimum : maximum;
      final fraction = (boundary - before.value) / (after.value - before.value);
      return (
        threshold: boundary,
        hour: before.hour + fraction * (after.hour - before.hour),
        alreadyExceeded: false,
      );
    }
    return (
      threshold: trend == 'Rising'
          ? maximum
          : trend == 'Falling'
              ? minimum
              : null,
      hour: null,
      alreadyExceeded: false,
    );
  }

  String thresholdLabel({String unit = ''}) {
    if (points.isEmpty) return 'Unavailable';
    final boundary = crossing.threshold;
    final suffix = unit.isEmpty ? '' : ' $unit';
    return boundary == null
        ? '${formatSensorRange(minimum, maximum)}$suffix'
        : '${boundary == minimum ? 'Lower' : 'Upper'}: ${formatSensorValue(boundary)}$suffix';
  }

  String explanation(String parameter) {
    if (points.isEmpty) return 'Forecast data is unavailable.';
    return '$parameter ${trend == 'Unavailable' ? 'has limited forecast data' : 'is ${trend.toLowerCase()}'}'
        '${hasViolation ? '; the available forecast includes values outside the configured range.' : '; available forecast values stay within the configured range.'}';
  }

  String get crossingLabel {
    if (points.isEmpty) return 'Unavailable';
    final result = crossing;
    if (result.alreadyExceeded) return 'Already exceeded at forecast start';
    if (result.hour == null) return 'Not expected';
    final minutes = (result.hour! * 60).round();
    if (minutes < 1) return 'Less than 1 min';
    return minutes < 60
        ? '~$minutes min'
        : '~${minutes ~/ 60}h ${minutes % 60}m';
  }
}
