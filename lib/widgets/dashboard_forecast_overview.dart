import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/monitoring_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/manila_time.dart';

class DashboardForecastOverview extends StatefulWidget {
  final List<ForecastPoint> phPoints;
  final List<ForecastPoint> ecPoints;
  final List<ForecastHorizonSummary> summaries;
  final DateTime? generatedAt;
  final bool isOffline;
  final bool isCalibrating;
  final String? forecastIssue;
  final DateTime? latestSensorRecordedAt;
  final VoidCallback onViewDetails;

  const DashboardForecastOverview({
    super.key,
    required this.phPoints,
    required this.ecPoints,
    required this.summaries,
    required this.generatedAt,
    this.isOffline = false,
    this.isCalibrating = false,
    this.forecastIssue,
    this.latestSensorRecordedAt,
    required this.onViewDetails,
  });

  @override
  State<DashboardForecastOverview> createState() =>
      _DashboardForecastOverviewState();
}

class _DashboardForecastOverviewState extends State<DashboardForecastOverview> {
  String _parameter = 'Both';
  int _hours = 4;

  static Color get _phColor => AppColors.accentGreen;
  static Color get _ecColor => AppColors.accentTeal;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    if (widget.isOffline || widget.forecastIssue != null) {
      final lastReceived = widget.latestSensorRecordedAt == null
          ? 'No sensor data received'
          : 'Last received ${formatManilaDateTime(toManilaTime(widget.latestSensorRecordedAt!))}';
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: AppDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            SizedBox(
              height: isMobile ? 230 : 350,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.isCalibrating ? Icons.tune : Icons.cloud_off,
                        size: 42, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                        widget.isCalibrating
                            ? 'Calibration in progress'
                            : 'Sensor offline',
                        style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 6),
                    Text(
                      widget.isCalibrating
                          ? 'Forecasting and reservoir history are paused while the probe is in calibration solution.'
                          : 'Forecasting requires a recent five-minute sensor reading.',
                      style: AppTextStyles.cardMeta,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.isOffline) ...[
                      const SizedBox(height: 4),
                      Text(lastReceived, style: AppTextStyles.cardMeta),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    final ph = _filtered(widget.phPoints);
    final ec = _filtered(widget.ecPoints);
    final phRange = _rangeFor(ph, fallback: const _ChartRange(5, 7));
    final ecRange = _rangeFor(ec, fallback: const _ChartRange(1, 2));
    final both = _parameter == 'Both';
    final hasFallbackHistory = [...ph, ...ec].any(
      (point) => !point.isPredicted && point.isFallback,
    );
    final chartRange = both
        ? _rangeFor(
            [...ph, ...ec],
            fallback: const _ChartRange(0, 10),
          )
        : _parameter == 'pH'
            ? phRange
            : ecRange;
    final currentLabel = _readingLabel(ph, ec, predicted: false);
    final forecastLabel = _readingLabel(ph, ec, predicted: true);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 5),
          Text(
            hasFallbackHistory
                ? 'Sensor data unavailable: estimated baseline and machine-learning forecast'
                : 'Realtime measurements and machine-learning forecast trajectory',
            style: AppTextStyles.cardMeta,
          ),
          SizedBox(height: isMobile ? 16 : 22),
          SizedBox(
            height: isMobile ? 230 : 350,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    minX: -_hours.toDouble(),
                    maxX: _hours.toDouble(),
                    minY: chartRange.minimum,
                    maxY: chartRange.maximum,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.chartGrid.withValues(alpha: 0.65),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (_) => FlLine(
                        color: AppColors.chartGrid.withValues(alpha: 0.35),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: AppColors.chartGrid),
                    ),
                    titlesData: _titlesData(
                      chartRange: chartRange,
                      isMobile: isMobile,
                    ),
                    extraLinesData: ExtraLinesData(
                      verticalLines: [
                        VerticalLine(
                          x: 0,
                          color: AppColors.textSecondary,
                          strokeWidth: 1,
                          dashArray: [5, 4],
                          label: VerticalLineLabel(
                            show: false,
                            alignment: Alignment.topCenter,
                            style: AppTextStyles.cardMeta.copyWith(
                              fontSize: isMobile ? 9 : 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.cardBackground,
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (spots) => spots.map((spot) {
                          // Each predicted line includes the current historical
                          // point so the two segments connect. Suppress that
                          // duplicate connector in the tooltip.
                          final isPredictedConnector =
                              spot.x <= 0 && spot.barIndex.isOdd;
                          if (isPredictedConnector) return null;

                          final isPh = _parameter == 'pH' ||
                              (_parameter == 'Both' && spot.barIndex < 2);
                          final label = isPh ? 'pH' : 'EC';
                          final color = isPh ? _phColor : _ecColor;
                          final unit = isPh ? '' : ' mS/cm';
                          return LineTooltipItem(
                            '$label ${spot.y.toStringAsFixed(6)}$unit',
                            AppTextStyles.bodyBold.copyWith(color: color),
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: [
                      if (_parameter != 'EC')
                        ..._seriesBars(
                          ph,
                          color: _phColor,
                        ),
                      if (_parameter != 'pH')
                        ..._seriesBars(
                          ec,
                          color: _ecColor,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  left: isMobile ? 35 : 50,
                  right: isMobile ? 35 : 50,
                  child: IgnorePointer(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.cardMeta.copyWith(
                            fontSize: isMobile ? 9 : 11,
                          ),
                          children: [
                            const TextSpan(text: 'Current '),
                            TextSpan(
                              text: currentLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: '  |  Forecast '),
                            TextSpan(
                              text: forecastLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendAndDate(isMobile, hasFallbackHistory),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final title = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(Icons.show_chart, color: AppColors.primaryButton),
        Text('Forecast Overview', style: AppTextStyles.sectionTitle),
        TextButton(
          onPressed: widget.onViewDetails,
          child: const Text('View forecast details'),
        ),
      ],
    );
    final controls = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _selector<String>(
          values: const ['Both', 'pH', 'EC'],
          selected: _parameter,
          label: (value) => value,
          onSelected: (value) => setState(() => _parameter = value),
        ),
        _selector<int>(
          values: const [4, 8, 12],
          selected: _hours,
          label: (value) => '${value}h',
          onSelected: (value) => setState(() => _hours = value),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 12), controls],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        controls,
      ],
    );
  }

  Widget _selector<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.calloutBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in values)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected == value
                      ? AppColors.primaryButton
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label(value),
                  style: AppTextStyles.cardMeta.copyWith(
                    color: selected == value
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  FlTitlesData _titlesData({
    required _ChartRange chartRange,
    required bool isMobile,
  }) {
    final singleInterval = (chartRange.maximum - chartRange.minimum) / 4;
    const axisDecimals = 6;
    final centerTime = widget.generatedAt ?? manilaNow();
    final horizontalInterval = isMobile ? _hours.toDouble() : _hours / 2;
    return FlTitlesData(
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      leftTitles: AxisTitles(
        axisNameWidget: Text(
          'Value',
          style: AppTextStyles.cardMeta,
        ),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: isMobile ? 62 : 72,
          interval: singleInterval,
          getTitlesWidget: (value, _) => Text(
            value.toStringAsFixed(axisDecimals),
            style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
          ),
        ),
      ),
      rightTitles: AxisTitles(
        axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: isMobile ? 62 : 72,
          interval: singleInterval,
          getTitlesWidget: (value, _) => Text(
            value.toStringAsFixed(axisDecimals),
            style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: horizontalInterval,
          getTitlesWidget: (value, _) {
            final time = centerTime.add(
              Duration(minutes: (value * 60).round()),
            );
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                formatManilaClockTime(time),
                style: AppTextStyles.cardMeta.copyWith(
                  fontSize: isMobile ? 10 : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend(bool hasFallbackHistory) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        if (_parameter != 'EC')
          _legendItem(
            hasFallbackHistory
                ? 'pH estimated / predicted'
                : 'pH measured / predicted',
            _phColor,
          ),
        if (_parameter != 'pH')
          _legendItem(
            hasFallbackHistory
                ? 'EC estimated / predicted'
                : 'EC measured / predicted',
            _ecColor,
          ),
      ],
    );
  }

  Widget _buildLegendAndDate(bool isMobile, bool hasFallbackHistory) {
    final generated = widget.generatedAt == null
        ? null
        : Text(
            'Generated ${formatManilaDateTime(widget.generatedAt!)}',
            style: AppTextStyles.cardMeta,
          );

    if (generated == null) return _buildLegend(hasFallbackHistory);
    if (isMobile) {
      return Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [_buildLegend(hasFallbackHistory), generated],
      );
    }
    return Row(
      children: [
        Expanded(child: _buildLegend(hasFallbackHistory)),
        const SizedBox(width: 16),
        generated,
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.cardMeta),
      ],
    );
  }

  String _readingLabel(
    List<ForecastPoint> ph,
    List<ForecastPoint> ec, {
    required bool predicted,
  }) {
    String? valueFor(List<ForecastPoint> points) {
      final matching = points.where(
        (point) => point.isPredicted == predicted,
      );
      if (matching.isEmpty) return null;
      final point = predicted
          ? matching.reduce(
              (a, b) =>
                  (a.hour - _hours).abs() <= (b.hour - _hours).abs() ? a : b,
            )
          : matching.reduce((a, b) => a.hour >= b.hour ? a : b);
      return point.value.toStringAsFixed(6);
    }

    final values = <String>[];
    if (_parameter != 'EC') {
      final value = valueFor(ph);
      if (value != null) values.add('pH $value');
    }
    if (_parameter != 'pH') {
      final value = valueFor(ec);
      if (value != null) values.add('EC $value');
    }
    return values.isEmpty ? '--' : values.join(' / ');
  }

  List<ForecastPoint> _filtered(List<ForecastPoint> points) {
    return points
        .where(
          (point) =>
              point.isPredicted ? point.hour <= _hours : point.hour >= -_hours,
        )
        .toList();
  }

  List<LineChartBarData> _seriesBars(
    List<ForecastPoint> points, {
    required Color color,
  }) {
    final historical = points.where((point) => !point.isPredicted).toList();
    final predicted = points.where((point) => point.isPredicted).toList();
    double y(double value) => value;
    final historicalSpots =
        historical.map((point) => FlSpot(point.hour, y(point.value))).toList();
    final predictedSpots = <FlSpot>[
      if (historical.isNotEmpty)
        FlSpot(historical.last.hour, y(historical.last.value)),
      ...predicted.map((point) => FlSpot(point.hour, y(point.value))),
    ];

    return [
      if (historicalSpots.isNotEmpty)
        _bar(historicalSpots, color: color, predicted: false),
      if (predictedSpots.isNotEmpty)
        _bar(predictedSpots, color: color, predicted: true),
    ];
  }

  LineChartBarData _bar(
    List<FlSpot> spots, {
    required Color color,
    required bool predicted,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: predicted ? 2 : 2.5,
      dashArray: predicted ? [6, 4] : null,
      dotData: FlDotData(show: predicted),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: predicted ? 0.05 : 0.10),
      ),
    );
  }

  _ChartRange _rangeFor(
    List<ForecastPoint> points, {
    required _ChartRange fallback,
  }) {
    if (points.isEmpty) return fallback;
    final values = points.map((point) => point.value);
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    final spread = maximum - minimum;
    final padding = math.max(spread * 0.18, maximum.abs() * 0.03);
    return _ChartRange(math.max(0, minimum - padding), maximum + padding);
  }
}

class _ChartRange {
  final double minimum;
  final double maximum;

  const _ChartRange(this.minimum, this.maximum);
}
