import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/forecasting_models.dart';
import 'package:monitoring_app/models/monitoring_models.dart'
    show ForecastPoint;
import 'package:monitoring_app/models/forecast_insight_summary.dart';
import 'package:monitoring_app/services/app_state.dart';
import 'package:monitoring_app/services/forecasting_service.dart';
import 'package:monitoring_app/utils/sensor_value_format.dart';
import 'package:monitoring_app/widgets/dashboard_insight_card.dart';
import 'package:monitoring_app/widgets/prediction_insights_card.dart';

void main() {
  for (final parameter in ['pH', 'EC']) {
    for (final width in [390.0, 1200.0]) {
      testWidgets('$parameter cards agree at width $width', (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        appParameterRanges.value = const ParameterRangeConfig();
        final values = parameter == 'pH' ? [6.7, 6.5, 6.4] : [1.89, 1.8, 1.77];
        final points = [
          for (var i = 0; i < 3; i++)
            ForecastingChartPoint(
                hour: (i + 1) * 4.0, value: values[i], isPredicted: true)
        ];
        final dashboardPoints = points
            .map((p) =>
                ForecastPoint(hour: p.hour, value: p.value, isPredicted: true))
            .toList();
        final summary = ForecastInsightSummary(
            forecast: points,
            minimum: parameter == 'pH' ? 5.5 : 1.2,
            maximum: parameter == 'pH' ? 6.5 : 1.8);
        final detail = ForecastingService().runFlutterDSS(
            parameter: parameter.toLowerCase(),
            currentPh: 6.7,
            currentEc: 1.89,
            currentTemp: 24,
            predictedPh: 6.4,
            predictedEc: 1.77);
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: Column(children: [
          DashboardInsightCard(
              phForecast: dashboardPoints,
              ecForecast: dashboardPoints,
              summaries: const [],
              parameterStatuses: const [],
              onViewDetails: () {}),
          PredictionInsightsCard(
              detail: detail,
              forecastPoints: points,
              currentPh: 6.7,
              currentEc: 1.89),
        ])))));
        if (parameter == 'EC') {
          await tester.tap(find.text('EC'));
          await tester.pump();
        }
        for (final value in values) {
          expect(find.text(formatSensorValue(value)), findsNWidgets(2));
        }
        expect(find.text('Falling'), findsNWidgets(2));
        expect(find.textContaining(summary.crossingLabel, findRichText: true),
            findsNWidgets(2));
        expect(
            find.textContaining(
                summary.thresholdLabel(unit: parameter == 'EC' ? 'mS/cm' : ''),
                findRichText: true),
            findsNWidgets(2));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
