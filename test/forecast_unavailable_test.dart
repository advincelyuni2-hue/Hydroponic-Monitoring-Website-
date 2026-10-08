import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/widgets/dashboard_forecast_overview.dart';

void main() {
  testWidgets('model baseline rejection does not label a fresh sensor offline',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardForecastOverview(
            phPoints: const [],
            ecPoints: const [],
            summaries: const [],
            generatedAt: null,
            forecastIssue: 'The model cannot see a recent reading.',
            latestSensorRecordedAt: DateTime.utc(2026, 10, 8, 18, 8),
            onViewDetails: () {},
          ),
        ),
      ),
    );

    expect(find.text('Sensor offline'), findsOneWidget);
    expect(find.text('Forecast unavailable'), findsNothing);
    expect(find.text('The model cannot see a recent reading.'), findsNothing);
  });
}
