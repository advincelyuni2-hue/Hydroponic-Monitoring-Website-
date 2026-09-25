import 'package:flutter/foundation.dart';
import 'user_service.dart';

final ValueNotifier<UserProfile?> appProfile =
    ValueNotifier<UserProfile?>(null);

final ValueNotifier<String> appMeasurementUnits =
    ValueNotifier<String>('Metric');

final ValueNotifier<bool> appNotificationsEnabled =
    ValueNotifier<bool>(true);

void setAppProfile(UserProfile profile) {
  appProfile.value = profile;
}

void clearAppProfile() {
  appProfile.value = null;
}

String formatTemperature(double celsius) {
  if (appMeasurementUnits.value == 'Imperial') {
    return '${(celsius * 9 / 5 + 32).toStringAsFixed(1)} °F';
  }
  return '${celsius.toStringAsFixed(1)} °C';
}