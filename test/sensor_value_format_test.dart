import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/utils/sensor_value_format.dart';

void main() {
  test('sensor values always display six decimal places', () {
    expect(formatSensorValue(6.86), '6.860000');
    expect(formatSensorValue(1.413), '1.413000');
    expect(formatSensorValue(1.2), '1.200000');
  });

  test('sensor ranges preserve six trailing decimal places', () {
    expect(formatSensorRange(5.5, 6.5), '5.500000 - 6.500000');
  });
}
