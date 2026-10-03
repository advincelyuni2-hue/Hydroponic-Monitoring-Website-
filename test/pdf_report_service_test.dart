import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/monitoring_models.dart';
import 'package:monitoring_app/models/reports_models.dart';
import 'package:monitoring_app/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates a PDF containing the selected report sections', () async {
    final service = PdfReportService(
      output: (bytes, filename) async {
        expect(bytes, isNotEmpty);
        expect(filename, 'hydroponic-monitoring-report.pdf');
      },
    );

    await service.generateAndShare(
      summary: const ReportSummaryData(
        avgPh: 6.2,
        phStatus: 'In range',
        avgEc: 1.5,
        ecStatus: 'Stable',
        avgTemp: 24,
        tempStatus: 'In range',
        criticalAlertsCount: 1,
        alertsPeriod: 'This month',
      ),
      trendPoints: const [
        AnalyticsPoint(label: 'Oct 1', value: 6.2, parameter: 'pH'),
        AnalyticsPoint(label: 'Oct 2', value: 6.3, parameter: 'pH'),
        AnalyticsPoint(label: 'Oct 1', value: 1.5, parameter: 'EC'),
        AnalyticsPoint(label: 'Oct 2', value: 1.6, parameter: 'EC'),
      ],
      predictionPoints: const [
        PredictedAnalyticsPoint(
          label: 'Oct 1',
          actualValue: 6.2,
          predictedValue: 6.3,
        ),
      ],
      sensorLogs: const [
        HistoryLogEntry([
          'October 1, 2026',
          'All day',
          '6.20',
          '1.50 mS/cm',
          '24.0 deg C',
          'Stable',
        ]),
      ],
      calibrationLogs: const [
        HistoryLogEntry([
          'October 1, 2026 8:00 AM',
          'pH',
          '2-Point Calibration',
          '+0.1',
          'Operator',
          'Success',
        ]),
      ],
      phRange: const RangeValues(5.5, 6.5),
      ecRange: const RangeValues(1.2, 1.8),
      selectedParameter: 'pH',
      includeSensorLogs: true,
      includeCalibrationLogs: true,
      includePhOptimization: true,
      includeEcOptimization: true,
      includeAllAnalytics: true,
    );
  });
}
