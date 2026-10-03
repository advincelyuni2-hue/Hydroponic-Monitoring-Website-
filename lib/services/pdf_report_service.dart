import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/monitoring_models.dart';
import '../models/reports_models.dart';
import 'pdf_report_output.dart';

const _primaryGreen = PdfColor(0.15, 0.39, 0.08);
const _borderColor = PdfColor(0.72, 0.74, 0.72);
const _mutedText = PdfColor(0.38, 0.42, 0.37);
const _pHColor = PdfColor(0.15, 0.39, 0.08);
const _ecColor = PdfColor(0.08, 0.60, 0.66);

class PdfReportService {
  final Future<void> Function(Uint8List bytes, String filename) _outputPdf;

  PdfReportService({
    Future<void> Function(Uint8List bytes, String filename)? output,
  }) : _outputPdf = output ?? outputPdf;

  Future<void> generateAndShare({
    required ReportSummaryData summary,
    required List<AnalyticsPoint> trendPoints,
    required List<PredictedAnalyticsPoint> predictionPoints,
    required List<HistoryLogEntry> sensorLogs,
    required List<HistoryLogEntry> calibrationLogs,
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
    final leftLogoBytes = (await rootBundle.load('assets/images/logo_left.png'))
        .buffer
        .asUint8List();
    final rightLogoBytes =
        (await rootBundle.load('assets/images/logo_right.png'))
            .buffer
            .asUint8List();
    final leftLogo = pw.MemoryImage(leftLogoBytes);
    final rightLogo = pw.MemoryImage(rightLogoBytes);
    final isPhTrend = selectedParameter.toLowerCase() == 'ph';
    final hasTaggedTrends = trendPoints.any((point) => point.parameter != null);
    final phTrendPoints = hasTaggedTrends
        ? trendPoints
            .where((point) => point.parameter?.toLowerCase() == 'ph')
            .toList()
        : isPhTrend
            ? trendPoints
            : const <AnalyticsPoint>[];
    final ecTrendPoints = hasTaggedTrends
        ? trendPoints
            .where((point) => point.parameter?.toLowerCase() == 'ec')
            .toList()
        : isPhTrend
            ? const <AnalyticsPoint>[]
            : trendPoints;

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.letter,
          margin: pw.EdgeInsets.fromLTRB(54, 118, 54, 54),
        ),
        header: (_) => _buildReportHeader(generatedAt, leftLogo, rightLogo),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _mutedText),
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 12),
          _sectionTitle('Summary Report'),
          _table(
            const ['Metric', 'Value', 'Status'],
            [
              [
                'Average pH (30d)',
                summary.avgPh.toStringAsFixed(1),
                summary.phStatus,
              ],
              [
                'Average EC (30d)',
                '${summary.avgEc.toStringAsFixed(1)} mS/cm',
                summary.ecStatus,
              ],
              [
                'Average temperature (30d)',
                '${summary.avgTemp.toStringAsFixed(1)} deg C',
                summary.tempStatus,
              ],
              [
                'Critical alerts',
                '${summary.criticalAlertsCount}',
                summary.alertsPeriod,
              ],
            ],
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Configuration'),
          _table(
            const ['Parameter', 'Minimum', 'Maximum'],
            [
              [
                'pH',
                phRange.start.toStringAsFixed(1),
                phRange.end.toStringAsFixed(1),
              ],
              [
                'EC (mS/cm)',
                ecRange.start.toStringAsFixed(1),
                ecRange.end.toStringAsFixed(1),
              ],
              ['Selected trend', selectedParameter, ''],
            ],
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Analytics Snapshot'),
          if (includeAllAnalytics) ...[
            pw.SizedBox(height: 10),
            _trendGraph(
              title: 'pH Trend',
              points: phTrendPoints,
              color: _pHColor,
            ),
            pw.SizedBox(height: 10),
            _trendGraph(
              title: 'EC Trend (mS/cm)',
              points: ecTrendPoints,
              color: _ecColor,
            ),
            pw.SizedBox(height: 8),
            _analyticsLegend(),
            pw.SizedBox(height: 10),
            _table(
              const ['Date', 'pH', 'EC (mS/cm)'],
              _combinedTrendRows(phTrendPoints, ecTrendPoints),
            ),
          ] else
            _emptySectionMessage(
              'Analytics charts and trend data were not included in this report.',
            ),
          pw.SizedBox(height: 20),
          _sectionTitle('Insights and Decision Support'),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              _recommendation(
                summary,
                predictionPoints,
                selectedParameter,
                phRange,
                ecRange,
              ),
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
            ),
          ),
          if (includeSensorLogs) ...[
            pw.SizedBox(height: 20),
            _sectionTitle('Sensor History Logs'),
            pw.SizedBox(height: 8),
            if (sensorLogs.isEmpty)
              _emptySectionMessage('No sensor history records are available.')
            else
              _table(
                const [
                  'Date',
                  'Time',
                  'Average pH',
                  'Average EC',
                  'Average Temp',
                  'Status',
                ],
                sensorLogs.map((log) => log.values).toList(),
              ),
          ],
          if (includeCalibrationLogs) ...[
            pw.SizedBox(height: 20),
            _sectionTitle('Calibration History Logs'),
            pw.SizedBox(height: 8),
            if (calibrationLogs.isEmpty)
              _emptySectionMessage(
                'No calibration history records are available.',
              )
            else
              _table(
                const [
                  'Time',
                  'Parameter',
                  'Calibration',
                  'Adjustment',
                  'Performed by',
                  'Result',
                ],
                calibrationLogs.map((log) => log.values).toList(),
              ),
          ],
          if (includePhOptimization) ...[
            pw.SizedBox(height: 20),
            _sectionTitle('pH Optimization Results'),
            pw.SizedBox(height: 8),
            _optimizationTable(
              value: summary.avgPh,
              status: summary.phStatus,
              range: phRange,
              unit: '',
            ),
          ],
          if (includeEcOptimization) ...[
            pw.SizedBox(height: 20),
            _sectionTitle('EC Optimization Results'),
            pw.SizedBox(height: 8),
            _optimizationTable(
              value: summary.avgEc,
              status: summary.ecStatus,
              range: ecRange,
              unit: ' mS/cm',
            ),
          ],
        ],
      ),
    );

    final bytes = await _buildBytes(document);
    await _outputPdf(bytes, 'hydroponic-monitoring-report.pdf');
  }

  pw.Widget _buildReportHeader(
    DateTime generatedAt,
    pw.MemoryImage leftLogo,
    pw.MemoryImage rightLogo,
  ) {
    final date = '${_twoDigits(generatedAt.month)}/'
        '${_twoDigits(generatedAt.day)}/${generatedAt.year} '
        '${_twoDigits(generatedAt.hour % 12 == 0 ? 12 : generatedAt.hour % 12)}:'
        '${_twoDigits(generatedAt.minute)} '
        '${generatedAt.hour < 12 ? 'AM' : 'PM'}';

    return pw.SizedBox(
      height: 100,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _reportLogo(leftLogo),
          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(
                  'San Pedro Office of the\n'
                  'Agricultural and Biosystems Engineering\n'
                  'Analytics Report',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Date Generated: $date',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          _reportLogo(rightLogo),
        ],
      ),
    );
  }

  pw.Widget _reportLogo(pw.MemoryImage image) => pw.SizedBox(
        width: 56,
        height: 56,
        child: pw.Image(image, fit: pw.BoxFit.contain),
      );

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  pw.Widget _sectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(height: 0.7, color: _borderColor),
        pw.SizedBox(height: 6),
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _table(List<String> headers, List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows
          .map((row) => row.map(_pdfSafeText).toList(growable: false))
          .toList(growable: false),
      headerStyle: const pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _primaryGreen),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      oddRowDecoration:
          const pw.BoxDecoration(color: PdfColor(0.97, 0.98, 0.96)),
    );
  }

  pw.Widget _trendGraph({
    required String title,
    required List<AnalyticsPoint> points,
    required PdfColor color,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 4),
        if (points.isEmpty)
          pw.Container(
            height: 90,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderColor, width: 0.5),
            ),
            child: pw.Text(
              'No ${title.startsWith('pH') ? 'pH' : 'EC'} trend data available',
              style: const pw.TextStyle(fontSize: 8, color: _mutedText),
            ),
          )
        else
          pw.SvgImage(svg: _trendChartSvg(points, color)),
      ],
    );
  }

  pw.Widget _analyticsLegend() {
    pw.Widget item(String title, PdfColor color) => pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(width: 8, height: 8, color: color),
            pw.SizedBox(width: 4),
            pw.Text(title, style: const pw.TextStyle(fontSize: 8)),
          ],
        );

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        item('pH trend', _pHColor),
        pw.SizedBox(width: 20),
        item('EC trend', _ecColor),
      ],
    );
  }

  pw.Widget _optimizationTable({
    required double value,
    required String status,
    required RangeValues range,
    required String unit,
  }) {
    return _table(
      const ['Average reading', 'Target minimum', 'Target maximum', 'Status'],
      [
        [
          '${value.toStringAsFixed(1)}$unit',
          '${range.start.toStringAsFixed(1)}$unit',
          '${range.end.toStringAsFixed(1)}$unit',
          status,
        ],
      ],
    );
  }

  pw.Widget _emptySectionMessage(String message) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(
        message,
        style: const pw.TextStyle(fontSize: 9, color: _mutedText),
      ),
    );
  }

  List<List<String>> _combinedTrendRows(
    List<AnalyticsPoint> phPoints,
    List<AnalyticsPoint> ecPoints,
  ) {
    final phByDate = {for (final point in phPoints) point.label: point.value};
    final ecByDate = {for (final point in ecPoints) point.label: point.value};
    final dates = <String>{
      ...phPoints.map((point) => point.label),
      ...ecPoints.map((point) => point.label),
    };
    return dates
        .map(
          (date) => [
            date,
            phByDate[date]?.toStringAsFixed(2) ?? '-',
            ecByDate[date]?.toStringAsFixed(2) ?? '-',
          ],
        )
        .toList();
  }

  String _trendChartSvg(List<AnalyticsPoint> points, PdfColor color) {
    const width = 504.0;
    const height = 116.0;
    const left = 30.0;
    const right = 10.0;
    const top = 8.0;
    const bottom = 22.0;
    final values = points.map((point) => point.value).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final valueRange = maxValue - minValue;
    const chartWidth = width - left - right;
    const chartHeight = height - top - bottom;
    final coordinates = points.indexed.map((entry) {
      final index = entry.$1;
      final point = entry.$2;
      final x = left +
          (points.length == 1
              ? chartWidth / 2
              : index * chartWidth / (points.length - 1));
      final normalizedValue =
          valueRange == 0 ? 0.5 : (point.value - minValue) / valueRange;
      final y = top + chartHeight * (1 - normalizedValue);
      return (x: x, y: y);
    }).toList();
    final polyline = coordinates
        .map((point) =>
            '${point.x.toStringAsFixed(1)},${point.y.toStringAsFixed(1)}')
        .join(' ');
    final colorHex =
        '#${(color.red * 255).round().toRadixString(16).padLeft(2, '0')}'
        '${(color.green * 255).round().toRadixString(16).padLeft(2, '0')}'
        '${(color.blue * 255).round().toRadixString(16).padLeft(2, '0')}';

    return '''
<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">
  <rect width="$width" height="$height" fill="#ffffff"/>
  <line x1="$left" y1="$top" x2="$left" y2="${height - bottom}" stroke="#cbd3c6"/>
  <line x1="$left" y1="${height - bottom}" x2="${width - right}" y2="${height - bottom}" stroke="#cbd3c6"/>
  <line x1="$left" y1="${top + chartHeight / 2}" x2="${width - right}" y2="${top + chartHeight / 2}" stroke="#e0e5dc"/>
  <polyline points="$polyline" fill="none" stroke="$colorHex" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
  ${coordinates.map((point) => '<circle cx="${point.x.toStringAsFixed(1)}" cy="${point.y.toStringAsFixed(1)}" r="2.5" fill="$colorHex"/>').join()}
</svg>
''';
  }

  String _pdfSafeText(String value) => value
      .replaceAll('°', ' deg')
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('’', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"');

  Future<Uint8List> _buildBytes(pw.Document document) => document.save();

  String _recommendation(
    ReportSummaryData summary,
    List<PredictedAnalyticsPoint> points,
    String selectedParameter,
    RangeValues phRange,
    RangeValues ecRange,
  ) {
    final latest = points.isEmpty
        ? (selectedParameter.toLowerCase() == 'ph'
            ? summary.avgPh
            : summary.avgEc)
        : points.last.predictedValue;
    final range = selectedParameter.toLowerCase() == 'ph' ? phRange : ecRange;

    if (latest > range.end) {
      return '$selectedParameter is trending high. Apply a small corrective '
          'adjustment and recheck the reading after the next sensor update.';
    }
    if (latest < range.start) {
      return '$selectedParameter is trending low. Apply a small corrective '
          'adjustment and recheck the reading after the next sensor update.';
    }
    return '$selectedParameter is within the configured target range. '
        'Continue monitoring and avoid unnecessary adjustment.';
  }
}
