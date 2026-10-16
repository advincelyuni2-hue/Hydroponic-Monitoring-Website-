import 'mobile_graph_card.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final saved = PageStorage.maybeOf(context)?.readState(context,
        identifier: 'forecast-overview-filters');
    if (saved is Map<String, Object>) {
      _parameter = saved['parameter'] as String;
      _hours = saved['hours'] as int;
    }
  }

  void _saveFilters() {
    PageStorage.maybeOf(context)?.writeState(context,
        <String, Object>{'parameter': _parameter, 'hours': _hours},
        identifier: 'forecast-overview-filters');
  }

  static Color get _phColor => AppColors.accentGreen;
  static Color get _ecColor => AppColors.accentTeal;
  static const Color _forecastColor = Color(0xFFF57C00);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final narrow = constraints.maxWidth < 760 * scale;
          if (MobileGraphPage.isActive(context)) return _buildCard(context, narrow);
          return SizedBox(
            height: constraints.hasBoundedHeight
                ? constraints.maxHeight
                : (narrow ? 600 : 440) * scale,
            child: _buildCard(context, narrow),
          );
        },
      );

  Widget _buildCard(BuildContext context, bool isMobile) {
    if (widget.isOffline || widget.forecastIssue != null) {
      final lastReceived = widget.latestSensorRecordedAt == null
          ? 'No sensor data received'
          : 'Last received ${formatManilaDateTime(toManilaTime(widget.latestSensorRecordedAt!))}';
      return Container(
        width: double.infinity,
        padding: MobileGraphPage.isActive(context) ? EdgeInsets.zero : EdgeInsets.all(isMobile ? 16 : 20),
        decoration: MobileGraphPage.isActive(context) ? null : AppDecorations.card(),
        child: MobileGraphComposition(
          chartIndex: 1,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            Expanded(
              child: SingleChildScrollView(
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
              )),
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

    return Container(
      width: double.infinity,
      padding: MobileGraphPage.isActive(context) ? EdgeInsets.zero : EdgeInsets.all(isMobile ? 16 : 20),
      decoration: MobileGraphPage.isActive(context) ? null : AppDecorations.card(),
      child: MobileGraphComposition(
        chartIndex: 4,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 8),
          IndexedStack(
            index: const ['Both', 'pH', 'EC'].indexOf(_parameter),
            children: [
              for (final parameter in ['Both', 'pH', 'EC'])
                _buildReadingSummary(
                  _readingLabel(ph, ec, predicted: false, parameter: parameter),
                  _readingLabel(ph, ec, predicted: true, parameter: parameter),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: MobileGraphTimeline(
              pointCount: _parameter == 'pH' ? ph.length
                  : _parameter == 'EC' ? ec.length : math.max(ph.length, ec.length),
              child: Padding(
              padding: EdgeInsets.only(right: isMobile ? 8 : 0),
              child: LayoutBuilder(
                  builder: (context, chartSpace) => MobileLineChart(
                        LineChartData(
                          clipData: const FlClipData.all(),
                          minX: -_hours.toDouble(),
                          maxX: _hours.toDouble(),
                          minY: chartRange.minimum,
                          maxY: chartRange.maximum,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color:
                                  AppColors.chartGrid.withValues(alpha: 0.65),
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (_) => FlLine(
                              color:
                                  AppColors.chartGrid.withValues(alpha: 0.35),
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
                            chartWidth: chartSpace.maxWidth,
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
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
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
                      )),
            ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendAndDate(isMobile, hasFallbackHistory),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.show_chart, color: AppColors.primaryButton),
        const SizedBox(width: 8),
        Flexible(
            child: Text('Forecast Overview',
                style: AppTextStyles.sectionTitle
                    .copyWith(fontSize: isMobile ? 17 : 19))),
      ],
    );

    final selectors = <Widget>[
      _selector<String>(
        compact: isMobile,
        values: const ['Both', 'pH', 'EC'],
        selected: _parameter,
        label: (value) => value,
        onSelected: (value) {
          setState(() => _parameter = value);
          _saveFilters();
        },
      ),
      _selector<int>(
        compact: isMobile,
        values: const [4, 8, 12],
        selected: _hours,
        label: (value) => '${value}h',
        onSelected: (value) {
          setState(() => _hours = value);
          _saveFilters();
        },
      ),
    ];
    final controls = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: selectors,
    );

    final details = TextButton(
      onPressed: widget.onViewDetails,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      ),
      child: const Text('View forecast details'),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!MobileGraphPage.isActive(context)) ...[
            title,
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [...selectors, details],
          ),
        ],
      );
    }

    return Row(
      children: [
        title,
        const SizedBox(width: 16),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: controls),
        ),
        details,
      ],
    );
  }

  Widget _selector<T>({
    bool compact = false,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in values)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelected(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 13,
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
      ),
    );
  }

  FlTitlesData _titlesData({
    required _ChartRange chartRange,
    required bool isMobile,
    required double chartWidth,
  }) {
    final singleInterval = (chartRange.maximum - chartRange.minimum) / 4;
    const axisDecimals = 2;
    final centerTime = widget.generatedAt ?? manilaNow();
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    // Keep complete clock labels on one line. Reduce tick count according to
    // the actual plot width and scaled text instead of splitting AM/PM below.
    var labelWidth = 0.0;
    if (isMobile) {
      for (final hour in [-_hours, 0, _hours]) {
        final painter = TextPainter(
          text: TextSpan(
            text: formatManilaClockTime(centerTime.add(Duration(hours: hour))),
            style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        labelWidth = math.max(labelWidth, painter.width);
        painter.dispose();
      }
    }
    final plotWidth = math.max(0.0, chartWidth - 46 * textScale);
    final tickCount =
        isMobile ? (plotWidth / (labelWidth + 16)).floor().clamp(1, 3) : 5;
    final horizontalInterval =
        isMobile ? _hours * (tickCount == 2 ? 2.0 : 1.0) : _hours / 2;
    return FlTitlesData(
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      leftTitles: AxisTitles(
        axisNameWidget:
            isMobile ? null : Text('Value', style: AppTextStyles.cardMeta),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 46 * MediaQuery.textScalerOf(context).scale(12) / 12,
          interval: singleInterval,
          getTitlesWidget: (value, meta) {
            final label = Text(
              value.toStringAsFixed(axisDecimals),
              style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
            );
            if (!isMobile) return label;
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 6,
              fitInside: SideTitleFitInsideData(
                enabled: true,
                axisPosition: meta.axisPosition,
                parentAxisSize: meta.parentAxisSize,
                distanceFromEdge: 0,
              ),
              child: label,
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34 * textScale,
          interval: horizontalInterval,
          getTitlesWidget: (value, meta) {
            if (isMobile && tickCount == 1 && value.abs() > 0.001) {
              return const SizedBox.shrink();
            }
            final time = centerTime.add(
              Duration(minutes: (value * 60).round()),
            );
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 8,
              fitInside: SideTitleFitInsideData(
                enabled: true,
                axisPosition: meta.axisPosition,
                parentAxisSize: meta.parentAxisSize,
                distanceFromEdge: 0,
              ),
              child: Text(
                formatManilaClockTime(time),
                softWrap: false,
                maxLines: 1,
                style: AppTextStyles.cardMeta.copyWith(
                  fontSize: 11,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReadingSummary(String current, String forecast) {
    return Wrap(
      spacing: 20,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final entry
            in {'Current:': current, 'Forecast:': forecast}.entries)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${entry.key} ',
                  style: AppTextStyles.cardMeta,
                ),
                TextSpan(
                  text: entry.value,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLegend(bool hasFallbackHistory) {
    // Reserve the largest mode's height without leaving a hidden pH slot
    // before the EC-only legend.
    return IndexedStack(
      index: const ['Both', 'pH', 'EC'].indexOf(_parameter),
      alignment: Alignment.topLeft,
      children: [
        for (final parameter in ['Both', 'pH', 'EC'])
          _buildLegendItems(parameter, hasFallbackHistory),
      ],
    );
  }

  Widget _buildLegendItems(String parameter, bool hasFallbackHistory) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (parameter != 'EC')
          _legendItem(
            hasFallbackHistory ? 'pH estimated' : 'pH measured',
            _phColor,
          ),
        if (parameter != 'pH')
          _legendItem(
            hasFallbackHistory ? 'EC estimated' : 'EC measured',
            _ecColor,
          ),
        _legendItem('Forecast', _forecastColor, dashed: true),
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
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildLegend(hasFallbackHistory),
          generated,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildLegend(hasFallbackHistory)),
        const SizedBox(width: 16),
        generated,
      ],
    );
  }

  Widget _legendItem(String label, Color color, {bool dashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 26,
          height: 12,
          child: Center(
            child: dashed
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Container(width: 6, height: 2, color: color),
                    ],
                  )
                : Container(height: 2, color: color),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: AppTextStyles.cardMeta)),
      ],
    );
  }

  String _readingLabel(
    List<ForecastPoint> ph,
    List<ForecastPoint> ec, {
    required bool predicted,
    required String parameter,
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
    if (parameter != 'EC') {
      final value = valueFor(ph);
      if (value != null) values.add('pH $value');
    }
    if (parameter != 'pH') {
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
    final lineColor = predicted ? _forecastColor : color;
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: lineColor,
      barWidth: predicted ? 2 : 2.5,
      dashArray: predicted ? [6, 4] : null,
      dotData: FlDotData(
        show: predicted,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: _forecastColor,
          strokeWidth: 1,
          strokeColor: _forecastColor,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: lineColor.withValues(alpha: predicted ? 0.05 : 0.10),
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
