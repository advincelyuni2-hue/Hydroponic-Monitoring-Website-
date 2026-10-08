import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/utils/parameter_severity.dart';

void main() {
  test('pH and EC use a 0.5 warning margin', () {
    expect(
      classifyParameterValue(
        value: 5.5,
        stableMin: 5.5,
        stableMax: 6.5,
        warningMargin: 0.5,
      ),
      ParameterSeverity.stable,
    );
    expect(
      classifyParameterValue(
        value: 5.2,
        stableMin: 5.5,
        stableMax: 6.5,
        warningMargin: 0.5,
      ),
      ParameterSeverity.warning,
    );
    expect(
      classifyParameterValue(
        value: 4.9,
        stableMin: 5.5,
        stableMax: 6.5,
        warningMargin: 0.5,
      ),
      ParameterSeverity.critical,
    );
  });

  test('temperature uses a 5 degree warning margin', () {
    expect(
      classifyParameterValue(
        value: 24,
        stableMin: 18,
        stableMax: 24,
        warningMargin: 5,
      ),
      ParameterSeverity.stable,
    );
    expect(
      classifyParameterValue(
        value: 28,
        stableMin: 18,
        stableMax: 24,
        warningMargin: 5,
      ),
      ParameterSeverity.warning,
    );
    expect(
      classifyParameterValue(
        value: 30,
        stableMin: 18,
        stableMax: 24,
        warningMargin: 5,
      ),
      ParameterSeverity.critical,
    );
  });
}
