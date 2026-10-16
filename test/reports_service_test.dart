import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/monitoring_models.dart';
import 'package:monitoring_app/services/monitoring_service.dart';
import 'package:monitoring_app/services/reports_service.dart';

void main() {
  test('loads chronological EC history for the selected window', () async {
    final monitoring = _FakeMonitoringService();
    final service = ReportsService(monitoringService: monitoring);

    final points = await service.getTrendData('EC', '7d');

    expect(points.map((point) => point.value), [1.4, 1.5, 1.6]);
    expect(points.map((point) => point.parameter), ['EC', 'EC', 'EC']);
    expect(points.first.label, 'Oct 1');
    expect(monitoring.requestedStart, DateTime(2026, 9, 27));
    expect(monitoring.requestedEnd, DateTime(2026, 10, 4));
  });
}

class _FakeMonitoringService extends MonitoringService {
  DateTime? requestedStart;
  DateTime? requestedEnd;

  @override
  Future<DateTimeRange?> getSensorCollectionDateRange() async =>
      DateTimeRange(
        start: DateTime(2026, 3, 3),
        end: DateTime(2026, 10, 3, 8),
      );

  @override
  Future<List<HistoryLogEntry>> getSensorHistory({
    required DateTime start,
    required DateTime end,
    required HistoryAggregation aggregation,
  }) async {
    requestedStart = start;
    requestedEnd = end;
    return const [
      HistoryLogEntry([
        'October 3, 2026',
        'All day',
        '6.20',
        '1.60 mS/cm',
        '24.0 deg C',
        'Stable',
      ]),
      HistoryLogEntry([
        'October 2, 2026',
        'All day',
        '6.10',
        '1.50 mS/cm',
        '24.2 deg C',
        'Stable',
      ]),
      HistoryLogEntry([
        'October 1, 2026',
        'All day',
        '6.00',
        '1.40 mS/cm',
        '24.1 deg C',
        'Stable',
      ]),
    ];
  }
}
