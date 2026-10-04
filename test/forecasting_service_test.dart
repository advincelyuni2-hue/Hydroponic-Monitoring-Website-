import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/services/forecasting_service.dart';

void main() {
  final service = ForecastingService();

  test('builds a normal pH insight for an in-range prediction', () {
    final insight = service.runFlutterDSS(
      parameter: 'ph',
      currentPh: 6.1,
      currentEc: 1.5,
      currentTemp: 24,
      predictedPh: 6.2,
      predictedEc: 1.5,
    );

    expect(insight.statusBadge, 'Normal');
    expect(insight.statusLabel, 'pH Level');
    expect(insight.suggestedFixes, ['No recommendation for now']);
  });

  test('prioritizes a combined critical pH and EC prediction', () {
    final insight = service.runFlutterDSS(
      parameter: 'ph',
      currentPh: 6.4,
      currentEc: 1.7,
      currentTemp: 27,
      predictedPh: 7.1,
      predictedEc: 2.1,
    );

    expect(insight.statusBadge, 'Critical');
    expect(insight.warningText, contains('both'));
    expect(insight.suggestedFixes, isNotEmpty);
  });
}
