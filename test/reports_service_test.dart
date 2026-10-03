import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/services/reports_service.dart';

void main() {
  test('returns the requested EC trend window in chronological order',
      () async {
    final service = ReportsService();

    final points = await service.getTrendData('EC', '7d');

    expect(points, hasLength(4));
    expect(points.map((point) => point.label), [
      'Jul 1',
      'Jul 5',
      'Jul 9',
      'Jul 13',
    ]);
    expect(points.map((point) => point.value), [5.4, 5.6, 5.8, 5.5]);
  });
}
