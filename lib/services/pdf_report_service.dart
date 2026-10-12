import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/monitoring_models.dart';
import '../models/reports_models.dart';
import '../utils/sensor_value_format.dart';
import 'app_state.dart';

const _primaryGreen = PdfColor(0.15, 0.39, 0.08);
const borderColor = PdfColor(0.72, 0.74, 0.72);
const _gridColor = PdfColor(0.88, 0.90, 0.87);
const mutedText = PdfColor(0.38, 0.42, 0.37);
const pHColor = PdfColor(0.15, 0.39, 0.08);
const ecColor = PdfColor(0.08, 0.60, 0.66);

/// Tables with more rows than this start on a fresh page, so their
/// heading is never left alone at the bottom of the previous page.
const _maxRowsKeptTogether = 14;

class PdfReportService {
  final Future<void> Function(Uint8List bytes, String filename) outputPdf;

  PdfReportService({
    Future<void> Function(Uint8List bytes, String filename)? output,
  }) : outputPdf = output ?? _defaultOutputPdf;

  static Future<void> _defaultOutputPdf(
      Uint8List bytes, String filename) async {}

  Future<Uint8List> buildReport({
    required ReportSummaryData summary,
    required List<AnalyticsPoint> phTrendPoints,
    required List<AnalyticsPoint> ecTrendPoints,
    required List<PredictedAnalyticsPoint> predictionPoints,
    required List<HistoryLogEntry> sensorLogs,
    required List<HistoryLogEntry> calibrationLogs,
    required RangeValues phRange,
    required RangeValues ecRange,
    required bool includeSensorLogs,
    required bool includeCalibrationLogs,
    required bool includePhOptimization,
    required bool includeEcOptimization,
    required bool includeAllAnalytics,
    required bool includeInsightsAndDecisionSupport,
    String downloadedBy = 'Current user',
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

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.letter,
          margin: pw.EdgeInsets.fromLTRB(54, 118, 54, 54),
        ),
        header: (context) =>
            _buildReportHeader(downloadedBy, leftLogo, rightLogo),
        footer: (context) => _buildReportFooter(generatedAt, context),
        build: (context) => [
          pw.SizedBox(height: 12),
          _section(
            title: 'Summary Report',
            description:
                'A quick overview of the last 30 days: the average pH, EC and temperature with their status, and the number of critical alerts recorded.',
            children: [
              _table(
                const ['Metric', 'Value', 'Status'],
                [
                  [
                    'Average pH (30d)',
                    formatSensorValue(summary.avgPh),
                    summary.phStatus,
                  ],
                  [
                    'Average EC (30d)',
                    '${formatSensorValue(summary.avgEc)} mS/cm',
                    summary.ecStatus,
                  ],
                  [
                    'Average temperature (30d)',
                    formatTemperature(summary.avgTemp),
                    summary.tempStatus,
                  ],
                  [
                    'Critical alerts',
                    '${summary.criticalAlertsCount}',
                    summary.alertsPeriod,
                  ],
                ],
              ),
            ],
          ),
          _section(
            title: 'Configuration',
            description:
                'The target ranges used for this report. These are the minimum and maximum values set on the Reports screen when this report was generated (they start from the ranges saved in Admin settings). Readings outside these ranges are marked as out of range.',
            children: [
              _table(
                const ['Parameter', 'Minimum', 'Maximum'],
                [
                  [
                    'pH',
                    formatSensorValue(phRange.start),
                    formatSensorValue(phRange.end),
                  ],
                  [
                    'EC (mS/cm)',
                    formatSensorValue(ecRange.start),
                    formatSensorValue(ecRange.end),
                  ],
                ],
              ),
            ],
          ),
          _section(
            title: 'Analytics Snapshot',
            description:
                'pH and EC readings for the timeframe selected on the Reports screen, drawn on one shared scale so you can compare how both change over time.',
            children: [
              if (includeAllAnalytics) ...[
                _combinedTrendChart(phTrendPoints, ecTrendPoints),
                pw.SizedBox(height: 8),
                _analyticsLegend(),
              ] else
                _emptySectionMessage(
                  'Analytics charts and trend data were not included in this report.',
                ),
            ],
          ),
          if (includeAllAnalytics &&
              (phTrendPoints.isNotEmpty || ecTrendPoints.isNotEmpty))
            _table(
              const ['Date', 'pH', 'EC (mS/cm)'],
              _combinedTrendRows(phTrendPoints, ecTrendPoints),
            ),
          pw.SizedBox(height: 16),
          if (includeInsightsAndDecisionSupport)
            _section(
              title: 'Insights and Decision Support',
              description:
                  'Plain-language advice based on the average pH and EC compared with the target ranges above.',
              children: [
                pw.Text(
                  '${_recommendation(summary, predictionPoints, 'pH', phRange, ecRange)}\n'
                  '${_recommendation(summary, predictionPoints, 'EC', phRange, ecRange)}',
                  style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
                ),
              ],
            ),
          if (includeSensorLogs)
            ..._tableSection(
              title: 'Sensor History Logs',
              description:
                  'Daily average sensor readings recorded by the system, with the status of each day (Stable, Warning or Critical).',
              headers: const [
                'Date',
                'Average pH',
                'Average EC',
                'Average Temp',
                'Status',
              ],
              rows: sensorLogs.map((log) {
                final row = List<String>.of(log.values);
                if (row.length > 1) row.removeAt(1);
                if (row.length > 3) row[3] = formatTempText(row[3]);
                return row;
              }).toList(),
              emptyMessage: 'No sensor history records are available.',
            ),
          if (includeCalibrationLogs)
            ..._tableSection(
              title: 'Calibration History Logs',
              description:
                  'A record of sensor calibrations: when they were done, what was adjusted, who performed them and the result.',
              headers: const [
                'Time',
                'Parameter',
                'Calibration',
                'Adjustment',
                'Performed by',
                'Result',
              ],
              rows: calibrationLogs.map((log) => log.values).toList(),
              emptyMessage: 'No calibration history records are available.',
            ),
          if (includePhOptimization)
            _section(
              title: 'pH Optimization Results',
              description:
                  'Compares the 30-day average pH with the target range in the Configuration section and shows whether it is in range.',
              children: [
                _optimizationTable(
                  value: summary.avgPh,
                  status: summary.phStatus,
                  range: phRange,
                  unit: '',
                ),
              ],
            ),
          if (includeEcOptimization)
            _section(
              title: 'EC Optimization Results',
              description:
                  'Compares the 30-day average EC with the target range in the Configuration section and shows whether it is in range.',
              children: [
                _optimizationTable(
                  value: summary.avgEc,
                  status: summary.ecStatus,
                  range: ecRange,
                  unit: ' mS/cm',
                ),
              ],
            ),
        ],
      ),
    );

    return _buildBytes(document);
  }

  /// Downloads / shares an already built PDF.
  Future<void> downloadPdf(Uint8List bytes) =>
      outputPdf(bytes, 'hydroponic-monitoring-report.pdf');

  pw.Widget _buildReportHeader(
    String downloadedBy,
    pw.MemoryImage leftLogo,
    pw.MemoryImage rightLogo,
  ) {
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
                  style: const pw.TextStyle(fontSize: 13, lineSpacing: 2),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Downloaded by: $downloadedBy',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          _reportLogo(rightLogo),
        ],
      ),
    );
  }

  pw.Widget _buildReportFooter(DateTime generatedAt, pw.Context context) {
    final date =
        '${_twoDigits(generatedAt.month)}/${_twoDigits(generatedAt.day)}/${generatedAt.year} '
        '${_twoDigits(generatedAt.hour % 12 == 0 ? 12 : generatedAt.hour % 12)}:'
        '${_twoDigits(generatedAt.minute)} '
        '${generatedAt.hour < 12 ? "AM" : "PM"}';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Date Generated: $date',
          style: const pw.TextStyle(fontSize: 11, color: mutedText),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 10, color: mutedText),
        ),
      ],
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
        pw.Container(height: 0.7, color: borderColor),
        pw.SizedBox(height: 6),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
      ],
    );
  }

  pw.Widget _sectionNote(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 10.5,
          color: mutedText,
          lineSpacing: 2,
        ),
      ),
    );
  }

  /// Heading + description + content in one block. A block is never split
  /// across pages, so a heading can no longer be left alone at the bottom.
  pw.Widget _section({
    required String title,
    required String description,
    required List<pw.Widget> children,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(title),
        _sectionNote(description),
        ...children,
        pw.SizedBox(height: 16),
      ],
    );
  }

  /// Section for a table that can be long. Short tables stay together with
  /// their heading; long tables start on a fresh page and their header row
  /// repeats on every page.
  List<pw.Widget> _tableSection({
    required String title,
    required String description,
    required List<String> headers,
    required List<List<String>> rows,
    required String emptyMessage,
  }) {
    if (rows.isEmpty) {
      return [
        _section(
          title: title,
          description: description,
          children: [_emptySectionMessage(emptyMessage)],
        ),
      ];
    }
    if (rows.length <= _maxRowsKeptTogether) {
      return [
        _section(
          title: title,
          description: description,
          children: [_table(headers, rows)],
        ),
      ];
    }
    return [
      pw.NewPage(),
      _sectionTitle(title),
      _sectionNote(description),
      _table(headers, rows),
      pw.SizedBox(height: 16),
    ];
  }

  pw.Widget _table(List<String> headers, List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows
          .map((row) => row.map(_pdfSafeText).toList(growable: false))
          .toList(growable: false),
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _primaryGreen),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      oddRowDecoration:
          const pw.BoxDecoration(color: PdfColor(0.97, 0.98, 0.96)),
    );
  }

  /// One chart with both pH and EC on a shared scale (like Forecast Overview).
  pw.Widget _combinedTrendChart(
    List<AnalyticsPoint> phPoints,
    List<AnalyticsPoint> ecPoints,
  ) {
    final labels = <String>[];
    for (final point in [...phPoints, ...ecPoints]) {
      if (!labels.contains(point.label)) labels.add(point.label);
    }

    if (labels.length < 2) {
      return pw.Container(
        height: 90,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: borderColor, width: 0.5),
        ),
        child: pw.Text(
          'Not enough trend data to draw a chart (at least 2 days needed).',
          style: const pw.TextStyle(fontSize: 10, color: mutedText),
        ),
      );
    }

    final phByLabel = {for (final p in phPoints) p.label: p.value};
    final ecByLabel = {for (final p in ecPoints) p.label: p.value};

    List<pw.PointChartValue> series(Map<String, double> values) => [
          for (var i = 0; i < labels.length; i++)
            if (values.containsKey(labels[i]))
              pw.PointChartValue(i.toDouble(), values[labels[i]]!),
        ];

    final phData = series(phByLabel);
    final ecData = series(ecByLabel);

    final allValues = [...phByLabel.values, ...ecByLabel.values];
    final maxValue =
        allValues.isEmpty ? 1.0 : allValues.reduce((a, b) => a > b ? a : b);
    final yMax = math.max(2.0, (maxValue / 2).ceil() * 2.0);
    final yTicks = [for (var i = 0; i <= 4; i++) yMax * i / 4];

    // Show about 7 date labels so they never overlap.
    final labelStep = (labels.length / 7).ceil();
    final xLabels = [
      for (var i = 0; i < labels.length; i++)
        i % labelStep == 0 ? labels[i] : '',
    ];

    const axisStyle = pw.TextStyle(fontSize: 9, color: mutedText);

    return pw.SizedBox(
      height: 190,
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis.fromStrings(
            xLabels,
            textStyle: axisStyle,
            marginStart: 14,
            marginEnd: 14,
            color: borderColor,
            divisions: labels.length <= 14,
            divisionsColor: _gridColor,
            ticks: true,
          ),
          yAxis: pw.FixedAxis<double>(
            yTicks,
            format: formatSensorValue,
            textStyle: axisStyle,
            color: borderColor,
            divisions: true,
            divisionsColor: _gridColor,
          ),
        ),
        datasets: [
          if (phData.isNotEmpty)
            pw.LineDataSet(
              legend: 'pH',
              data: phData,
              color: pHColor,
              lineWidth: 2,
              pointSize: 2.5,
              drawSurface: true,
              surfaceOpacity: 0.12,
            ),
          if (ecData.isNotEmpty)
            pw.LineDataSet(
              legend: 'EC',
              data: ecData,
              color: ecColor,
              lineWidth: 2,
              pointSize: 2.5,
              drawSurface: true,
              surfaceOpacity: 0.12,
            ),
        ],
      ),
    );
  }

  pw.Widget _analyticsLegend() {
    pw.Widget item(String title, PdfColor color) => pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(width: 8, height: 8, color: color),
            pw.SizedBox(width: 4),
            pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
          ],
        );

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        item('pH', pHColor),
        pw.SizedBox(width: 20),
        item('EC (mS/cm)', ecColor),
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
          '${formatSensorValue(value)}$unit',
          '${formatSensorValue(range.start)}$unit',
          '${formatSensorValue(range.end)}$unit',
          status,
        ]
      ],
    );
  }

  pw.Widget _emptySectionMessage(String message) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(
        message,
        style: const pw.TextStyle(fontSize: 11, color: mutedText),
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
            phByDate[date] == null ? '-' : formatSensorValue(phByDate[date]!),
            ecByDate[date] == null ? '-' : formatSensorValue(ecByDate[date]!),
          ],
        )
        .toList();
  }

  String _pdfSafeText(String value) => value
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('’', "'");

  Future<Uint8List> _buildBytes(pw.Document document) => document.save();

  String _recommendation(
    ReportSummaryData summary,
    List<PredictedAnalyticsPoint> points,
    String selectedParameter,
    RangeValues phRange,
    RangeValues ecRange,
  ) {
    final isPh = selectedParameter.toLowerCase() == 'ph';
    final latest = points.isEmpty
        ? (isPh ? summary.avgPh : summary.avgEc)
        : points.last.predictedValue;

    final range = isPh ? phRange : ecRange;

    if (latest > range.end) {
      return '$selectedParameter is trending high. Apply a small corrective adjustment and recheck the reading after the next sensor update.';
    }
    if (latest < range.start) {
      return '$selectedParameter is trending low. Apply a small corrective adjustment and recheck the reading after the next sensor update.';
    }
    return '$selectedParameter is within the configured target range. Continue monitoring and avoid unnecessary adjustment.';
  }
}
