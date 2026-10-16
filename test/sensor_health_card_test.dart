import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/reports_models.dart';
import 'package:monitoring_app/theme/theme_mode_controller.dart';
import 'package:monitoring_app/widgets/sensor_health_card.dart';

void main() {
  for (final width in [280.0, 320.0, 720.0]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('vertical calibration at $width in $mode', (tester) async {
        appThemeMode.value = mode;
        addTearDown(() => appThemeMode.value = ThemeMode.light);
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
          child: SizedBox(
              width: width,
              child: const SensorHealthCard(sensors: [
                SensorHealthItem(
                    sensorName: 'pH Probe',
                    daysSinceCalibration: 0,
                    healthPercentage: 100,
                    statusLabel: 'Good'),
                SensorHealthItem(
                    sensorName: 'EC Sensor',
                    daysSinceCalibration: 0,
                    healthPercentage: 100,
                    statusLabel: 'Good'),
                SensorHealthItem(
                    sensorName: 'Temperature Sensor',
                    daysSinceCalibration: -1,
                    healthPercentage: 0,
                    statusLabel: 'No records'),
              ])),
        ))));
        expect(find.text('3 sensors'), findsOneWidget);
        expect(find.text('Good 2', findRichText: true), findsOneWidget);
        expect(find.text('No records 1', findRichText: true), findsOneWidget);
        expect(find.text('Calibrated today'), findsNWidgets(2));
        expect(find.text('No calibration recorded'), findsOneWidget);
        expect(tester.getTopLeft(find.text('pH Probe')).dy,
            lessThan(tester.getTopLeft(find.text('EC Sensor')).dy));
        expect(tester.getTopLeft(find.text('EC Sensor')).dy,
            lessThan(tester.getTopLeft(find.text('Temperature Sensor')).dy));
        expect(tester.getSize(find.byType(SensorHealthCard)).width, width);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
