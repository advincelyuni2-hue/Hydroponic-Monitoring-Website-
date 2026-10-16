import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/monitoring_models.dart';
import 'package:monitoring_app/widgets/app_header.dart';
import 'package:monitoring_app/widgets/dashboard_layout.dart';
import 'package:monitoring_app/widgets/dashboard_realtime_section.dart';
import 'package:monitoring_app/widgets/dashboard_parameter_gauge.dart';
import 'package:monitoring_app/widgets/dashboard_insight_card.dart';
import 'package:monitoring_app/widgets/dashboard_forecast_overview.dart';

final _statuses = [
  ParameterStatus(
      label: 'pH',
      currentValue: '6.123456',
      unit: '',
      idealRange: '5.5 - 6.5',
      lastUpdated: 'Oct 12, 2026 10:00 AM'),
  ParameterStatus(
      label: 'EC',
      currentValue: '1.234567',
      unit: 'mS/cm',
      idealRange: '1.2 - 1.8',
      lastUpdated: 'Oct 12, 2026 10:00 AM',
      status: 'Warning'),
  ParameterStatus(
      label: 'Temperature',
      currentValue: '25.4',
      unit: '°C',
      idealRange: '20 - 28',
      lastUpdated: 'Oct 12, 2026 10:00 AM'),
];

List<ForecastPoint> _points(bool ph) => [
      for (final hour in [-12, -8, -4, 0, 4, 8, 12])
        ForecastPoint(
            hour: hour.toDouble(),
            value: ph ? 6.1 + hour / 20 : 1.8,
            isPredicted: hour > 0),
    ];

Widget _dashboard(double scale, {bool offline = false}) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
          body: DashboardLayout(
        // Supplying callbacks avoids the live notification bell/service.
        header: AppHeader(
            title: 'Dashboard', onBellTap: () {}, onProfileTap: () {}),
        realtime: DashboardRealtimeSection(
            statuses: _statuses
                .map((s) => ParameterStatus(
                    label: s.label,
                    currentValue: s.currentValue,
                    unit: s.unit,
                    idealRange: s.idealRange,
                    lastUpdated: s.lastUpdated,
                    isOffline: offline,
                    status: offline ? 'Offline' : s.status))
                .toList(),
            isOffline: offline),
        insight: DashboardInsightCard(
            phForecast: _points(true),
            ecForecast: _points(false),
            summaries: const [],
            parameterStatuses: _statuses,
            isOffline: offline,
            onViewDetails: () {}),
        overview: DashboardForecastOverview(
            phPoints: _points(true),
            ecPoints: _points(false),
            summaries: const [],
            generatedAt: DateTime(2026, 10, 12, 10),
            isOffline: offline,
            onViewDetails: () {}),
      )),
    );

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1366, 768),
    const Size(1440, 900)
  ]) {
    testWidgets('Dashboard fits and retains mode dimensions at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_dashboard(1));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final gauges = find.byType(DashboardParameterGauge);
      final gaugeSize = tester.getSize(gauges.first);
      for (var i = 1; i < 3; i++) {
        expect(tester.getSize(gauges.at(i)), gaugeSize);
      }
      // Protect the restored visual proportions, not just the card box size.
      // The old shrunken desktop arc was only 72px across.
      for (final label in ['pH', 'EC', 'Temperature']) {
        final dial = find.byKey(ValueKey('gauge-dial-$label'));
        final reading = find.byKey(ValueKey('gauge-reading-$label'));
        final unit = find.byKey(ValueKey('gauge-unit-$label'));
        final dialRect = tester.getRect(dial);
        final readingRect = tester.getRect(reading);
        final unitRect = tester.getRect(unit);
        expect(dialRect.bottom, lessThan(readingRect.top));
        expect(readingRect.bottom, lessThan(unitRect.top));
        expect(
            tester.renderObject(dial),
            paints
              ..something((method, args) {
                if (method != #drawArc) return false;
                final arc = args[0] as Rect;
                final paint = args[4] as Paint;
                final minDiameter = size.width >= 1150 ? 95.0 : 210.0;
                expect(arc.width, greaterThanOrEqualTo(minDiameter));
                expect(paint.strokeWidth, greaterThanOrEqualTo(10));
                expect(arc.left - paint.strokeWidth / 2,
                    greaterThanOrEqualTo(-0.01));
                expect(arc.right + paint.strokeWidth / 2,
                    lessThanOrEqualTo(dialRect.width + 0.01));
                return true;
              }));
      }
      final page = find
          .byType(Scrollable)
          .evaluate()
          .map((e) => (e as StatefulElement).state)
          .whereType<ScrollableState>()
          .firstWhere((s) => s.axisDirection == AxisDirection.down);
      if (size.width >= 1150) {
        expect(page.position.maxScrollExtent, 0);
        expect(tester.getBottomRight(find.byType(DashboardForecastOverview)).dy,
            lessThanOrEqualTo(size.height));
      } else {
        expect(page.position.maxScrollExtent, greaterThan(0));
        final horizontal = find
            .byType(Scrollable)
            .evaluate()
            .map((e) => (e as StatefulElement).state)
            .whereType<ScrollableState>()
            .firstWhere((s) =>
                s.axisDirection == AxisDirection.right &&
                s.position.maxScrollExtent > 0);
        horizontal.position.jumpTo(horizontal.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(
            tester.getRect(gauges.last).right, lessThanOrEqualTo(size.width));
        expect(tester.takeException(), isNull);
      }

      final insight = find.byType(DashboardInsightCard);
      final insightSize = tester.getSize(insight);
      final ec = find.descendant(of: insight, matching: find.text('EC'));
      await tester.ensureVisible(ec);
      await tester.tap(ec);
      await tester.pumpAndSettle();
      expect(tester.getSize(insight), insightSize);
      expect(tester.takeException(), isNull);

      final overview = find.byType(DashboardForecastOverview);
      final overviewSize = tester.getSize(overview);
      for (final parameter in ['pH', 'EC', 'Both']) {
        for (final hours in ['4h', '8h', '12h']) {
          for (final label in [parameter, hours]) {
            final control =
                find.descendant(of: overview, matching: find.text(label));
            await tester.ensureVisible(control);
            await tester.tap(control);
            await tester.pumpAndSettle();
          }
          expect(tester.getSize(overview), overviewSize);
          expect(tester.takeException(), isNull);
        }
      }
    });
  }

  for (final size in [const Size(390, 844), const Size(1366, 768)]) {
    testWidgets('Dashboard offline state fits at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_dashboard(1, offline: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(390, 844),
    const Size(1366, 768),
    const Size(1366, 500)
  ]) {
    testWidgets(
        'Dashboard permits scrolling with large text/short window $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_dashboard(size.height == 500 ? 1 : 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(DashboardForecastOverview));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
