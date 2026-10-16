import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/forecasting_models.dart';
import 'package:monitoring_app/services/forecast_snapshot_cache.dart';

List<ForecastingChartPoint> points(double value, {bool fallback = false}) => [
      ForecastingChartPoint(
          hour: 4, value: value, isPredicted: true, isFallback: fallback),
    ];

void main() {
  test('shares in-flight and completed baseline without duplicate fetches',
      () async {
    final cache = ForecastSnapshotCache();
    final pending = Completer<List<ForecastingChartPoint>>();
    var calls = 0;
    Future<List<ForecastingChartPoint>> fetch() {
      calls++;
      return pending.future;
    }

    final first = cache.get('baseline', fetch);
    final second = cache.get('baseline', fetch);
    expect(identical(first, second), isTrue);
    pending.complete(points(1.89));
    expect(identical(await first, await second), isTrue);
    await cache.get('baseline', fetch);
    expect(calls, 1);
  });
  test('older completion cannot overwrite a newer baseline', () async {
    final cache = ForecastSnapshotCache();
    final older = Completer<List<ForecastingChartPoint>>();
    final first = cache.get('old', () => older.future);
    await cache.get('new', () async => points(1.77));
    older.complete(points(1.89));
    await first;
    final latest =
        await cache.get('new', () async => throw StateError('must reuse'));
    expect(latest.single.value, 1.77);
  });
  test('errors, missing forecasts, and fallback responses remain retryable',
      () async {
    final cache = ForecastSnapshotCache();
    await expectLater(cache.get('key', () async => throw StateError('offline')),
        throwsStateError);
    await cache.get('key', () async => []);
    await cache.get('key', () async => points(0, fallback: true));
    final recovered = await cache.get('key', () async => points(1.89));
    expect(recovered.single.value, 1.89);
    expect(recovered.single.isFallback, isFalse);
  });
}
