import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/reports_models.dart';
import 'pdf_report_output.dart';

class PdfReportService {
  final Future<void> Function(Uint8List bytes, String filename) _output;

  PdfReportService({
    Future<void> Function(Uint8List bytes, String filename)? output,
  }) : _output = output ?? outputPdf;

  static const _reportTitle =
      'SMART DECISION SUPPORT SYSTEM FOR PRECISION HYDROPONICS: '
      'REALTIME PH AND EC OPTIMIZATION USING PREDICTIVE ANALYTICS';
  static const _textColor = PdfColor.fromInt(0xFF202124);
  static const _ruleColor = PdfColor.fromInt(0xFF929292);
  static const _phColor = PdfColor.fromInt(0xFF18764A);
  static const _ecColor = PdfColor.fromInt(0xFF2459A6);
  static const _rangeColor = PdfColor.fromInt(0xFFCC7A00);

  Future<void> generateAndShare({
    required PdfReportData reportData,
    required String timeframe,
    required bool includeSensorLogs,
    required bool includeCalibrationLogs,
    required bool includePhOptimization,
    required bool includeEcOptimization,
    required bool includeAllAnalytics,
  }) async {
    final logoLeft = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo_left.png'))
          .buffer
          .asUint8List(),
    );
    final logoRight = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo_right.png'))
          .buffer
          .asUint8List(),
    );
    final generatedAt = DateTime.now();
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 12, 36, 34),
        header: (context) => _pageHeader(logoLeft, logoRight, generatedAt),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _ruleColor),
          ),
        ),
        build: (context) {
          final widgets = <pw.Widget>[
            _section(
              'Summary Report',
              [_summaryTable(reportData)],
            ),
            _section(
              'Configuration',
              [
                _configurationTable(
                  reportData,
                  timeframe: timeframe,
                  includeSensorLogs: includeSensorLogs,
                  includeCalibrationLogs: includeCalibrationLogs,
                  includePhOptimization: includePhOptimization,
                  includeEcOptimization: includeEcOptimization,
                  includeAllAnalytics: includeAllAnalytics,
                ),
              ],
            ),
            _sectionHeader('Analytics Snapshot'),
            if (includeAllAnalytics) ...[
              _trendChart(
                title: 'pH trend',
                readings: reportData.phReadings,
                minimum: reportData.phMin,
                maximum: reportData.phMax,
                unit: 'pH',
                color: _phColor,
              ),
              pw.SizedBox(height: 8),
              _subheading('pH trend values'),
              _trendTable(
                readings: reportData.phReadings,
                unit: 'pH',
              ),
              pw.SizedBox(height: 12),
              _trendChart(
                title: 'EC trend (mS/cm)',
                readings: reportData.ecReadings,
                minimum: reportData.ecMin,
                maximum: reportData.ecMax,
                unit: 'mS/cm',
                color: _ecColor,
              ),
              pw.SizedBox(height: 8),
              _subheading('EC trend values'),
              _trendTable(
                readings: reportData.ecReadings,
                unit: 'mS/cm',
              ),
            ] else
              _bodyText('Analytics charts and trend tables were not selected.'),
            pw.SizedBox(height: 12),
            _section(
              'Insights and Decision Support',
              _insights(reportData),
            ),
          ];

          if (includeSensorLogs) {
            final sensorLogCount = reportData.phReadings.length +
                reportData.ecReadings.length +
                reportData.temperatureReadings.length;
            if (sensorLogCount > 15) widgets.add(pw.NewPage());
            widgets.addAll(_sensorHistorySection(reportData));
          }
          if (includeCalibrationLogs) {
            if (reportData.calibrationLogs.length > 15) {
              widgets.add(pw.NewPage());
            }
            widgets.addAll(_calibrationHistorySection(reportData));
          }
          if (includePhOptimization) {
            widgets.addAll(_optimizationSection('pH'));
          }
          if (includeEcOptimization) {
            widgets.addAll(_optimizationSection('EC'));
          }
          return widgets;
        },
      ),
    );

    final bytes = await document.save();
    await _output(bytes, 'hydroponic-monitoring-report.pdf');
  }

  pw.Widget _pageHeader(
    pw.MemoryImage logoLeft,
    pw.MemoryImage logoRight,
    DateTime generatedAt,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(
              width: 64,
              height: 64,
              child: pw.Image(logoLeft, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    _reportTitle,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Date Generated: ${_formatDateTime(generatedAt)}',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8, color: _textColor),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 10),
            pw.SizedBox(
              width: 64,
              height: 64,
              child: pw.Image(logoRight, fit: pw.BoxFit.contain),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _ruleColor, thickness: 0.6),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _textColor,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: _ruleColor, thickness: 0.5),
        pw.SizedBox(height: 7),
      ],
    );
  }

  pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader(title),
        ...children,
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _summaryTable(PdfReportData data) {
    final ph = _statisticsInRange(
      data.phSummaryReadings,
      data.phMin,
      data.phMax,
    );
    final ec = _statisticsInRange(
      data.ecSummaryReadings,
      data.ecMin,
      data.ecMax,
    );
    final rows = <List<String>>[
      [
        'Average pH (30d)',
        _metric(ph.average),
        _averageStatus(ph.average, data.phMin, data.phMax),
      ],
      [
        'Average EC (30d)',
        '${_metric(ec.average)} mS/cm',
        _averageStatus(ec.average, data.ecMin, data.ecMax),
      ],
      [
        'Critical alerts (this month)',
        '${data.criticalAlertsCount}',
        data.criticalAlertsCount == 0 ? 'Stable' : 'Critical',
      ],
      [
        'pH minimum',
        _metric(ph.minimum),
        _boundStatus(ph.minimum, data.phMin, data.phMax),
      ],
      [
        'pH maximum',
        _metric(ph.maximum),
        _boundStatus(ph.maximum, data.phMin, data.phMax),
      ],
      [
        'pH standard deviation',
        _metric(ph.standardDeviation),
        _stabilityStatus(ph.standardDeviation, true)
      ],
      [
        'pH readings within configured range',
        _percent(ph.withinRangePercentage),
        _percentageStatus(ph.withinRangePercentage),
      ],
      [
        'EC minimum',
        _metric(ec.minimum),
        _boundStatus(ec.minimum, data.ecMin, data.ecMax),
      ],
      [
        'EC maximum',
        _metric(ec.maximum),
        _boundStatus(ec.maximum, data.ecMin, data.ecMax),
      ],
      [
        'EC standard deviation',
        _metric(ec.standardDeviation),
        _stabilityStatus(ec.standardDeviation, false)
      ],
      [
        'EC readings within configured range',
        _percent(ec.withinRangePercentage),
        _percentageStatus(ec.withinRangePercentage),
      ],
    ];

    return pw.TableHelper.fromTextArray(
      headers: const ['Metric', 'Value', 'Status'],
      data: rows,
      headerStyle:
          const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      border: pw.TableBorder.all(color: _ruleColor, width: 0.45),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEAF0EC)),
    );
  }

  pw.Widget _configurationTable(
    PdfReportData data, {
    required String timeframe,
    required bool includeSensorLogs,
    required bool includeCalibrationLogs,
    required bool includePhOptimization,
    required bool includeEcOptimization,
    required bool includeAllAnalytics,
  }) {
    final rows = <List<String>>[
      [
        'pH configured range',
        '${_number(data.phMin)} - ${_number(data.phMax)}'
      ],
      [
        'EC configured range (mS/cm)',
        '${_number(data.ecMin)} - ${_number(data.ecMax)}',
      ],
      [
        'Sensor history logs',
        _yesNo(includeSensorLogs),
      ],
      [
        'Calibration history logs',
        _yesNo(includeCalibrationLogs),
      ],
      [
        'pH optimization results',
        _yesNo(includePhOptimization),
      ],
      [
        'EC optimization results',
        _yesNo(includeEcOptimization),
      ],
      [
        'All analytics and graphs',
        _yesNo(includeAllAnalytics),
      ],
      [
        'Date range / filter',
        '${_timeframeLabel(timeframe)}: ${_formatDate(data.startDate)} - ${_formatDate(data.endDate)}',
      ],
    ];
    return pw.TableHelper.fromTextArray(
      headers: const ['Configuration', 'Value'],
      data: rows,
      headerStyle:
          const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      border: pw.TableBorder.all(color: _ruleColor, width: 0.45),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEAF0EC)),
    );
  }

  pw.Widget _trendChart({
    required String title,
    required List<ReportReading> readings,
    required double minimum,
    required double maximum,
    required String unit,
    required PdfColor color,
  }) {
    final dailyPoints = _dailyAverages(readings);
    if (dailyPoints.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _subheading(title),
          _bodyText('No data available for this period.'),
        ],
      );
    }

    final chartPointCount = math.max(dailyPoints.length, 2);
    final yValues = dailyPoints.map((point) => point.value).toList();
    final yMin = math.min(minimum, yValues.reduce(math.min)) - 0.25;
    final yMax = math.max(maximum, yValues.reduce(math.max)) + 0.25;
    final yTicks = List<double>.generate(
      5,
      (index) => yMin + (yMax - yMin) * index / 4,
    );
    final xTicks = dailyPoints.length == 1
        ? [0.0, 1.0]
        : _sampleIndices(dailyPoints.length)
            .map((index) => index.toDouble())
            .toList();
    final datasets = <pw.Dataset>[
      pw.LineDataSet<pw.PointChartValue>(
        data: [
          for (var index = 0; index < dailyPoints.length; index++)
            pw.PointChartValue(
              dailyPoints.length == 1 ? 0.5 : index.toDouble(),
              dailyPoints[index].value,
            ),
        ],
        legend: 'Daily average ($unit)',
        color: color,
        lineWidth: 1.7,
        pointSize: 2,
        drawPoints: true,
      ),
      ..._dashedRangeLine(
          chartPointCount, minimum, _rangeColor, 'Minimum target'),
      ..._dashedRangeLine(
          chartPointCount, maximum, _rangeColor, 'Maximum target'),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _subheading(title),
        pw.SizedBox(
          height: 190,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis<double>(
                xTicks,
                format: (value) {
                  if (dailyPoints.length == 1) {
                    return value < 0.5
                        ? ''
                        : _shortDate(dailyPoints.first.date);
                  }
                  final index = value.round().clamp(0, dailyPoints.length - 1);
                  return _shortDate(dailyPoints[index].date);
                },
                textStyle: const pw.TextStyle(fontSize: 6),
                divisions: true,
                divisionsDashed: true,
              ),
              yAxis: pw.FixedAxis<double>(
                yTicks,
                format: (value) => value.toStringAsFixed(2),
                textStyle: const pw.TextStyle(fontSize: 6),
                divisions: true,
                divisionsDashed: true,
              ),
            ),
            datasets: datasets,
            left: pw.Container(
              width: 24,
              alignment: pw.Alignment.center,
              child: pw.Text(unit, style: const pw.TextStyle(fontSize: 7)),
            ),
            bottom: pw.Container(
              height: 18,
              alignment: pw.Alignment.center,
              child: pw.ChartLegend(
                direction: pw.Axis.horizontal,
                textStyle: const pw.TextStyle(fontSize: 6),
                padding: const pw.EdgeInsets.all(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<pw.LineDataSet<pw.PointChartValue>> _dashedRangeLine(
    int pointCount,
    double value,
    PdfColor color,
    String? legend,
  ) {
    if (pointCount < 2) return const [];
    final result = <pw.LineDataSet<pw.PointChartValue>>[];
    const dashCount = 18;
    for (var index = 0; index < dashCount; index++) {
      if (index.isOdd) continue;
      final start = (pointCount - 1) * index / dashCount;
      final end = (pointCount - 1) * (index + 0.65) / dashCount;
      result.add(
        pw.LineDataSet<pw.PointChartValue>(
          data: [
            pw.PointChartValue(start, value),
            pw.PointChartValue(end, value),
          ],
          legend: index == 0 ? legend : null,
          color: color,
          lineWidth: 0.8,
          drawPoints: false,
        ),
      );
    }
    return result;
  }

  pw.Widget _trendTable({
    required List<ReportReading> readings,
    required String unit,
  }) {
    final points = _dailyAverages(readings);
    if (points.isEmpty) return _bodyText('No data available for this period.');
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Trend value ($unit)'],
      data: [
        for (final point in points)
          [_formatDate(point.date), _number(point.value)],
      ],
      headerStyle:
          const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      border: pw.TableBorder.all(color: _ruleColor, width: 0.4),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEAF0EC)),
    );
  }

  List<pw.Widget> _insights(PdfReportData data) {
    final phOut = _outOfRangeCount(data.phReadings, data.phMin, data.phMax);
    final ecOut = _outOfRangeCount(data.ecReadings, data.ecMin, data.ecMax);
    final phWorst = _worstDay(data.phReadings, data.phMin, data.phMax);
    final ecWorst = _worstDay(data.ecReadings, data.ecMin, data.ecMax);
    final phDirection = _trendDirection(data.phReadings);
    final ecDirection = _trendDirection(data.ecReadings);
    final recalibrationNeeded = phOut + ecOut > 0;
    final calibrationAvailable = data.calibrationLogs.isNotEmpty;
    final insights = <String>[
      'pH trend: $phDirection. $phOut of-range readings in the selected period.'
          '${phWorst == null ? '' : ' Worst day: ${_formatDate(phWorst)}.'}',
      'EC trend: $ecDirection. $ecOut out-of-range readings in the selected period.'
          '${ecWorst == null ? '' : ' Worst day: ${_formatDate(ecWorst)}.'}',
      'Critical alerts recorded this month: ${data.criticalAlertsCount}.',
      recalibrationNeeded
          ? 'Recalibration is recommended: readings have fallen outside configured limits.'
          : calibrationAvailable
              ? 'No out-of-range readings were found; calibration activity is present in the period.'
              : 'No out-of-range readings were found. Recent calibration could not be confirmed from the available log entries.',
    ];
    final actions = <String>[
      if (phOut + ecOut > 0)
        'Inspect the probe(s) associated with out-of-range readings and recalibrate before making large nutrient corrections.',
      'Review the worst-day readings against the sensor history and verify that the recorded values match the growing-system conditions.',
      if (data.criticalAlertsCount > 0)
        'Review and acknowledge the critical alerts; document the corrective action taken for each event.',
      if (!calibrationAvailable)
        'Confirm the pH and EC probes are calibrated and record the calibration in the calibration log.',
      'Continue monitoring pH and EC against the configured limits; adjust nutrient solution gradually and recheck after the next reading.',
    ];

    return [
      for (final insight in insights) _bullet(insight),
      pw.SizedBox(height: 5),
      _subheading('Recommended actions'),
      for (var index = 0; index < math.min(actions.length, 5); index++)
        _numberedAction(actions[index], index + 1),
    ];
  }

  List<pw.Widget> _sensorHistorySection(PdfReportData data) {
    final readings = [
      ...data.phReadings,
      ...data.ecReadings,
      ...data.temperatureReadings,
    ]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return [
      _sectionHeader('Sensor History Logs'),
      if (readings.isEmpty)
        _bodyText('No data available for this period.')
      else
        pw.TableHelper.fromTextArray(
          headers: const ['Date', 'Parameter', 'Value', 'Status'],
          data: [
            for (final reading in readings)
              [
                _formatDateTime(reading.recordedAt),
                reading.parameter,
                _number(reading.value),
                reading.status,
              ],
          ],
          headerStyle:
              const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          border: pw.TableBorder.all(color: _ruleColor, width: 0.4),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEAF0EC)),
        ),
      pw.SizedBox(height: 12),
    ];
  }

  List<pw.Widget> _calibrationHistorySection(PdfReportData data) {
    return [
      _sectionHeader('Calibration History Logs'),
      if (data.calibrationLogs.isEmpty)
        _bodyText('No data available for this period.')
      else
        pw.TableHelper.fromTextArray(
          headers: const [
            'Date',
            'Parameter',
            'Calibration type',
            'Adjustment',
            'Performed by',
            'Status',
          ],
          data: [
            for (final log in data.calibrationLogs)
              [
                _formatDateTime(log.recordedAt),
                log.parameter,
                log.calibrationType,
                log.adjustment,
                log.performedBy,
                log.status,
              ],
          ],
          headerStyle:
              const pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          border: pw.TableBorder.all(color: _ruleColor, width: 0.4),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEAF0EC)),
        ),
      pw.SizedBox(height: 12),
    ];
  }

  List<pw.Widget> _optimizationSection(String parameter) {
    return [
      _section(
        '$parameter Optimization Results',
        [
          _bodyText(
            'No optimization results available for this period.',
          ),
        ],
      ),
    ];
  }

  _ReadingStatistics _statistics(List<ReportReading> readings) {
    if (readings.isEmpty) return const _ReadingStatistics.empty();
    final values = readings.map((reading) => reading.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final variance = values
            .map((value) => math.pow(value - average, 2))
            .reduce((a, b) => a + b) /
        values.length;
    return _ReadingStatistics(
      average: average,
      minimum: values.reduce(math.min),
      maximum: values.reduce(math.max),
      standardDeviation: math.sqrt(variance),
      withinRangePercentage: 0,
    );
  }

  double _withinRangePercentage(
    List<ReportReading> readings,
    double minimum,
    double maximum,
  ) {
    if (readings.isEmpty) return 0;
    final within = readings
        .where(
            (reading) => reading.value >= minimum && reading.value <= maximum)
        .length;
    return within * 100 / readings.length;
  }

  _ReadingStatistics _statisticsInRange(
    List<ReportReading> readings,
    double minimum,
    double maximum,
  ) {
    final statistics = _statistics(readings);
    return statistics.copyWith(
      withinRangePercentage: _withinRangePercentage(readings, minimum, maximum),
    );
  }

  List<_DailyPoint> _dailyAverages(List<ReportReading> readings) {
    final buckets = <DateTime, List<double>>{};
    for (final reading in readings) {
      final date = DateTime(
        reading.recordedAt.year,
        reading.recordedAt.month,
        reading.recordedAt.day,
      );
      buckets.putIfAbsent(date, () => []).add(reading.value);
    }
    final dates = buckets.keys.toList()..sort();
    return [
      for (final date in dates)
        _DailyPoint(
          date,
          buckets[date]!.reduce((a, b) => a + b) / buckets[date]!.length,
        ),
    ];
  }

  int _outOfRangeCount(
    List<ReportReading> readings,
    double minimum,
    double maximum,
  ) =>
      readings
          .where(
              (reading) => reading.value < minimum || reading.value > maximum)
          .length;

  DateTime? _worstDay(
    List<ReportReading> readings,
    double minimum,
    double maximum,
  ) {
    final daily = _dailyAverages(readings);
    if (daily.isEmpty) return null;
    daily.sort((a, b) {
      final aDeviation = _rangeDeviation(a.value, minimum, maximum);
      final bDeviation = _rangeDeviation(b.value, minimum, maximum);
      return bDeviation.compareTo(aDeviation);
    });
    return _rangeDeviation(daily.first.value, minimum, maximum) == 0
        ? null
        : daily.first.date;
  }

  String _trendDirection(List<ReportReading> readings) {
    final daily = _dailyAverages(readings);
    if (daily.length < 2) return 'Insufficient data to determine direction';
    final change = daily.last.value - daily.first.value;
    if (change.abs() < 0.02) return 'Stable';
    return change > 0 ? 'Increasing' : 'Decreasing';
  }

  double _rangeDeviation(double value, double minimum, double maximum) {
    if (value < minimum) return minimum - value;
    if (value > maximum) return value - maximum;
    return 0;
  }

  String _averageStatus(double? value, double minimum, double maximum) {
    if (value == null) return 'No data';
    if (value < minimum || value > maximum) return 'Critical';
    final margin = (maximum - minimum) * 0.05;
    if (value - minimum < margin || maximum - value < margin) return 'Warning';
    return 'In range';
  }

  String _boundStatus(double? value, double minimum, double maximum) {
    if (value == null) return 'No data';
    return value < minimum || value > maximum ? 'Critical' : 'In range';
  }

  String _stabilityStatus(double? value, bool isPh) {
    if (value == null) return 'No data';
    final stableLimit = isPh ? 0.15 : 0.25;
    if (value <= stableLimit) return 'Stable';
    if (value <= stableLimit * 2) return 'Warning';
    return 'Critical';
  }

  String _percentageStatus(double? percentage) {
    if (percentage == null) return 'No data';
    if (percentage >= 95) return 'Stable';
    if (percentage >= 80) return 'Warning';
    return 'Critical';
  }

  List<int> _sampleIndices(int length) {
    if (length <= 5) return List.generate(length, (index) => index);
    return {
      0,
      (length - 1) ~/ 4,
      (length - 1) ~/ 2,
      (length - 1) * 3 ~/ 4,
      length - 1,
    }.toList()
      ..sort();
  }

  pw.Widget _subheading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
          text,
          style:
              const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      );

  pw.Widget _bodyText(String text) => pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8, color: _textColor),
      );

  pw.Widget _bullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('- ', style: const pw.TextStyle(fontSize: 8)),
            pw.Expanded(child: _bodyText(text)),
          ],
        ),
      );

  pw.Widget _numberedAction(String text, int number) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 14,
              child: pw.Text(
                '$number.',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.Expanded(child: _bodyText(text)),
          ],
        ),
      );

  String _metric(double? value) =>
      value == null ? 'No data available for this period' : _number(value);

  String _number(double value) => value.toStringAsFixed(2);

  String _percent(double? value) => value == null
      ? 'No data available for this period'
      : '${_number(value)}%';

  String _yesNo(bool value) => value ? 'Yes' : 'No';

  String _timeframeLabel(String timeframe) => switch (timeframe) {
        '7d' => 'Weekly (7 days)',
        '90d' => 'Quarterly (90 days)',
        _ => 'Monthly (30 days)',
      };

  String _formatDate(DateTime value) =>
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.day.toString().padLeft(2, '0')}/${value.year}';

  String _shortDate(DateTime value) =>
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.day.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    final meridiem = value.hour < 12 ? 'AM' : 'PM';
    return '${_formatDate(value)} $hour:$minute:$second $meridiem';
  }
}

class _ReadingStatistics {
  final double? average;
  final double? minimum;
  final double? maximum;
  final double? standardDeviation;
  final double? withinRangePercentage;

  const _ReadingStatistics({
    required this.average,
    required this.minimum,
    required this.maximum,
    required this.standardDeviation,
    required this.withinRangePercentage,
  });

  const _ReadingStatistics.empty()
      : average = null,
        minimum = null,
        maximum = null,
        standardDeviation = null,
        withinRangePercentage = null;

  _ReadingStatistics copyWith({double? withinRangePercentage}) =>
      _ReadingStatistics(
        average: average,
        minimum: minimum,
        maximum: maximum,
        standardDeviation: standardDeviation,
        withinRangePercentage:
            withinRangePercentage ?? this.withinRangePercentage,
      );
}

class _DailyPoint {
  final DateTime date;
  final double value;

  const _DailyPoint(this.date, this.value);
}
