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
            evaluation: ModelEvaluation.empty,
            selectedParameter: 'Both',
            selectedHorizon: 12,
            onHorizonChanged: (_) {},
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

  testWidgets('intervened forecast remains visible outside accuracy',
      (tester) async {
    const evaluation = ModelEvaluation(
      samples: [],
      horizonHours: 4,
      modelName: 'Forecast model',
      intervenedCount: 1,
      records: [
        ForecastEvaluationRecord(
          parameter: 'ph',
          targetLabel: 'Oct 9, 2026, 4:00 PM',
          predictedValue: 7.2,
          actualValue: 6.3,
          status: 'intervened',
          interventionCount: 1,
          actionType: 'pH Down',
          actionTimeLabel: 'Oct 9, 2026, 2:00 PM',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReportPredictionCard(
              evaluation: evaluation,
              selectedParameter: 'Both',
              selectedHorizon: 4,
              onHorizonChanged: (_) {},
              isLoading: false,
              errorMessage: null,
              onParameterChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Intervened'), findsOneWidget);
    expect(find.textContaining('pH Down'), findsOneWidget);
    expect(evaluation.accuracyFor('Both'), isNull);
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
