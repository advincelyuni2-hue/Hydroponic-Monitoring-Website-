import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/services/app_state.dart';
import 'package:monitoring_app/services/forecasting_service.dart';

void main() {
  final service = ForecastingService();

  setUp(() {
    appParameterRanges.value = const ParameterRangeConfig();
  });

  test('builds a stable pH insight for an in-range prediction', () {
    final insight = service.runFlutterDSS(
      parameter: 'ph',
      currentPh: 6.1,
      currentEc: 1.5,
      currentTemp: 24,
      predictedPh: 6.2,
      predictedEc: 1.5,
    );

    expect(insight.statusBadge, 'Stable');
    expect(insight.statusLabel, 'pH Level');
    expect(insight.suggestedFixes, ['No recommendation for now']);
  });

  test('critical pH forecast is not downgraded by EC', () {
    final insight = service.runFlutterDSS(
      parameter: 'ph',
      currentPh: 6.4,
      currentEc: 1.7,
      currentTemp: 27,
      predictedPh: 7.1,
      predictedEc: 2.1,
    );

    expect(insight.statusBadge, 'Critical');
    expect(insight.warningText, contains('critically elevated'));
    expect(insight.suggestedFixes, isNotEmpty);
  });

  test('uses current pH severity when forecast appears stable', () {
    final insight = service.runFlutterDSS(
      parameter: 'ph',
      currentPh: 9.1,
      currentEc: 1.5,
      currentTemp: 24,
      predictedPh: 6.2,
      predictedEc: 1.5,
    );

    expect(insight.statusBadge, 'Critical');
  });

  test('uses configured pH warning and critical boundaries', () {
    appParameterRanges.value = const ParameterRangeConfig(
      phMin: 5.8,
      phMax: 6.8,
    );
    final warning = service.runFlutterDSS(
      parameter: 'ph',
      currentPh: 6.2,
      currentEc: 1.5,
      currentTemp: 24,
      predictedPh: 7.1,
      predictedEc: 1.5,
    );
    final critical = service.runFlutterDSS(
      parameter: 'ph',
      currentPh: 6.2,
      currentEc: 1.5,
      currentTemp: 24,
      predictedPh: 7.4,
      predictedEc: 1.5,
    );

    expect(warning.statusBadge, 'Warning');
    expect(critical.statusBadge, 'Critical');
    expect(warning.targetPh, closeTo(6.3, 0.001));
  });

  test('uses the same configurable range rules for EC', () {
    final warning = service.runFlutterDSS(
      parameter: 'ec',
      currentPh: 6.2,
      currentEc: 1.5,
      currentTemp: 24,
      predictedPh: 6.2,
      predictedEc: 0.9,
    );
    final critical = service.runFlutterDSS(
      parameter: 'ec',
      currentPh: 6.2,
      currentEc: 1.5,
      currentTemp: 24,
      predictedPh: 6.2,
      predictedEc: 0.6,
    );

    expect(warning.statusBadge, 'Warning');
    expect(critical.statusBadge, 'Critical');
  });
}
