import '../models/forecasting_models.dart';

/// Shares in-flight and completed responses for an identical sensor baseline.
/// A new telemetry timestamp gets a new snapshot; failures remain retryable.
class ForecastSnapshotCache {
  final _requests = <Object, Future<List<ForecastingChartPoint>>>{};

  Future<List<ForecastingChartPoint>> get(
    Object key,
    Future<List<ForecastingChartPoint>> Function() fetch,
  ) {
    final existing = _requests[key];
    if (existing != null) return existing;
    late final Future<List<ForecastingChartPoint>> request;
    request = Future.sync(fetch).then((points) {
      if (!points
              .any((p) => p.isPredicted && !p.isFallback && p.value.isFinite) ||
          points.any((p) => p.isFallback)) {
        if (identical(_requests[key], request)) _requests.remove(key);
      }
      return List<ForecastingChartPoint>.unmodifiable(points);
    }, onError: (Object error, StackTrace stack) {
      if (identical(_requests[key], request)) _requests.remove(key);
      Error.throwWithStackTrace(error, stack);
    });
    // Bound memory without allowing an older completion to replace newer data.
    if (_requests.length >= 32) _requests.remove(_requests.keys.first);
    _requests[key] = request;
    return request;
  }
}
