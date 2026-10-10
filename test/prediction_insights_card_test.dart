import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/forecasting_models.dart';
import 'package:monitoring_app/screens/notifications_screen.dart';
import 'package:monitoring_app/theme/theme_mode_controller.dart';
import 'package:monitoring_app/widgets/prediction_insights_card.dart';

void main() {
  for (final width in [320.0, 768.0, 1200.0]) {
    for (final dark in [false, true]) {
      testWidgets('toggle and layout at $width, dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        appThemeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          appThemeMode.value = ThemeMode.light;
        });
        var selected = 'pH';
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
          body: SingleChildScrollView(
              child: StatefulBuilder(
            builder: (context, setState) => PredictionInsightsCard(
              detail: PredictionInsightDetail(
                statusLabel: '$selected Level',
                statusBadge: 'Normal',
                warningText: '',
                temperature: '24 °C',
                ecLevel: '',
                calloutText: 'A long explanation. ' * 20,
                currentPh: 6,
                targetPh: 6,
                suggestedFixes: const [],
              ),
              forecastPoints: [
                for (final hour in [4, 8, 12])
                  ForecastingChartPoint(
                      hour: hour.toDouble(),
                      value: selected == 'pH' ? 6 : 1.5,
                      isPredicted: true)
              ],
              currentPh: 6,
              currentEc: 1.5,
              showParamSelector: true,
              selectedInsightParam: selected,
              onInsightParamChanged: (value) =>
                  setState(() => selected = value),
            ),
          )),
        )));
        await tester.pumpAndSettle();
        expect(find.text('pH Trend'), findsOneWidget);
        for (final hour in [4, 8, 12]) {
          expect(find.text('${hour}hr'), findsOneWidget);
        }
        await tester.tap(find.text('EC'));
        await tester.pumpAndSettle();
        expect(find.text('EC Trend'), findsOneWidget);
        expect(find.text('1.500000'), findsNWidgets(3));
        expect(find.text('pH level:'), findsOneWidget);
        expect(find.text('Apply fix'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('View recent notifications'));
        await tester.tap(find.text('View recent notifications'));
        await tester.pumpAndSettle();
        expect(find.byType(NotificationsScreen), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
