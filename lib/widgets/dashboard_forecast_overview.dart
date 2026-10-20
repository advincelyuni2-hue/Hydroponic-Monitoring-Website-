import 'sensor_offline_state.dart';
import 'card_info_tooltip.dart';
import 'mobile_graph_card.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../models/forecast_insight_summary.dart';
import '../models/forecasting_models.dart' as forecasting;
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
      DashboardForecastOverviewState();
}

class DashboardForecastOverviewState
    extends State<DashboardForecastOverview> {
  String _parameter = 'Both';
  int _hours = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final saved = PageStorage.maybeOf(context)?.readState(
      context,
      identifier: 'forecast-overview-filters',
    );
    if (saved is Map<String, Object>) {
      _parameter = saved['parameter'] as String;
      _hours = saved['hours'] as int;
    }
  }

  void _saveFilters() {
    PageStorage.maybeOf(context)?.writeState(
      context,
      <String, Object>{'parameter': _parameter, 'hours': _hours},
      identifier: 'forecast-overview-filters',
    );
  }

  static Color get _phColor => AppColors.accentGreen;
  // Cyan/Blue color for EC matching reference image
static Color get _ecColor => AppColors.accentTeal;
  static const Color _forecastColor = Color(0xFFF57000);

  static const List<double> niceSteps = [
    0.05, 0.1, 0.2, 0.25, 0.5, 1, 2, 2.5, 5, 10, 20, 25, 50, 100, 200, 250,
    500, 1000,
  ];

  static double identity(double value) => value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final scale =
              MediaQuery.textScalerOf(context).scale(14) / 14;
          final narrow = constraints.maxWidth < 760 * scale;
          if (MobileGraphPage.isActive(context)) {
            return buildCard(context, narrow);
          }
          return SizedBox(
            height: constraints.hasBoundedHeight
                ? constraints.maxHeight
                : (narrow ? 600 : 440) * scale,
            child: buildCard(context, narrow),
          );
        },
      );

  Widget buildCard(BuildContext context, bool isMobile) {
    if (widget.isOffline ||
        widget.isCalibrating ||
        widget.forecastIssue != null) {
      final lastReceived = widget.latestSensorRecordedAt == null
          ? 'No sensor data received'
          : 'Last received ${formatManilaDateTime(toManilaTime(widget.latestSensorRecordedAt!))}';
      return Container(
        width: double.infinity,
        padding: MobileGraphPage.isActive(context)
            ? EdgeInsets.zero
            : EdgeInsets.all(isMobile ? 16 : 20),
        decoration: MobileGraphPage.isActive(context)
            ? null
            : AppDecorations.card(),
        child: MobileGraphComposition(
          chartIndex: 1,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.isOffline && !widget.isCalibrating
                ? OfflineHeader(child: _buildHeader(isMobile))
                : _buildHeader(isMobile),
            Expanded(
              child: widget.isOffline && !widget.isCalibrating
                  ? const SensorOfflineBody.forecast()
                  : SingleChildScrollView(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isCalibrating ? Icons.tune : Icons.cloud_off,
                              size: 42,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.isCalibrating
                                  ? 'Calibration in progress'
                                  : 'Sensor offline',
                              style: AppTextStyles.sectionTitle,
                            ),
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
            ),
          ],
        ),
      );
    }

    final ph = _filtered(widget.phPoints);
    final ec = _filtered(widget.ecPoints);
    final phRange = rangeFor(ph, fallback: const ChartRange(5, 7));
    final ecRange = rangeFor(ec, fallback: const ChartRange(1, 2));
    final both = _parameter == 'Both';

    final hasFallbackHistory = [...ph, ...ec].any(
      (point) => !point.isPredicted && point.isFallback,
    );

    final chartRange = both
        ? _rangeFor([...ph, ...ec], fallback: const ChartRange(0, 10))
        : _parameter == 'pH'
            ? phRange
            : ecRange;

    final showPhBars = _parameter != 'EC' && ph.isNotEmpty;
    final showEcBars = _parameter != 'pH' && ec.isNotEmpty;
    final dual = showPhBars && showEcBars;
    final maxIntervals = isMobile ? 4 : 6;

    final AxisRange left = dual
        ? niceAxis(phRange.minimum, phRange.maximum, maxIntervals: maxIntervals)
        : niceAxis(chartRange.minimum, chartRange.maximum, maxIntervals: maxIntervals);

    final AxisRange? right = dual
        ? _alignedAxis(ecRange.minimum, ecRange.maximum, left.intervals)
        : null;

    final r = right;
    final axisScale =
        r == null ? 1.0 : (left.max - left.min) / (r.max - r.min);

    double ecToPlot(double v) =>
        r == null ? v : left.min + (v - r.min) * axisScale;
    double ecToReal(double y) =>
        r == null ? y : r.min + (y - left.min) / axisScale;

    final plots = <_PlotBar>[
      if (_parameter != 'EC')
        ..._seriesBars(
          ph,
          param: 'pH',
          color: _phColor,
          fillHistorical: true,
          fillPredicted: !dual,
        ),
      if (_parameter != 'pH')
        ..._seriesBars(
          ec,
          param: 'EC',
          color: _ecColor,
          toPlot: ecToPlot,
          toReal: ecToReal,
          fillHistorical: !showPhBars,
          fillPredicted: !dual,
        ),
    ];

    final infos = [for (final p in plots) p.info];
    final leftIsEc = showEcBars && !showPhBars;

    return Container(
      width: double.infinity,
      padding: MobileGraphPage.isActive(context)
          ? EdgeInsets.zero
          : EdgeInsets.all(isMobile ? 16 : 20),
      decoration: MobileGraphPage.isActive(context)
          ? null
          : AppDecorations.card(),
      child: MobileGraphComposition(
        chartIndex: 1,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 8),
          _buildReadingSummaryBadges(ph, ec),
          const SizedBox(height: 12),
          Expanded(
            child: MobileGraphTimeline(
              pointCount: _parameter == 'pH'
                  ? ph.length
                  : _parameter == 'EC'
                      ? ec.length
                      : math.max(ph.length, ec.length),
              child: Padding(
                padding: EdgeInsets.only(right: isMobile ? 8 : 0),
                child: LayoutBuilder(
                  builder: (context, chartSpace) => MobileLineChart(
                    LineChartData(
                      clipData: const FlClipData.all(),
                      minX: -_hours.toDouble(),
                      maxX: _hours.toDouble(),
                      minY: left.min,
                      maxY: left.max,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: left.step,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.chartGrid.withValues(alpha: 0.55),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: AppColors.chartGrid),
                          // Green axis line on the left (pH or single axis)
                          left: BorderSide(
                            color: leftIsEc ? _ecColor : _phColor,
                            width: 2.5,
                          ),
                          // Cyan axis line on the right when dual axis is shown
                          right: dual
                              ? BorderSide(color: _ecColor, width: 2.5)
                              : BorderSide.none,
                        ),
                      ),
                      titlesData: _titlesData(
                        left: left,
                        right: right,
                        leftIsEc: leftIsEc,
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
                              tooltipRoundedRadius: 10,
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              tooltipMargin: 10,
                              maxContentWidth: 220,
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              tooltipBorder:
                                  BorderSide(color: AppColors.chartGrid),
                              getTooltipItems: (spots) {
                                var headerShown = false;
                                return spots.map((spot) {
                                  final info = infos[spot.barIndex];
                                  // Each predicted line includes the current
                                  // historical point so the two segments
                                  // connect. Suppress that duplicate
                                  // connector in the tooltip.
                                  final isPredictedConnector =
                                      spot.x <= 0 && info.predicted;
                                  if (isPredictedConnector) return null;


                                  final isPh = info.param == 'pH';
                                  final value = info
                                      .toReal(spot.y)
                                      .toStringAsFixed(isPh ? 2 : 3);
                                  final unit = isPh ? '' : ' mS/cm';
                                  final name = info.predicted
                                      ? '${info.param} forecast'
                                      : info.param;
                                  final dotColor = info.predicted
                                      ? _forecastColor
                                      : (isPh ? _phColor : _ecColor);
                                  // Orange text is hard to read on white;
                                  // darken it for the value.
                                  final textColor = info.predicted
                                      ? Color.lerp(
                                          _forecastColor, Colors.black, 0.3)!
                                      : dotColor;
                                  final header = headerShown
                                      ? ''
                                      : '${_timeAtHour(spot.x)}\n';
                                  headerShown = true;


                                  return LineTooltipItem(
                                    header,
                                    AppTextStyles.cardMeta.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.left,
                                    children: [
                                      TextSpan(
                                        text: '● ',
                                        style: TextStyle(
                                          color: dotColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '$name  ',
                                        style: AppTextStyles.cardMeta
                                            .copyWith(fontSize: 12),
                                      ),
                                      TextSpan(
                                        text: '$value$unit',
                                        style: AppTextStyles.bodyBold.copyWith(
                                          color: textColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [for (final p in plots) p.bar],
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
          child: CardInfoTitle(
            'Forecast Overview',
            description:
                'Shows recent readings and available model predictions for pH and EC over the selected horizon.',
            style: AppTextStyles.sectionTitle
                .copyWith(fontSize: isMobile ? 17 : 19),
          ),
        ),
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
          if (!MobileGraphPage.isActive(context)) title,
          const SizedBox(height: 8),
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: controls,
          ),
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

  /// Badge-style summary matching reference image (pH badge + EC badge)
  Widget _buildReadingSummaryBadges(
    List<ForecastPoint> ph,
    List<ForecastPoint> ec,
  ) {
    final showPh = _parameter != 'EC' && ph.isNotEmpty;
    final showEc = _parameter != 'pH' && ec.isNotEmpty;

    final phCurrent = _getReadingValue(ph, predicted: false, decimals: 2);
    final phForecast = _getReadingValue(ph, predicted: true, decimals: 2);

    final ecCurrent = _getReadingValue(ec, predicted: false, decimals: 3);
    final ecForecast = _getReadingValue(ec, predicted: true, decimals: 3);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showPh && phCurrent != null)
          _badgeChip(
            param: 'pH',
            current: phCurrent,
            forecast: phForecast,
            color: _phColor,
            bgColor: const Color(0xFFEFF7E9),
          ),
        if (showEc && ecCurrent != null)
          _badgeChip(
            param: 'EC',
            current: ecCurrent,
            forecast: ecForecast,
            color: _ecColor,
            bgColor: const Color(0xFFEBF3FC),
          ),
      ],
    );
  }

  Widget _badgeChip({
    required String param,
    required String current,
    String? forecast,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$param  ',
            style: AppTextStyles.cardMeta.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            current,
            style: AppTextStyles.bodyBold.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
          if (forecast != null) ...[
            Text(
              '  →  ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              forecast,
              style: AppTextStyles.bodyBold.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _getReadingValue(
    List<ForecastPoint> points, {
    required bool predicted,
    required int decimals,
  }) {
    if (predicted) {
      return _modelSummary(points).valueAt(_hours)?.toStringAsFixed(decimals);
    }
    final matching = points.where((p) => !p.isPredicted).toList();
    if (matching.isEmpty) return null;
    final point = matching.reduce((a, b) => a.hour >= b.hour ? a : b);
    return point.value.toStringAsFixed(decimals);
  }

  FlTitlesData _titlesData({
    required AxisRange left,
    required AxisRange? right,
    required bool leftIsEc,
    required bool isMobile,
    required double chartWidth,
  }) {
    final r = right;
    final dual = r != null;
    final centerTime = widget.generatedAt ?? manilaNow();
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final leftReserved = (isMobile ? 34 : 40) * textScale;
    final rightReserved = dual ? (isMobile ? 34 : 40) * textScale : 0.0;

    var labelWidth = 0.0;
    if (isMobile) {
      for (final hour in [-_hours, 0, _hours]) {
        final painter = TextPainter(
          text: TextSpan(
            text: formatManilaClockTime(
              centerTime.add(Duration(hours: hour)),
            ),
            style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        labelWidth = math.max(labelWidth, painter.width);
        painter.dispose();
      }
    }

    final axisNameSize = dual || !isMobile ? 18.0 : 0.0;
    final plotWidth = math.max(
      0.0,
      chartWidth - leftReserved - rightReserved - (dual ? axisNameSize * 2 : 0),
    );

    final tickCount = isMobile
        ? (plotWidth / (labelWidth + 16)).floor().clamp(1, 3)
        : 5;
    final horizontalInterval =
        isMobile ? _hours * (tickCount == 2 ? 2.0 : 1.0) : _hours / 2;

    TextStyle axisNameStyle(Color color) => AppTextStyles.cardMeta.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        );

    Widget tickLabel(String text, TitleMeta meta, {required bool onRight, required Color color}) {
      final label = Text(
        text,
        style: AppTextStyles.cardMeta.copyWith(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      );

      if (!isMobile) {
        return Padding(
          padding: onRight
              ? const EdgeInsets.only(left: 6)
              : const EdgeInsets.only(right: 6),
          child: label,
        );
      }
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
    }

    return FlTitlesData(
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      leftTitles: AxisTitles(
        axisNameSize: axisNameSize,
        axisNameWidget: (isMobile && !dual)
            ? null
            : Text(
                leftIsEc ? 'EC (mS/cm)' : 'pH',
                style: axisNameStyle(leftIsEc ? _ecColor : _phColor),
              ),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: leftReserved,
          interval: left.step,
          getTitlesWidget: (value, meta) => tickLabel(
            _tickLabel(value, left.step),
            meta,
            onRight: false,
            color: leftIsEc ? _ecColor : _phColor,
          ),
        ),
      ),
      rightTitles: r == null
          ? const AxisTitles(sideTitles: SideTitles(showTitles: false))
          : AxisTitles(
              axisNameSize: axisNameSize,
              axisNameWidget: Text(
                isMobile ? 'EC' : 'EC (mS/cm)',
                style: axisNameStyle(_ecColor),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: rightReserved,
                interval: left.step,
                getTitlesWidget: (value, meta) {
                  final real = r.min +
                      (value - left.min) *
                          (r.max - r.min) /
                          (left.max - left.min);
                  return tickLabel(
                    _tickLabel(real, r.step),
                    meta,
                    onRight: true,
                    color: _ecColor,
                  );
                },
              ),
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
                style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend(bool hasFallbackHistory) {
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
        if (parameter != 'EC')
          _legendItem('pH forecast', _phColor, dashed: true),
        if (parameter != 'pH')
          _legendItem(
            hasFallbackHistory ? 'EC estimated' : 'EC measured',
            _ecColor,
          ),
        if (parameter != 'pH')
          _legendItem('EC forecast', _ecColor, dashed: true),
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

  ForecastInsightSummary _modelSummary(List<ForecastPoint> points) =>
      ForecastInsightSummary(
        forecast: points
            .map((point) => forecasting.ForecastingChartPoint(
                  hour: point.hour,
                  value: point.value,
                  isPredicted: point.isPredicted,
                  isFallback: point.isFallback,
                ))
            .toList(),
        minimum: 0,
        maximum: 1,
      );

  List<ForecastPoint> _filtered(List<ForecastPoint> points) {
    return [
      ...points.where((point) =>
          !point.isPredicted &&
          point.hour.isFinite &&
          point.value.isFinite &&
          point.hour >= -_hours &&
          point.hour <= 0),
      for (final point in _modelSummary(points).points)
        if (point.hour <= _hours)
          ForecastPoint(
            hour: point.hour,
            value: point.value,
            isPredicted: true,
            isFallback: false,
          ),
    ]..sort((a, b) => a.hour.compareTo(b.hour));
  }

  List<_PlotBar> _seriesBars(
    List<ForecastPoint> points, {
    required String param,
    required Color color,
    double Function(double) toPlot = identity,
    double Function(double) toReal = identity,
    required bool fillHistorical,
    required bool fillPredicted,
  }) {
    final historical =
        points.where((point) => !point.isPredicted).toList();
    final predicted =
        points.where((point) => point.isPredicted).toList();

    final historicalSpots = historical
        .map((point) => FlSpot(point.hour, toPlot(point.value)))
        .toList();

    final predictedSpots = <FlSpot>[
      if (historical.isNotEmpty)
        FlSpot(historical.last.hour, toPlot(historical.last.value)),
      ...predicted
          .map((point) => FlSpot(point.hour, toPlot(point.value))),
    ];

    return [
      if (historicalSpots.isNotEmpty)
        _PlotBar(
          _bar(historicalSpots,
              color: color, predicted: false, fill: fillHistorical),
          _BarInfo(param, false, toReal),
        ),
      if (predictedSpots.isNotEmpty)
        _PlotBar(
          _bar(predictedSpots,
              color: color, predicted: true, fill: fillPredicted),
          _BarInfo(param, true, toReal),
        ),
    ];
  }

  LineChartBarData _bar(
    List<FlSpot> spots, {
    required Color color,
    required bool predicted,
    required bool fill,
  }) {
    final lineColor = predicted ? color : color;
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: lineColor,
      barWidth: predicted ? 2.25 : 2.5,
      isStrokeCapRound: true,
      dashArray: predicted ? [6, 4] : null,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: fill,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: predicted ? 0.08 : 0.16),
            lineColor.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  ChartRange rangeFor(
    List<ForecastPoint> points, {
    required ChartRange fallback,
  }) {
    if (points.isEmpty) return fallback;
    final values = points.map((point) => point.value);
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    final spread = maximum - minimum;
    final padding = math.max(spread * 0.18, maximum.abs() * 0.03);
    return ChartRange(
      math.max(0, minimum - padding),
      maximum + padding,
    );
  }

  ChartRange _rangeFor(
    List<ForecastPoint> points, {
    required ChartRange fallback,
  }) =>
      rangeFor(points, fallback: fallback);

  String _timeAtHour(double hour) {
    final center = widget.generatedAt ?? manilaNow();
    return formatManilaClockTime(
      center.add(Duration(minutes: (hour * 60).round())),
    );
  }

  static AxisRange niceAxis(
    double low,
    double high, {
    required int maxIntervals,
  }) {
    for (final step in niceSteps) {
      var lo = (low / step).floorToDouble() * step;
      if (lo < 0) lo = 0;
      var hi = (high / step).ceilToDouble() * step;
      var n = ((hi - lo) / step).round();
      if (n < 2) {
        hi = lo + 2 * step;
        n = 2;
      }
      if (n <= maxIntervals) return AxisRange(lo, hi, step);
    }
    final lo = math.max(low, 0.0);
    return AxisRange(lo, high, (high - lo) / maxIntervals);
  }

  static AxisRange _alignedAxis(double low, double high, int intervals) {
    for (final step in niceSteps) {
      var lo = (low / step).floorToDouble() * step;
      if (lo < 0) lo = 0;
      final hi = lo + intervals * step;
      if (hi >= high - 1e-9) return AxisRange(lo, hi, step);
    }
    final span = math.max(high - low, 0.1);
    return AxisRange(low, low + span, span / intervals);
  }

  static String _tickLabel(double value, double step) {
    if (step >= 1 && (step - step.roundToDouble()).abs() < 1e-9) {
      return value.toStringAsFixed(0);
    }
    final tenths = step * 10;
    if ((tenths - tenths.roundToDouble()).abs() < 1e-9) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }
}

class ChartRange {
  final double minimum;
  final double maximum;
  const ChartRange(this.minimum, this.maximum);
}

class AxisRange {
  final double min;
  final double max;
  final double step;
  const AxisRange(this.min, this.max, this.step);
  int get intervals => ((max - min) / step).round();
}

class _BarInfo {
  final String param;
  final bool predicted;
  final double Function(double) toReal;
  const _BarInfo(this.param, this.predicted, this.toReal);
}

class _PlotBar {
  final LineChartBarData bar;
  final _BarInfo info;
  const _PlotBar(this.bar, this.info);
}