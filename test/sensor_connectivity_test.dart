import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/services/monitoring_service.dart';

void main() {
  group('sensor connectivity', () {
    final now = DateTime.utc(2026, 10, 9, 8);

    test('is offline when no sensor reading exists', () {
      expect(
        MonitoringService.isSensorReadingOffline(null, now: now),
        isTrue,
      );
    });

    test('remains online at the ten-minute boundary', () {
      expect(
        MonitoringService.isSensorReadingOffline(
          now.subtract(const Duration(minutes: 10)),
          now: now,
        ),
        isFalse,
      );
    });

    test('is offline after the ten-minute boundary', () {
      expect(
        MonitoringService.isSensorReadingOffline(
          now.subtract(const Duration(minutes: 10, seconds: 1)),
          now: now,
        ),
        isTrue,
      );
    });
  });
}
