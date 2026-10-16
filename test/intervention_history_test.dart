import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/services/monitoring_service.dart';

void main() {
  test('saved intervention fields become an action history row', () {
    final entry = MonitoringService.interventionEntryFromRow({
      'performed_at': '2026-10-08T18:30:00Z',
      'parameter': 'ph',
      'action_type': 'pH Down',
      'amount': null,
      'amount_unit': 'mL',
      'notes': 'Adjusted after warning',
      'source': 'notification_fix',
    });

    expect(entry.values, [
      'Oct 9, 2026',
      '2:30 AM',
      'ph',
      'pH Down',
      '—',
      'Adjusted after warning',
      'Notification',
    ]);
  });
}
