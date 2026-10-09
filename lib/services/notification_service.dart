import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';
import '../models/notification_models.dart';
import '../utils/manila_time.dart';
import '../utils/sensor_value_format.dart';
import 'supabase_client.dart';

class NotificationService {
  String? lastInterventionError;

  String _saveError(Object error) {
    if (error is PostgrestException) {
      if (error.code == 'PGRST202') {
        return 'The intervention database function is missing. Run '
            'supabase/forecast_intervention_setup.sql in the SQL Editor.';
      }
      final code = error.code;
      return code == null ? error.message : '${error.message} ($code)';
    }
    return error.toString();
  }

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
        .order('timestamp', ascending: false)
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
    final displayMessage = _formatStoredSensorText(message, parameter);
    final liveDetail = liveDetails[parameter];
    final legacyCurrent = _legacyCurrentValue(message);
    final legacyRange = _legacyIdealRange(message);
    final rawCurrentValue = _nonEmpty(row['current_value']) ??
        (legacyCurrent == 'Not recorded'
            ? liveDetail?.currentValue ?? legacyCurrent
            : legacyCurrent);
    final rawIdealRange = _nonEmpty(row['ideal_range']) ??
        (legacyRange == 'Not recorded'
            ? liveDetail?.idealRange ?? legacyRange
            : legacyRange);
    final currentValue = _formatStoredSensorText(rawCurrentValue, parameter);
    final idealRange = _formatStoredSensorText(rawIdealRange, parameter);
    final storedRecommendation = _nonEmpty(row['recommendation']);
    final hasStoredSnapshot = _nonEmpty(row['current_value']) != null &&
        _nonEmpty(row['ideal_range']) != null;
    final typeText = (row['type'] as String? ?? '').toLowerCase();
    final isCritical =
        typeText == 'critical' || message.toLowerCase().contains('critical');
    final rawTime = (row['timestamp'] ?? row['created_at'])?.toString();
    final parsed = rawTime == null ? null : DateTime.tryParse(rawTime);

    return AppNotificationItem(
      id: row['id'].toString(),
      title: _displayTitle(storedTitle, parameter),
      subtitle: displayMessage.isEmpty
          ? liveDetail?.summary ?? 'Review this notification.'
          : displayMessage,
      timestamp: parsed == null
          ? 'Recent'
          : formatManilaDateTime(toManilaTime(parsed)),
      type: isCritical
          ? NotificationType.critical
          : typeText == 'info'
              ? NotificationType.info
              : NotificationType.warning,
      currentStatus: hasStoredSnapshot
          ? _storedAlertStatus(typeText, '${storedTitle ?? ''} $message')
          : liveDetail?.statusLabel ??
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
      source: row['source']?.toString() ?? 'manual',
      lifecycleState: row['lifecycle_state']?.toString() ??
          (row['is_resolved'] == true ? 'resolved' : 'open'),
      actionTakenAt: _formatTimestamp(row['action_taken_at']),
      recoveryStartedAt: _formatTimestamp(row['recovery_started_at']),
      stableReadingCount: (row['stable_reading_count'] as num?)?.toInt() ?? 0,
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

  String _formatStoredSensorText(String text, String parameter) {
    if (parameter != 'pH Level' && parameter != 'EC Level') return text;
    return text.replaceAllMapped(RegExp(r'-?\d+\.\d+'), (match) {
      final value = double.tryParse(match.group(0)!);
      return value == null ? match.group(0)! : formatSensorValue(value);
    });
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

  String _storedAlertStatus(String type, String text) {
    final direction = _legacyStatus(text);
    final severity = type == 'critical' ? 'Critical' : 'Warning';
    return direction == 'Status unavailable'
        ? severity
        : '$direction · $severity';
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

    Map<String, dynamic>? latest;
    try {
      latest = await client
          .from('sensor_history')
          .select('avg_ph, avg_ec, avg_temp')
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (_) {
      latest = null;
    }

    return {
      'pH Level': _detail(
        parameter: 'pH',
        value: (latest?['avg_ph'] as num?)?.toDouble(),
        minimum: phMin,
        maximum: phMax,
        warningMargin: 0.5,
        unit: 'pH',
        lowRecommendation:
            'Add pH-up solution gradually, circulate, and verify the reading.',
        highRecommendation:
            'Add pH-down solution gradually, circulate, and verify the reading.',
      ),
      'EC Level': _detail(
        parameter: 'EC',
        value: (latest?['avg_ec'] as num?)?.toDouble(),
        minimum: ecMin,
        maximum: ecMax,
        warningMargin: 0.5,
        unit: 'mS/cm',
        lowRecommendation:
            'Check the nutrient mixture and replenish gradually, then verify EC.',
        highRecommendation:
            'Check concentration and dilute gradually with clean water, then verify EC.',
      ),
      'Temperature': _detail(
        parameter: 'Temperature',
        value: (latest?['avg_temp'] as num?)?.toDouble(),
        minimum: 18,
        maximum: 24,
        warningMargin: 5,
        unit: '°C',
        lowRecommendation:
            'Inspect heating and raise temperature gradually, then verify the sensor.',
        highRecommendation:
            'Improve cooling or ventilation and verify the sensor reading.',
      ),
    };
  }

  _LiveNotificationDetail _detail({
    required String parameter,
    required double? value,
    required double minimum,
    required double maximum,
    required double warningMargin,
    required String unit,
    required String lowRecommendation,
    required String highRecommendation,
  }) {
    final isTemperature = parameter == 'Temperature';
    final displayValue = value == null
        ? 'Not recorded'
        : '${isTemperature ? value.toStringAsFixed(1) : formatSensorValue(value)} $unit';
    final direction = value == null
        ? null
        : value < minimum
            ? 'Low'
            : value > maximum
                ? 'High'
                : null;
    final critical = value != null &&
        (value < minimum - warningMargin || value > maximum + warningMargin);
    final statusLabel = value == null
        ? 'No five-minute average'
        : direction == null
            ? 'Stable'
            : '$direction · ${critical ? 'Critical' : 'Warning'}';
    return _LiveNotificationDetail(
      statusLabel: statusLabel,
      currentValue: displayValue,
      idealRange: isTemperature
          ? '${minimum.toStringAsFixed(1)} - ${maximum.toStringAsFixed(1)} $unit'
          : '${formatSensorRange(minimum, maximum)} $unit',
      recommendation: value == null
          ? 'Verify the sensor connection and wait for a new reading.'
          : value < minimum
              ? lowRecommendation
              : value > maximum
                  ? highRecommendation
                  : 'The latest reading is within the configured range. Continue monitoring.',
      summary: '$parameter five-minute average is '
          '${direction?.toLowerCase() ?? 'stable'} at $displayValue.',
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

  Future<bool> recordFixAndResolve({
    required String notificationId,
    required String parameter,
    required double currentValue,
    required String currentStatus,
    required String actionType,
    double? amount,
    required String notes,
    double? reservoirVolumeL,
  }) async {
    final client = supabaseClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      lastInterventionError = 'Sign in before recording an intervention.';
      return false;
    }

    try {
      lastInterventionError = null;
      final actionId = await client.rpc(
        'record_notification_intervention',
        params: {
          'notification_id_value': notificationId,
          'parameter_value': parameter,
          'current_value_value': currentValue,
          'current_status_value': currentStatus,
          'action_type_value': actionType,
          'amount_value': amount,
          'notes_value': notes,
          'reservoir_volume_l_value': reservoirVolumeL,
        },
      );
      if (actionId == null) {
        lastInterventionError = 'The database did not return an action log ID.';
        return false;
      }
      return true;
    } catch (error) {
      lastInterventionError = _saveError(error);
      return false;
    }
  }

  Future<bool> recordManualIntervention({
    required String parameter,
    required double currentValue,
    required String actionType,
    required DateTime performedAtManila,
    double? amount,
    required String notes,
    double? reservoirVolumeL,
  }) async {
    final client = supabaseClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      lastInterventionError = 'Sign in before recording an intervention.';
      return false;
    }

    try {
      lastInterventionError = null;
      final actionId = await client.rpc(
        'record_manual_intervention_at',
        params: {
          'parameter_value': parameter,
          'current_value_value': currentValue,
          'action_type_value': actionType,
          'amount_value': amount,
          'notes_value': notes,
          'reservoir_volume_l_value': reservoirVolumeL,
          'performed_at_value':
              manilaWallTimeToUtc(performedAtManila).toIso8601String(),
        },
      );
      if (actionId == null) {
        lastInterventionError = 'The database did not return an action log ID.';
        return false;
      }
      return true;
    } catch (error) {
      lastInterventionError = error is PostgrestException &&
              error.code == 'PGRST202'
          ? 'The dated intervention function is missing. Run '
              'supabase/manual_intervention_time_setup.sql in the SQL Editor.'
          : _saveError(error);
      return false;
    }
  }

  RealtimeChannel? subscribeToAdminAlerts({
    required void Function() onAlert,
  }) {
    final client = supabaseClient;
    if (client == null || appProfile.value?.isAdmin != true) return null;
    return client
        .channel('admin-alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (_) => onAlert(),
        )
        .subscribe();
  }

  RealtimeChannel? subscribeToNotifications({
    required void Function() onNotification,
  }) {
    final client = supabaseClient;
    if (client == null || client.auth.currentUser == null) return null;
    return client
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (_) => onNotification(),
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
    if (client == null || appProfile.value?.isAdmin != true) return 0;
    final rows =
        await client.from('notifications').select('id').eq('status', 'unread');
    return rows.length;
  }

  Future<int> unreadNotificationCount() async {
    final client = supabaseClient;
    if (client == null || client.auth.currentUser == null) return 0;
    final rows = await client
        .from('notifications')
        .select('id, status, is_read, is_resolved');
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .where(
          (row) =>
              row['status'] != 'read' &&
              row['is_read'] != true &&
              row['is_resolved'] != true,
        )
        .length;
  }

  Future<List<AppNotification>> getNotifications() async {
    final client = supabaseClient;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      final isAdmin = appProfile.value?.isAdmin == true;
      final query = client
          .from('notifications')
          .select('id, message, status, timestamp, created_at');
      final rows = isAdmin
          ? await query.order('created_at', ascending: false).limit(10)
          : await query
              .eq('employee_id', user.id)
              .order('created_at', ascending: false)
              .limit(10);
      return (rows as List).cast<Map<String, dynamic>>().map((row) {
        final critical = (row['message'] as String? ?? '')
            .toLowerCase()
            .contains('critical');
        return AppNotification(
          id: row['id'].toString(),
          databaseId: row['id'].toString(),
          title: critical ? 'Critical alert' : 'Notification',
          detail: row['message'] as String? ?? '',
          timeAgo: _timeAgo(DateTime.tryParse(
              (row['timestamp'] ?? row['created_at']) as String? ?? '')),
          isCritical: critical,
        );
      }).toList();
    }
    return const [];
  }

  String _timeAgo(DateTime? timestamp) {
    if (timestamp == null) return 'Recent';
    final difference = DateTime.now().difference(timestamp.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
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

/// A single notification/alert shown in the dashboard.
class AppNotification {
  final String id;
  final String title;
  final String detail;
  final String timeAgo;
  final bool isCritical;
  final String? databaseId;

  AppNotification({
    required this.id,
    required this.title,
    required this.detail,
    required this.timeAgo,
    required this.isCritical,
    this.databaseId,
  });
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
