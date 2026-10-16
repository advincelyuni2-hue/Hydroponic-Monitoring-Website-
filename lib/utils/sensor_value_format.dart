const int sensorValueDecimalPlaces = 6;

String formatSensorValue(num value) =>
    value.toStringAsFixed(sensorValueDecimalPlaces);

String formatSensorRange(num minimum, num maximum) =>
    '${formatSensorValue(minimum)} - ${formatSensorValue(maximum)}';
