enum ParameterSeverity { stable, warning, critical }

ParameterSeverity classifyParameterValue({
  required double value,
  required double stableMin,
  required double stableMax,
  required double warningMargin,
}) {
  if (value >= stableMin && value <= stableMax) {
    return ParameterSeverity.stable;
  }
  if (value >= stableMin - warningMargin &&
      value <= stableMax + warningMargin) {
    return ParameterSeverity.warning;
  }
  return ParameterSeverity.critical;
}

String parameterSeverityLabel(ParameterSeverity severity) => switch (severity) {
      ParameterSeverity.stable => 'Stable',
      ParameterSeverity.warning => 'Warning',
      ParameterSeverity.critical => 'Critical',
    };
