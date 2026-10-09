import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/services/calibration_service.dart';

void main() {
  final start = DateTime.utc(2026, 10, 9, 0, 0);

  List<CalibrationSample> samples(List<double> voltages) => [
        for (var i = 0; i < voltages.length; i++)
          CalibrationSample(
              i + 1, start.add(Duration(seconds: i * 10)), voltages[i]),
      ];

  test('does not capture before six readings over the settling window', () {
    final result = CalibrationStability.evaluate(
      samples([2.50, 2.50, 2.50, 2.50, 2.50]),
      parameter: 'ph',
    );
    expect(result.stable, isFalse);
  });

  test('accepts a stable pH voltage window', () {
    final result = CalibrationStability.evaluate(
      samples([2.500, 2.503, 2.501, 2.500, 2.502, 2.501]),
      parameter: 'ph',
    );
    expect(result.stable, isTrue);
    expect(result.averageVoltage, closeTo(2.501, 0.001));
  });

  test('rejects a migrating solution with drifting voltage', () {
    final result = CalibrationStability.evaluate(
      samples([2.50, 2.47, 2.43, 2.40, 2.37, 2.34]),
      parameter: 'ph',
    );
    expect(result.stable, isFalse);
  });

  test('uses the TDS voltage limit independently of the pH limit', () {
    final readings = samples([1.001, 1.015, 1.007, 1.012, 1.009, 1.013]);
    expect(CalibrationStability.evaluate(readings, parameter: 'tds').stable,
        isTrue);
    expect(CalibrationStability.evaluate(readings, parameter: 'ph').stable,
        isFalse);
  });
}
