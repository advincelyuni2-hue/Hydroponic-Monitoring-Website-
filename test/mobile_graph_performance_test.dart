import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/widgets/mobile_graph_card.dart';

void main() {
  var tappedPoint = false;
  Future<void> mount(WidgetTester tester) async {
    tappedPoint = false;
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final notifier = ValueNotifier(0);
    addTearDown(notifier.dispose);
    final spots = [
      for (var i = 0; i < 20; i++) FlSpot(i.toDouble(), 5 + (i % 3).toDouble()),
      const FlSpot(19.00000001, 6),
    ];
    await tester.pumpWidget(MaterialApp(
        home: MobileGraphPage(
      title: 'Forecast',
      listenable: notifier,
      builder: (_) => MobileGraphComposition(chartIndex: 1, children: [
        const Text('Controls'),
        SizedBox(
            height: 320,
            child: MobileGraphTimeline(
                pointCount: spots.length,
                child: MobileLineChart(
                    continuousTimeLabels: true,
                    LineChartData(
                      minX: 0,
                      maxX: 20,
                      minY: 0,
                      maxY: 10,
                      lineTouchData:
                          LineTouchData(touchCallback: (event, response) {
                        if (event is FlTapUpEvent &&
                            (response?.lineBarSpots?.isNotEmpty ?? false)) {
                          tappedPoint = true;
                        }
                      }),
                      lineBarsData: [LineChartBarData(spots: spots)],
                    ),
                    preserveAxes: true))),
        const Text('Legend'),
      ]),
    )));
    await tester.pumpAndSettle();
  }

  testWidgets('details fully hide and reopen from the floating arrow',
      (tester) async {
    await mount(tester);
    expect(find.text('Controls'), findsNothing);
    expect(find.byTooltip('Expand details'), findsOneWidget);
    await tester.tap(find.byTooltip('Expand details'));
    await tester.pumpAndSettle();
    expect(find.text('Controls'), findsOneWidget);
    expect(find.text('Legend'), findsOneWidget);
    await tester.tap(find.byTooltip('Collapse details'));
    await tester.pumpAndSettle();
    expect(find.text('Controls'), findsNothing);
    expect(find.text('Legend'), findsNothing);
    expect(find.byTooltip('Expand details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'fixed axes do not duplicate series; near timestamps keep width bounded',
      (tester) async {
    await mount(tester);
    final charts =
        tester.widgetList<LineChart>(find.byType(LineChart)).toList();
    expect(charts.where((chart) => chart.data.lineBarsData.isNotEmpty),
        hasLength(1));
    final plot = find.byWidgetPredicate(
        (widget) => widget is LineChart && widget.data.lineBarsData.isNotEmpty);
    expect(tester.getSize(plot).width, lessThan(5000));
    expect(tester.widget<LineChart>(plot).data.lineBarsData.single.spots,
        hasLength(21));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrollable time axis has intermediate ticks', (tester) async {
    await mount(tester);
    final chart = tester.widgetList<LineChart>(find.byType(LineChart))
        .firstWhere((chart) => chart.data.lineBarsData.isNotEmpty).data;
    final interval = chart.titlesData.topTitles.sideTitles.interval!;
    expect(interval, greaterThan(0));
    expect((chart.maxX - chart.minX) / interval, greaterThan(3));
    expect(chart.titlesData.bottomTitles.sideTitles.showTitles, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plot pans scroll both axes and taps still identify data points',
      (tester) async {
    await mount(tester);
    ScrollableState scroll(Axis axis) => tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .firstWhere((state) =>
            axisDirectionToAxis(state.axisDirection) == axis &&
            state.position.maxScrollExtent > 100);
    final horizontal = scroll(Axis.horizontal);
    final vertical = scroll(Axis.vertical);
    await tester.dragFrom(const Offset(210, 280), const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(horizontal.position.pixels, greaterThan(0));
    await tester.dragFrom(const Offset(210, 280), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(vertical.position.pixels, greaterThan(0));
    // Tap a visible point after scrolling.
    final plotFinder = find.byWidgetPredicate(
        (widget) => widget is LineChart && widget.data.lineBarsData.isNotEmpty);
    final chart = tester.widget<LineChart>(plotFinder).data;
    final rect = tester.getRect(find.descendant(of: plotFinder,
      matching: find.byWidgetPredicate((widget) =>
        widget.runtimeType.toString() == 'LineChartLeaf')));
    Offset position(FlSpot spot) => Offset(
      rect.left + (spot.x - chart.minX) / (chart.maxX - chart.minX) * rect.width,
      rect.top + (chart.maxY - spot.y) /
          (chart.maxY - chart.minY) * rect.height,
    );
    final visiblePoint = chart.lineBarsData.first.spots.map(position).firstWhere(
      (point) => point.dx > 80 && point.dx < 330 &&
          point.dy > 120 && point.dy < 700);
    await tester.tapAt(visiblePoint);
    await tester.pumpAndSettle();
    expect(tappedPoint, isTrue);
    expect(tester.takeException(), isNull);
  });
}
