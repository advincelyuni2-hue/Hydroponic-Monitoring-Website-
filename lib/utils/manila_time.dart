const Duration manilaUtcOffset = Duration(hours: 8);

// Current sensor rows arrive from Supabase eight hours earlier than their
// intended UTC instant. Keep this correction isolated to sensor data so other
// application timestamps continue to use the normal UTC -> PHT conversion.
const Duration sensorStoredUtcCorrection = Duration(hours: 8);

DateTime parseSupabaseTimestamp(String value) {
  final trimmed = value.trim();
  final databaseTextMatch = RegExp(
    r'^(\d{1,2})/(\d{1,2})/(\d{4})[ T](\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?$',
    caseSensitive: false,
  ).firstMatch(trimmed);

  if (databaseTextMatch != null) {
    var hour = int.parse(databaseTextMatch.group(4)!);
    final period = databaseTextMatch.group(7)?.toUpperCase();
    if (period == 'AM' && hour == 12) hour = 0;
    if (period == 'PM' && hour != 12) hour += 12;
    return DateTime.utc(
      int.parse(databaseTextMatch.group(3)!),
      int.parse(databaseTextMatch.group(1)!),
      int.parse(databaseTextMatch.group(2)!),
      hour,
      int.parse(databaseTextMatch.group(5)!),
      int.tryParse(databaseTextMatch.group(6) ?? '') ?? 0,
    );
  }

  final hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(trimmed);
  return DateTime.parse(hasTimezone ? trimmed : '${trimmed}Z');
}

/// Converts an absolute timestamp from Supabase into Manila wall-clock time.
///
/// Supabase stores `timestamptz` values as UTC. Returning a wall-clock
/// [DateTime] keeps display and history bucketing independent of the device's
/// configured timezone.
DateTime toManilaTime(DateTime timestamp) {
  final shifted = timestamp.toUtc().add(manilaUtcOffset);
  return DateTime(
    shifted.year,
    shifted.month,
    shifted.day,
    shifted.hour,
    shifted.minute,
    shifted.second,
    shifted.millisecond,
    shifted.microsecond,
  );
}

DateTime toSensorManilaTime(DateTime timestamp) {
  return toManilaTime(timestamp.toUtc().add(sensorStoredUtcCorrection));
}

DateTime manilaNow() => toManilaTime(DateTime.now());

/// Converts a date/time selected in the UI as Manila wall-clock time to the
/// UTC instant expected by Supabase range filters.
DateTime manilaWallTimeToUtc(DateTime manilaTime) {
  return DateTime.utc(
    manilaTime.year,
    manilaTime.month,
    manilaTime.day,
    manilaTime.hour,
    manilaTime.minute,
    manilaTime.second,
    manilaTime.millisecond,
    manilaTime.microsecond,
  ).subtract(manilaUtcOffset);
}

DateTime sensorManilaWallTimeToStoredUtc(DateTime manilaTime) {
  return manilaWallTimeToUtc(manilaTime).subtract(sensorStoredUtcCorrection);
}

String formatManilaClockTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
}

String formatManilaDateTime(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}, '
      '${formatManilaClockTime(value)} PHT';
}
