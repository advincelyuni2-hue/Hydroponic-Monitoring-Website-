import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/reports_models.dart';
import 'pdf_report_output.dart';

class PdfReportService {
  Future<void> generateAndShare({
    required ReportSummaryData summary,
    required List<AnalyticsPoint> trendPoints,
    required List<PredictedAnalyticsPoint> predictionPoints,
    required RangeValues phRange,
    required RangeValues ecRange,
    required String selectedParameter,
    required bool includeSensorLogs,
    required bool includeCalibrationLogs,
    required bool includePhOptimization,
    required bool includeEcOptimization,
    required bool includeAllAnalytics,
  }) async {
    final document = pw.Document();
    final generatedAt = DateTime.now();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(),
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Hydroponic Monitoring Report'),
          ),
          pw.Text('Generated ${generatedAt.toLocal()}'),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Summary')),
          pw.TableHelper.fromTextArray(
            headers: const ['Metric', 'Value', 'Status'],
            data: [
              ['Average pH (30d)', summary.avgPh.toStringAsFixed(1), summary.phStatus],
              ['Average EC (30d)', '${summary.avgEc.toStringAsFixed(1)} mS/cm', summary.ecStatus],
              ['Critical alerts', '${summary.criticalAlertsCount}', summary.alertsPeriod],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Configuration')),
          pw.TableHelper.fromTextArray(
            headers: const ['Parameter', 'Minimum', 'Maximum'],
            data: [
              ['pH', phRange.start.toStringAsFixed(1), phRange.end.toStringAsFixed(1)],
              ['EC', ecRange.start.toStringAsFixed(1), ecRange.end.toStringAsFixed(1)],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Included sections')),
          pw.Bullet(text: 'Sensor history logs: ${includeSensorLogs ? 'Yes' : 'No'}'),
          pw.Bullet(text: 'Calibration history logs: ${includeCalibrationLogs ? 'Yes' : 'No'}'),
          pw.Bullet(text: 'pH optimization results: ${includePhOptimization ? 'Yes' : 'No'}'),
          pw.Bullet(text: 'EC optimization results: ${includeEcOptimization ? 'Yes' : 'No'}'),
          pw.Bullet(text: 'All analytics and graphs: ${includeAllAnalytics ? 'Yes' : 'No'}'),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Analytics snapshot')),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Trend value'],
            data: trendPoints
                .map((point) => [point.label, point.value.toStringAsFixed(2)])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Decision support')),
          pw.Text(_recommendation(summary, predictionPoints, selectedParameter)),
        ],
      ),
    );

    final bytes = await _buildBytes(document);
    await outputPdf(bytes, 'hydroponic-monitoring-report.pdf');
  }

  Future<Uint8List> _buildBytes(pw.Document document) => document.save();

  String _recommendation(
    ReportSummaryData summary,
    List<PredictedAnalyticsPoint> points,
    String selectedParameter,
  ) {
    final latest = points.isEmpty
        ? (selectedParameter == 'pH' ? summary.avgPh : summary.avgEc)
        : points.last.predictedValue;
    final lowerLimit = selectedParameter == 'pH' ? 5.5 : 5.0;
    final upperLimit = selectedParameter == 'pH' ? 6.5 : 6.0;

    if (latest > upperLimit) {
      return 'Recommendation: $selectedParameter is trending high. Apply a small corrective adjustment and recheck the reading after the next sensor update.';
    }
    if (latest < lowerLimit) {
      return 'Recommendation: $selectedParameter is trending low. Apply a small corrective adjustment and recheck the reading after the next sensor update.';
    }
    return 'Recommendation: $selectedParameter is within the configured target range. Continue monitoring and avoid unnecessary adjustment.';
  }
}