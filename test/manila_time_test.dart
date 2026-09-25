import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/utils/manila_time.dart';

void main() {
  test('converts a Supabase UTC timestamp to Manila time', () {
    final result = toManilaTime(
      parseSupabaseTimestamp('2026-09-25T12:30:00Z'),
    );

    expect(result, DateTime(2026, 9, 25, 20, 30));
    expect(formatManilaDateTime(result), 'Sep 25, 2026, 8:30 PM PHT');
  });

  test('treats a Supabase timestamp without an offset as UTC', () {
    final result = toManilaTime(
      parseSupabaseTimestamp('2026-09-25T12:30:00'),
    );

    expect(result, DateTime(2026, 9, 25, 20, 30));
  });

  test('converts the database text timestamp from UTC to Manila time', () {
    final result = toManilaTime(
      parseSupabaseTimestamp('09/19/2026 00:04:00'),
    );

    expect(result, DateTime(2026, 9, 19, 8, 4));
    expect(formatManilaDateTime(result), 'Sep 19, 2026, 8:04 AM PHT');
  });

  test('corrects the live sensor storage skew before converting to PHT', () {
    final result = toSensorManilaTime(
      parseSupabaseTimestamp('2026-09-18T16:04:00+00:00'),
    );

    expect(result, DateTime(2026, 9, 19, 8, 4));
    expect(formatManilaDateTime(result), 'Sep 19, 2026, 8:04 AM PHT');
  });

  test('converts a Manila history boundary back to UTC', () {
    final result = manilaWallTimeToUtc(DateTime(2026, 9, 25));

    expect(result, DateTime.utc(2026, 9, 24, 16));
  });

  test('accounts for sensor storage skew in history boundaries', () {
    final result = sensorManilaWallTimeToStoredUtc(DateTime(2026, 9, 19));

    expect(result, DateTime.utc(2026, 9, 18, 8));
  });
}
