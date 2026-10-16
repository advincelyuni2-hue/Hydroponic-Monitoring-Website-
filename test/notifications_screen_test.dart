import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/controllers/notification_controller.dart';
import 'package:monitoring_app/models/notification_models.dart';
import 'package:monitoring_app/services/notification_service.dart';
import 'package:monitoring_app/screens/notifications_screen.dart';
import 'package:monitoring_app/screens/add_log_screen.dart';
import 'package:monitoring_app/theme/theme_mode_controller.dart';

AppNotificationItem item(String id,
        {bool resolved = false, bool sensor = false}) =>
    AppNotificationItem(
        id: id,
        title: sensor ? 'pH Level High' : 'Employee alert $id',
        subtitle: 'Notification description $id',
        timestamp: 'Oct 9, 2026, 7:50 PM',
        createdAt: DateTime.utc(2026, 10, 9, int.parse(id)),
        type: sensor ? NotificationType.critical : NotificationType.info,
        currentStatus: sensor ? 'High ? Critical' : 'Open',
        currentValue: '7.5 pH',
        idealRange: '5.5 - 6.5 pH',
        recommendation: 'Verify the reading.',
        source: sensor ? 'sensor' : 'manual',
        isResolved: resolved);

class FakeNotifications extends NotificationService {
  final rows = [item('1'), item('2', sensor: true), item('3', resolved: true)];
  int resolutions = 0;
  @override
  Stream<List<AppNotificationItem>> streamNotificationItems() =>
      Stream.value(rows);
  @override
  Future<bool> updateAlertResolved(String id, bool resolved) async {
    resolutions++;
    return true;
  }

  @override
  Future<List<AppNotificationItem>> getNotificationItems(
          {int limit = 10, bool activeOnly = false}) async =>
      rows;
}

void main() {
  Future<FakeNotifications> mount(WidgetTester tester, double width,
      {bool dark = false}) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    appThemeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
    final service = FakeNotifications();
    final controller = NotificationController(service: service);
    addTearDown(() {
      controller.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      appThemeMode.value = ThemeMode.light;
    });
    await tester.pumpWidget(
        MaterialApp(home: NotificationsScreen(controller: controller)));
    await tester.pumpAndSettle();
    return service;
  }

  for (final dark in [false, true]) {
    testWidgets('desktop selection, checkbox, tabs and actions dark=$dark',
        (tester) async {
      final service = await mount(tester, 1200, dark: dark);
      expect(find.byKey(const ValueKey('notification-details')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('check-1')));
      await tester.pump();
      expect(find.byKey(const ValueKey('notification-details')), findsNothing);
      expect(find.text('Selected (1)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('open-2')));
      await tester.pump();
      expect(
          find.byKey(const ValueKey('notification-details')), findsOneWidget);
      expect(find.text('Mark resolved'), findsNothing);
      await tester.tap(find.text('Record action'));
      await tester.pumpAndSettle();
      expect(find.byType(RecordFixCard), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.resolutions, 0);
      await tester.tap(find.byTooltip('Close details'));
      await tester.pump();
      expect(find.byKey(const ValueKey('notification-details')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('open-1')));
      await tester.pump();
      await tester.tap(find.text('Mark resolved'));
      await tester.pumpAndSettle();
      expect(service.resolutions, 1);
      expect(find.byKey(const ValueKey('open-1')), findsNothing);
      await tester.tap(find.text('Resolved').first);
      await tester.pump();
      expect(find.byKey(const ValueKey('open-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('open-3')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('filters search and date sorting combine', (tester) async {
    await mount(tester, 1200);
    expect(tester.getTopLeft(find.byKey(const ValueKey('open-2'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('open-1'))).dy));
    await tester.tap(find.text('By Date: newest'));
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const ValueKey('open-1'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('open-2'))).dy));
    await tester.tap(find.byTooltip('Filter notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('critical').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-1')), findsNothing);
    expect(find.byKey(const ValueKey('open-2')), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Search notifications'), 'unmatched');
    await tester.pump();
    expect(find.byKey(const ValueKey('open-2')), findsNothing);
  });
  for (final width in [390.0, 768.0]) {
    testWidgets('mobile/tablet detail route and back at $width',
        (tester) async {
      await mount(tester, width);
      await tester.tap(find.byKey(const ValueKey('open-2')));
      await tester.pumpAndSettle();
      expect(find.text('Notification details'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notification-details')), findsNothing);
      expect(find.byKey(const ValueKey('open-2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
