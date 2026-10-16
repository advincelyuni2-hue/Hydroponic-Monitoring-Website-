import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';
import '../theme/theme_mode_controller.dart';

final ValueNotifier<UserProfile?> appProfile = ValueNotifier<UserProfile?>(null);
final ValueNotifier<String> appMeasurementUnits = ValueNotifier<String>('Metric');
final ValueNotifier<bool> appNotificationsEnabled = ValueNotifier<bool>(true);

const _measurementUnitsKey = 'measurement_units';
const _notificationsEnabledKey = 'notifications_enabled';
const _darkModeKey = 'dark_mode';

Future<void> loadSavedPreferences() async {
  final preferences = await SharedPreferences.getInstance();

  final savedUnits = preferences.getString(_measurementUnitsKey);
  appMeasurementUnits.value =
      savedUnits == 'Imperial' ? 'Imperial' : 'Metric';

  appNotificationsEnabled.value =
      preferences.getBool(_notificationsEnabledKey) ?? true;

  final isDarkMode = preferences.getBool(_darkModeKey) ?? false;
  appThemeMode.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
}

Future<void> saveNotificationPreference(bool value) async {
  appNotificationsEnabled.value = value;
  final preferences = await SharedPreferences.getInstance();
  await preferences.setBool(_notificationsEnabledKey, value);
}

Future<void> saveMeasurementUnitsPreference(String value) async {
  appMeasurementUnits.value = value;
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(_measurementUnitsKey, value);
}

Future<void> saveDarkModePreference(bool value) async {
  appThemeMode.value = value ? ThemeMode.dark : ThemeMode.light;
  final preferences = await SharedPreferences.getInstance();
  await preferences.setBool(_darkModeKey, value);
}

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