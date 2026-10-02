import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/models/reports_models.dart';
import 'package:monitoring_app/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a PDF when report readings are empty', () async {
    Uint8List? outputBytes;
    final service = PdfReportService(
      output: (bytes, _) async => outputBytes = bytes,
    );

    await service.generateAndShare(
      reportData: _emptyReportData(),
      timeframe: '30d',
      includeSensorLogs: false,
      includeCalibrationLogs: false,
      includePhOptimization: false,
      includeEcOptimization: false,
      includeAllAnalytics: true,
    );

    expect(outputBytes, isNotNull);
    expect(String.fromCharCodes(outputBytes!.take(4)), '%PDF');
  });

  test('builds charts with a single daily reading', () async {
    Uint8List? outputBytes;
    final service = PdfReportService(
      output: (bytes, _) async => outputBytes = bytes,
    );
    final reading = ReportReading(
      recordedAt: DateTime(2026, 9, 1, 8),
      value: 6.1,
      parameter: 'pH',
      status: 'Normal',
    );
    final reportData = PdfReportData(
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 30),
      phReadings: [reading],
      ecReadings: const [],
      temperatureReadings: const [],
      phSummaryReadings: [reading],
      ecSummaryReadings: const [],
      calibrationLogs: const [],
      phMin: 5.5,
      phMax: 6.5,
      ecMin: 1.2,
      ecMax: 1.8,
      criticalAlertsCount: 0,
    );

    await service.generateAndShare(
      reportData: reportData,
      timeframe: '30d',
      includeSensorLogs: false,
      includeCalibrationLogs: false,
      includePhOptimization: false,
      includeEcOptimization: false,
      includeAllAnalytics: true,
    );

    expect(outputBytes, isNotNull);
    expect(String.fromCharCodes(outputBytes!.take(4)), '%PDF');
  });

  test('builds charts and selected optional report sections', () async {
    Uint8List? outputBytes;
    final service = PdfReportService(
      output: (bytes, _) async => outputBytes = bytes,
    );
    final readings = List.generate(
      35,
      (index) => ReportReading(
        recordedAt: DateTime(2026, 9, 1 + index, 8),
        value: 6.1 + index % 4 * 0.1,
        parameter: 'pH',
        status: 'Normal',
      ),
    );
    final reportData = PdfReportData(
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 30),
      phReadings: readings,
      ecReadings: List.generate(
        35,
        (index) => ReportReading(
          recordedAt: DateTime(2026, 9, 1 + index, 8),
          value: 1.5 + index % 4 * 0.1,
          parameter: 'EC',
          status: 'Normal',
        ),
      ),
      temperatureReadings: [
        ReportReading(
          recordedAt: DateTime(2026, 9, 1, 8),
          value: 24,
          parameter: 'Temperature',
          status: 'Normal',
        ),
      ],
      phSummaryReadings: readings,
      ecSummaryReadings: const [],
      calibrationLogs: List.generate(
        35,
        (index) => ReportCalibrationLog(
          recordedAt: DateTime(2026, 9, 1 + index, 7),
          parameter: 'pH',
          calibrationType: 'Routine',
          adjustment: '0.01',
          performedBy: 'Employee',
          status: 'Completed',
        ),
      ),
      phMin: 5.5,
      phMax: 6.5,
      ecMin: 1.2,
      ecMax: 1.8,
      criticalAlertsCount: 0,
    );

    await service.generateAndShare(
      reportData: reportData,
      timeframe: '30d',
      includeSensorLogs: true,
      includeCalibrationLogs: true,
      includePhOptimization: true,
      includeEcOptimization: true,
      includeAllAnalytics: true,
    );

    expect(outputBytes, isNotNull);
    expect(String.fromCharCodes(outputBytes!.take(4)), '%PDF');
    expect(outputBytes!.length, greaterThan(5000));
  });
}

PdfReportData _emptyReportData() => PdfReportData(
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 30),
      phReadings: const [],
      ecReadings: const [],
      temperatureReadings: const [],
      phSummaryReadings: const [],
      ecSummaryReadings: const [],
      calibrationLogs: const [],
      phMin: 5.5,
      phMax: 6.5,
      ecMin: 1.2,
      ecMax: 1.8,
      criticalAlertsCount: 0,
    );
