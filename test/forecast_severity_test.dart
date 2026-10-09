import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/forecast_insight_summary.dart';
import 'package:monitoring_app/models/forecasting_models.dart';
import 'package:monitoring_app/models/monitoring_models.dart'
    show ForecastPoint;
import 'package:monitoring_app/services/app_state.dart';
import 'package:monitoring_app/services/forecasting_service.dart';
import 'package:monitoring_app/theme/app_colors.dart';
import 'package:monitoring_app/theme/forecast_severity_style.dart';
import 'package:monitoring_app/theme/theme_mode_controller.dart';
import 'package:monitoring_app/utils/parameter_severity.dart';
import 'package:monitoring_app/utils/sensor_value_format.dart';
import 'package:monitoring_app/widgets/dashboard_insight_card.dart';
import 'package:monitoring_app/widgets/prediction_insights_card.dart';

void main() {
  test('unavailable severity uses neutral theme colors', () {
    addTearDown(() => appThemeMode.value = ThemeMode.light);
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      appThemeMode.value = mode;
      const style = ForecastSeverityStyle(null);
      expect(style.tint, AppColors.surfaceMuted);
      expect(style.text, AppColors.textSecondary);
    }
  });
  for (final range in [(5.5, 6.5), (1.2, 1.8)]) {
    test('monitoring boundaries and margin for $range', () {
      final cases = <double, ParameterSeverity>{
        range.$1: ParameterSeverity.stable,
        range.$2: ParameterSeverity.stable,
        range.$1 - 0.1: ParameterSeverity.warning,
        range.$2 + 0.1: ParameterSeverity.warning,
        range.$1 - 0.5: ParameterSeverity.warning,
        range.$2 + 0.5: ParameterSeverity.warning,
        range.$1 - 0.501: ParameterSeverity.critical,
        range.$2 + 0.501: ParameterSeverity.critical,
      };
      for (final entry in cases.entries) {
        final summary = ForecastInsightSummary(
            minimum: range.$1,
            maximum: range.$2,
            forecast: [
              for (final hour in [4, 8, 12])
                ForecastingChartPoint(
                    hour: hour.toDouble(), value: entry.key, isPredicted: true)
            ]);
        for (final hour in [4, 8, 12]) {
          expect(summary.severityAt(hour), entry.value);
          expect(
              summary.severityAt(hour),
              classifyParameterValue(
                  value: entry.key,
                  stableMin: range.$1,
                  stableMax: range.$2,
                  warningMargin: 0.5));
        }
      }
      expect(
          ForecastInsightSummary(
                  forecast: [], minimum: range.$1, maximum: range.$2)
              .severityAt(4),
          isNull);
    });
  }
  for (final parameter in ['pH', 'EC']) {
    testWidgets('$parameter colors match and react to config and theme',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        appParameterRanges.value = const ParameterRangeConfig();
        appThemeMode.value = ThemeMode.light;
      });
      appParameterRanges.value = const ParameterRangeConfig();
      appThemeMode.value = ThemeMode.light;
      final values = parameter == 'pH' ? [6.0, 6.8, 7.2] : [1.5, 2.0, 2.5];
      final points = [
        for (var i = 0; i < 3; i++)
          ForecastingChartPoint(
              hour: (i + 1) * 4.0, value: values[i], isPredicted: true)
      ];
      final dashboard = points
          .map((p) =>
              ForecastPoint(hour: p.hour, value: p.value, isPredicted: true))
          .toList();
      final detail = ForecastingService().runFlutterDSS(
          parameter: parameter.toLowerCase(),
          currentPh: 6,
          currentEc: 1.5,
          currentTemp: 24,
          predictedPh: 7.2,
          predictedEc: 2.5);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Column(children: [
        DashboardInsightCard(
            phForecast: dashboard,
            ecForecast: dashboard,
            summaries: const [],
            parameterStatuses: const [],
            onViewDetails: () {}),
        PredictionInsightsCard(
            detail: detail,
            forecastPoints: points,
            currentPh: 6,
            currentEc: 1.5),
      ])))));
      if (parameter == 'EC') {
        await tester.tap(find.text('EC'));
        await tester.pump();
      }
      void check(List<Color> backgrounds, List<Color> texts) {
        for (var i = 0; i < 3; i++) {
          final finder = find.text(formatSensorValue(values[i]));
          expect(finder, findsNWidgets(2));
          for (final element in finder.evaluate()) {
            expect((element.widget as Text).style!.color, texts[i]);
            BoxDecoration? decoration;
            element.visitAncestorElements((ancestor) {
              final widget = ancestor.widget;
              if (widget is Container && widget.decoration is BoxDecoration) {
                decoration = widget.decoration as BoxDecoration;
                return false;
              }
              return true;
            });
            expect(decoration!.color, backgrounds[i]);
          }
        }
      }

      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        appThemeMode.value = mode;
        await tester.pump();
        check([
          AppColors.statusCardGreen,
          AppColors.statusCardYellow,
          AppColors.alertBackground
        ], [
          AppColors.accentGreen,
          AppColors.warningYellow,
          AppColors.criticalRed
        ]);
      }
      appParameterRanges.value = const ParameterRangeConfig(
          phMin: 5.5, phMax: 7.5, ecMin: 1.2, ecMax: 2.8);
      await tester.pump();
      check(List.filled(3, AppColors.statusCardGreen),
          List.filled(3, AppColors.accentGreen));
      expect(tester.takeException(), isNull);
    });
  }
}
