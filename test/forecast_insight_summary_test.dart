import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/forecast_insight_summary.dart';
import 'package:monitoring_app/models/forecasting_models.dart';

ForecastingChartPoint point(double hour, double value,
        {bool predicted = true, bool fallback = false}) =>
    ForecastingChartPoint(
        hour: hour, value: value, isPredicted: predicted, isFallback: fallback);

ForecastInsightSummary summarize(List<ForecastingChartPoint> points) =>
    ForecastInsightSummary(forecast: points, minimum: 2, maximum: 4);

void main() {
  test('EC falling back into range retains upper violation', () {
    final summary = ForecastInsightSummary(
        forecast: [point(4, 1.89), point(8, 1.80), point(12, 1.77)],
        minimum: 1.2,
        maximum: 1.8);
    expect(summary.trend, 'Falling');
    expect(summary.crossing.threshold, 1.8);
    expect(summary.crossing.alreadyExceeded, isTrue);
    expect(summary.outside(1.8), isFalse);
    expect(summary.crossingLabel, 'Already exceeded at forecast start');
  });
  test('lower exceeded and matching pH/EC trend vocabulary', () {
    for (final range in [(5.5, 6.5), (1.2, 1.8)]) {
      final low = range.$1;
      final high = range.$2;
      for (final direction in [-1, 0, 1]) {
        final summary = ForecastInsightSummary(forecast: [
          point(4, low - 0.2),
          point(12, low - 0.2 + direction * 0.1)
        ], minimum: low, maximum: high);
        expect(
            summary.trend,
            direction < 0
                ? 'Falling'
                : direction > 0
                    ? 'Rising'
                    : 'Stable');
        expect(summary.crossing.threshold, low);
        expect(summary.crossing.alreadyExceeded, isTrue);
      }
    }
  });

  test('interpolates upper crossing even when trajectory recovers', () {
    final summary = summarize([point(0, 3), point(4, 5), point(12, 3)]);
    expect(summary.crossing.hour, 2);
    expect(summary.crossing.threshold, 4);
    expect(summary.hasViolation, isTrue);
  });
  test('interpolates lower crossing', () {
    final summary = summarize([point(0, 3), point(4, 1)]);
    expect(summary.crossing.hour, 2);
    expect(summary.crossing.threshold, 2);
    expect(summary.trend, 'Falling');
  });
  test('already exceeded does not invent an earlier crossing', () {
    final summary = summarize([point(1, 5), point(4, 3)]);
    expect(summary.crossing.alreadyExceeded, isTrue);
    expect(summary.crossingLabel, 'Already exceeded at forecast start');
  });
  test('no crossing and insignificant fluctuations', () {
    final summary = summarize([point(0, 3), point(12, 3.01)]);
    expect(summary.crossingLabel, 'Not expected');
    expect(summary.trend, 'Stable');
  });
  test('missing horizons exclude historical, fallback, and nonfinite points',
      () {
    final summary = summarize([
      point(4, 3),
      point(8, 4, predicted: false),
      point(12, 5, fallback: true),
      point(8, double.nan),
      point(16, 5),
    ]);
    expect(summary.valueAt(4), 3);
    expect(summary.valueAt(8), isNull);
    expect(summary.valueAt(12), isNull);
    expect(summarize([]).crossingLabel, 'Unavailable');
  });
  test('sorts hour offsets and never relabels a nearby point', () {
    final summary = summarize([point(12, 3.8), point(4, 3), point(7.9, 3.5)]);
    expect(summary.trend, 'Rising');
    expect(summary.valueAt(8), isNull);
    expect(summary.valueAt(12), 3.8);
  });
}
