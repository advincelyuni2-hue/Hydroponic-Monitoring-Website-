import 'package:flutter/foundation.dart';
import 'user_service.dart';

final ValueNotifier<UserProfile?> appProfile = ValueNotifier<UserProfile?>(null);
final ValueNotifier<String> appMeasurementUnits = ValueNotifier<String>('Metric');
final ValueNotifier<bool> appNotificationsEnabled = ValueNotifier<bool>(true);

/// The pH / EC ideal ranges saved by the admin. Every screen reads from here.
class ParameterRangeConfig {
  final double phMin;
  final double phMax;
  final double ecMin;
  final double ecMax;

  const ParameterRangeConfig({
    this.phMin = 5.5,
    this.phMax = 6.5,
    this.ecMin = 1.2,
    this.ecMax = 1.8,
  });
}

final ValueNotifier<ParameterRangeConfig> appParameterRanges =
    ValueNotifier<ParameterRangeConfig>(const ParameterRangeConfig());

void setAppProfile(UserProfile profile) {
  appProfile.value = profile;
}

String formatTemperature(double celsius) {
  if (appMeasurementUnits.value == 'Imperial') {
    return '${(celsius * 9 / 5 + 32).toStringAsFixed(1)} °F';
  }
  return '${celsius.toStringAsFixed(1)} °C';
}

bool get isImperial => appMeasurementUnits.value == 'Imperial';
String get tempUnit => isImperial ? '°F' : '°C';
double toDisplayTemp(double c) => isImperial ? c * 9 / 5 + 32 : c;
double fromDisplayTemp(double v) => isImperial ? (v - 32) * 5 / 9 : v;

String formatTempRange(double minC, double maxC) =>
    '${toDisplayTemp(minC).toStringAsFixed(1)}–${toDisplayTemp(maxC).toStringAsFixed(1)} $tempUnit';

String formatTempText(String text) {
  final match = RegExp(r'^\s*(-?\d+(\.\d+)?)\s*°C\s*$').firstMatch(text);
  if (match == null) return text;
  return formatTemperature(double.parse(match.group(1)!));
}