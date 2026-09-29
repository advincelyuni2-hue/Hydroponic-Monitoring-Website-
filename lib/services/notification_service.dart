import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_models.dart';
import '../utils/manila_time.dart';
import 'supabase_client.dart';

class NotificationService {
  Future<List<AppNotificationItem>> getNotificationItems({
    int limit = 10,
    bool activeOnly = false,
  }) async {
    final client = supabaseClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return const [];

    final query = client.from('notifications').select();
    final rows = activeOnly
        ? await query
            .eq('is_resolved', false)
            .order('created_at', ascending: false)
            .limit(limit)
        : await query.order('created_at', ascending: false).limit(limit);
    return _mapNotificationRows(
      (rows as List).cast<Map<String, dynamic>>(),
    );
  }

  Stream<List<AppNotificationItem>> streamNotificationItems() {
    final client = supabaseClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return Stream.value(const <AppNotificationItem>[]);
    }

    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap(_mapNotificationRows);
  }

  Future<List<AppNotificationItem>> _mapNotificationRows(
    List<Map<String, dynamic>> rows,
  ) async {
    final liveDetails = await _loadLiveDetails();
    return rows.map((row) => _mapToNotificationItem(row, liveDetails)).toList();
  }

  AppNotificationItem _mapToNotificationItem(
    Map<String, dynamic> row,
    Map<String, _LiveNotificationDetail> liveDetails,
  ) {
    final message = row['message'] as String? ?? '';
    final storedTitle = _nonEmpty(row['title']);
    final parameter = _nonEmpty(row['parameter']) ??
        _legacyParameter('${storedTitle ?? ''} $message');
    final liveDetail = liveDetails[parameter];
    final legacyCurrent = _legacyCurrentValue(message);
    final legacyRange = _legacyIdealRange(message);
    final currentValue = _nonEmpty(row['current_value']) ??
        (legacyCurrent == 'Not recorded'
            ? liveDetail?.currentValue ?? legacyCurrent
            : legacyCurrent);
    final idealRange = _nonEmpty(row['ideal_range']) ??
        (legacyRange == 'Not recorded'
            ? liveDetail?.idealRange ?? legacyRange
            : legacyRange);
    final storedRecommendation = _nonEmpty(row['recommendation']);
    final typeText = (row['type'] as String? ?? '').toLowerCase();
    final isCritical =
        typeText == 'critical' || message.toLowerCase().contains('critical');
    final rawTime = (row['timestamp'] ?? row['created_at'])?.toString();
    final parsed = rawTime == null ? null : DateTime.tryParse(rawTime);

    return AppNotificationItem(
      id: row['id'].toString(),
      title: _displayTitle(storedTitle, parameter),
      subtitle: message.isEmpty
          ? liveDetail?.summary ?? 'Review this notification.'
          : message,
      timestamp: parsed == null
          ? 'Recent'
          : formatManilaDateTime(toManilaTime(parsed)),
      type: isCritical
          ? NotificationType.critical
          : typeText == 'info'
              ? NotificationType.info
              : NotificationType.warning,
      currentStatus: liveDetail?.statusLabel ??
          _legacyStatus('${storedTitle ?? ''} $message'),
      currentValue: currentValue,
      idealRange: idealRange,
      recommendation: storedRecommendation != null &&
              !_isGenericRecommendation(
                storedRecommendation,
                storedTitle,
                message,
              )
          ? storedRecommendation
          : liveDetail?.recommendation ??
              _legacyRecommendation(parameter, message),
      isRead: row['status'] == 'read' || row['is_read'] == true,
      isResolved: row['is_resolved'] == true,
      resolvedByName: row['resolved_by_name'] as String?,
      resolvedAt: _formatTimestamp(row['resolved_at']),
    );
  }

  String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _legacyParameter(String message) {
    final lower = message.toLowerCase();
    if (RegExp(r'\bp\s*h\b').hasMatch(lower)) {
      return 'pH Level';
    }
    if (RegExp(r'\bec\b').hasMatch(lower)) {
      return 'EC Level';
    }
    if (lower.contains('temperature') || RegExp(r'\btemp\b').hasMatch(lower)) {
      return 'Temperature';
    }
    return '';
  }

  String _displayTitle(String? storedTitle, String parameter) {
    final normalized = storedTitle?.trim().toLowerCase();
    final isGeneric = normalized == null ||
        normalized.isEmpty ||
        normalized == 'notification' ||
        normalized == 'alert' ||
        normalized == 'warning' ||
        normalized == 'warning alert';
    if (!isGeneric) return storedTitle!;
    return parameter.isEmpty ? 'Notification' : '$parameter alert';
  }

  String _legacyStatus(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('high')) return 'High';
    if (lower.contains('low')) return 'Low';
    if (lower.contains('drift')) return 'Drifting';
    return 'Status unavailable';
  }

  bool _isGenericRecommendation(
    String recommendation,
    String? title,
    String message,
  ) {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

    final normalized = normalize(recommendation);
    return normalized.isEmpty ||
        normalized == normalize(message) ||
        normalized == normalize(title ?? '') ||
        RegExp(r'^(high|low|drifting?) (ph|ec|temperature|temp)$')
            .hasMatch(normalized);
  }

  String _legacyCurrentValue(String message) {
    final match = RegExp(
      r'(?:reading|at)\s+(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(message);
    return match?.group(1) ?? 'Not recorded';
  }

  String _legacyIdealRange(String message) {
    final match = RegExp(
      r'range\s*\(([^)]+)\)',
      caseSensitive: false,
    ).firstMatch(message);
    return match?.group(1) ?? 'Not recorded';
  }

  String _legacyRecommendation(String parameter, String message) {
    final current = double.tryParse(_legacyCurrentValue(message));
    final rangeMatch = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*-\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(_legacyIdealRange(message));
    final minimum = double.tryParse(rangeMatch?.group(1) ?? '');
    final isLow = current != null && minimum != null && current < minimum;

    if (parameter == 'pH Level') {
      return isLow
          ? 'Add pH-up solution gradually, circulate, and verify the reading.'
          : 'Add pH-down solution gradually, circulate, and verify the reading.';
    }
    if (parameter == 'EC Level') {
      return isLow
          ? 'Check the nutrient mixture and replenish gradually, then verify EC.'
          : 'Check concentration and dilute gradually with clean water, then verify EC.';
    }
    if (parameter == 'Temperature') {
      return isLow
          ? 'Inspect heating and raise temperature gradually, then verify the sensor.'
          : 'Improve cooling or ventilation and verify the sensor reading.';
    }
    return message.isEmpty ? 'Review this notification.' : message;
  }

  Future<Map<String, _LiveNotificationDetail>> _loadLiveDetails() async {
    final client = supabaseClient;
    if (client == null) return const {};

    double phMin = 5.5;
    double phMax = 6.5;
    double ecMin = 1.2;
    double ecMax = 1.8;
    try {
      final config = await client
          .from('parameter_configurations')
          .select('ph_min, ph_max, ec_min, ec_max')
          .eq('id', 1)
          .maybeSingle();
      phMin = (config?['ph_min'] as num?)?.toDouble() ?? phMin;
      phMax = (config?['ph_max'] as num?)?.toDouble() ?? phMax;
      ecMin = (config?['ec_min'] as num?)?.toDouble() ?? ecMin;
      ecMax = (config?['ec_max'] as num?)?.toDouble() ?? ecMax;
    } catch (_) {
      // Fall back to the same ranges used by the realtime dashboard.
    }

    final values = await Future.wait([
      _latestRawValue('ph_readings'),
      _latestRawValue('ec_readings'),
      _latestRawValue('temp_readings'),
    ]);

    return {
      'pH Level': _detail(
        parameter: 'pH',
        value: values[0],
        minimum: phMin,
        maximum: phMax,
        unit: 'pH',
        lowRecommendation:
            'Add pH-up solution gradually, circulate, and verify the reading.',
        highRecommendation:
            'Add pH-down solution gradually, circulate, and verify the reading.',
      ),
      'EC Level': _detail(
        parameter: 'EC',
        value: values[1],
        minimum: ecMin,
        maximum: ecMax,
        unit: 'mS/cm',
        lowRecommendation:
            'Check the nutrient mixture and replenish gradually, then verify EC.',
        highRecommendation:
            'Check concentration and dilute gradually with clean water, then verify EC.',
      ),
      'Temperature': _detail(
        parameter: 'Temperature',
        value: values[2],
        minimum: 18,
        maximum: 28,
        unit: '°C',
        lowRecommendation:
            'Inspect heating and raise temperature gradually, then verify the sensor.',
        highRecommendation:
            'Improve cooling or ventilation and verify the sensor reading.',
      ),
    };
  }

  Future<double?> _latestRawValue(String table) async {
    final client = supabaseClient;
    if (client == null) return null;
    try {
      final row = await client
          .from(table)
          .select('value')
          .eq('is_average', false)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row?['value'] as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }

  _LiveNotificationDetail _detail({
    required String parameter,
    required double? value,
    required double minimum,
    required double maximum,
    required String unit,
    required String lowRecommendation,
    required String highRecommendation,
  }) {
    final displayValue = value == null ? 'Not recorded' : '$value $unit';
    final direction = value == null
        ? 'unknown'
        : value < minimum
            ? 'low'
            : value > maximum
                ? 'high'
                : 'within range';
    final statusLabel = value == null
        ? 'No live reading'
        : value < minimum
            ? 'Low'
            : value > maximum
                ? 'High'
                : 'Within range';
    return _LiveNotificationDetail(
      statusLabel: statusLabel,
      currentValue: displayValue,
      idealRange: '$minimum - $maximum $unit',
      recommendation: value == null
          ? 'Verify the sensor connection and wait for a new reading.'
          : value < minimum
              ? lowRecommendation
              : value > maximum
                  ? highRecommendation
                  : 'The latest reading is within the configured range. Continue monitoring.',
      summary: '$parameter is $direction at $displayValue.',
    );
  }

  String? _formatTimestamp(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    return parsed == null ? null : formatManilaDateTime(toManilaTime(parsed));
  }

  Future<bool> updateAlertResolved(String id, bool isResolved) async {
    final client = supabaseClient;
    if (client == null) return false;
    try {
      await client
          .from('notifications')
          .update({'is_resolved': isResolved}).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  RealtimeChannel? subscribeToAdminAlerts({
    required void Function() onAlert,
  }) {
    final client = supabaseClient;
    if (client == null || client.auth.currentUser == null) return null;
    return client
        .channel('admin-alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (_) => onAlert(),
        )
        .subscribe();
  }

  Future<void> sendAdminAlert(String message) async {
    final client = supabaseClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('An authenticated Supabase session is required.');
    }
    await client.from('notifications').insert({
      'employee_id': user.id,
      'source': 'manual',
      'title': 'Employee alert',
      'message': message,
      'type': 'info',
      'recommendation': message,
      'status': 'unread',
    });
  }

  Future<int> unreadAdminAlertCount() async {
    final client = supabaseClient;
    if (client == null || client.auth.currentUser == null) return 0;
    final rows = await client
        .from('notifications')
        .select('id')
        .eq('is_read', false)
        .eq('is_resolved', false);
    return rows.length;
  }

  Future<bool> markAsRead(String notificationId) async {
    final client = supabaseClient;
    if (client == null) return false;
    await client
        .from('notifications')
        .update({'status': 'read'}).eq('id', notificationId);
    return true;
  }

  Future<bool> deleteNotification(String notificationId) async {
    final client = supabaseClient;
    if (client == null) return false;
    await client.from('notifications').delete().eq('id', notificationId);
    return true;
  }
}

class _LiveNotificationDetail {
  final String statusLabel;
  final String currentValue;
  final String idealRange;
  final String recommendation;
  final String summary;

  const _LiveNotificationDetail({
    required this.statusLabel,
    required this.currentValue,
    required this.idealRange,
    required this.recommendation,
    required this.summary,
  });
}
