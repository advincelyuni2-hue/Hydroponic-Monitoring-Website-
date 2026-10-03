import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/reports_models.dart';
import 'package:monitoring_app/widgets/report_analytics_card.dart';
import 'package:monitoring_app/widgets/report_prediction_card.dart';
import 'package:monitoring_app/widgets/target_distribution_card.dart';

void main() {
  testWidgets('historical trend parameter and timeframe controls respond',
      (tester) async {
    final parameters = <String>[];
    final timeframes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportsAnalyticsCard(
            selectedParameter: 'pH',
            selectedTimeframe: '7d',
            points: const [AnalyticsPoint(label: 'Oct 1', value: 6.2)],
            minThreshold: 5.5,
            maxThreshold: 6.5,
            onParameterChanged: parameters.add,
            onTimeframeChanged: timeframes.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('EC').first);
    await tester.pump();
    await tester.tap(find.text('30d'));

    expect(parameters, ['EC']);
    expect(timeframes, ['30d']);
  });

  testWidgets('forecast evaluation Both, pH, and EC controls respond',
      (tester) async {
    final selections = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportPredictionCard(
            phPoints: const [AnalyticsPoint(label: 'Oct 1', value: 6.2)],
            ecPoints: const [AnalyticsPoint(label: 'Oct 1', value: 0.37)],
            selectedParameter: 'Both',
            isLoading: false,
            errorMessage: null,
            onParameterChanged: selections.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('EC').first);
    await tester.pump();
    await tester.tap(find.text('pH').first);

    expect(selections, ['EC', 'pH']);
  });

  testWidgets('frequency distribution parameter control responds',
      (tester) async {
    final selections = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TargetDistributionCard(
            data: const TargetDistributionData(
              optimalPercentage: 80,
              warningPercentage: 15,
              criticalPercentage: 5,
            ),
            selectedParam: 'pH',
            onParamChanged: selections.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('EC').first);

    expect(selections, ['EC']);
  });
}
