import 'card_info_tooltip.dart';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'mobile_graph_card.dart';

class ReportsAnalyticsCard extends StatefulWidget {
  final String selectedParameter;
  final bool compact;
  final bool isLoading;
  final String selectedTimeframe;
  final List<AnalyticsPoint> points;
  final double minThreshold;
  final double maxThreshold;
  final ValueChanged<String> onParameterChanged;
  final ValueChanged<String> onTimeframeChanged;

  const ReportsAnalyticsCard({
    super.key,
    required this.selectedParameter,
    this.compact = false,
    this.isLoading = false,
    required this.selectedTimeframe,
    required this.points,
    required this.minThreshold,
    required this.maxThreshold,
    required this.onParameterChanged,
    required this.onTimeframeChanged,
  });

  @override
  State<ReportsAnalyticsCard> createState() => ReportsAnalyticsCardState();
}

class ReportsAnalyticsCardState extends State<ReportsAnalyticsCard> {
  static Color get phColor => AppColors.accentGreen;
  static Color get ecColor => AppColors.accentTeal;

  // Steps used to pick "nice" axis ticks (4, 6, 8 ... / 1.5, 1.75, 2 ...).
  static const List<double> _niceSteps = [
    0.05, 0.1, 0.2, 0.25, 0.5, 1, 2, 2.5, 5, 10, 20, 25, 50, 100, 200, 250,
    500, 1000,
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    if (widget.isLoading) {
      return Container(
        height: 320,
        decoration: MobileGraphPage.isActive(context) ? null : AppDecorations.card(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final latest = widget.points.isEmpty ? null : widget.points.last;
    final outOfRange = latest != null &&
        (latest.value < widget.minThreshold || latest.value > widget.maxThreshold);
    final outsideCount = widget.points.where((point) =>
        point.value < widget.minThreshold || point.value > widget.maxThreshold).length;

    return Container(
      width: double.infinity,
      padding: MobileGraphPage.isActive(context) ? EdgeInsets.zero : EdgeInsets.all(isMobile || widget.compact ? 16 : 20),
      decoration: MobileGraphPage.isActive(context) ? null : AppDecorations.card(),
      child: MobileGraphComposition(
        chartIndex: 4,
        subtitle: 'Historical sensor trends and parameter telemetry',
        sheetTitle: 'Telemetry details',
        summaries: [
          MobileGraphSummary(title: 'Latest reading',
            value: latest == null ? 'No readings' : latest.value.toStringAsFixed(2),
            detail: latest == null ? null
                : '${latest.label}\n${widget.selectedParameter} ? ${outOfRange ? "Out of range" : "In range"}',
            valueColor: outOfRange ? AppColors.alertBorder : AppColors.accentGreen),
          MobileGraphSummary(title: 'Ideal range',
            value: '${widget.minThreshold.toStringAsFixed(2)} ? ${widget.maxThreshold.toStringAsFixed(2)}',
            detail: widget.points.isEmpty ? 'No readings available'
                : '$outsideCount of ${widget.points.length} readings out of range during ${widget.selectedTimeframe}'),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 5),
          if (MobileGraphPage.isActive(context)) const SizedBox.shrink() else Text(
            'Historical sensor trends and parameter telemetry',
            style: AppTextStyles.cardMeta,
          ),
          SizedBox(height: isMobile || widget.compact ? 16 : 22),
          SizedBox(
            height: isMobile
                ? (context.findAncestorWidgetOfExactType<MobileGraphPage>() != null ? 320 : 230)
                : (widget.compact ? 260 : 350),
            child: MobileGraphTimeline(
              pointCount: widget.points.length,
              child: MobileLineChart(_buildTrendChartData(isMobile),
                preserveAxes: MobileGraphPage.isActive(context)),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
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
        Icon(Icons.show_chart, color: AppColors.accentGreen),
        CardInfoTitle('Historical Telemetry Trends', description: 'Shows historical sensor readings and how they change over the selected period.', style: AppTextStyles.sectionTitle),
      ],
    );

    final controls = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _selector<String>(
          values: const ['pH', 'EC'],
          selected: widget.selectedParameter,
          label: (val) => val,
          onSelected: widget.onParameterChanged,
        ),
        _selector<String>(
          values: const ['7d', '30d', '90d'],
          selected: widget.selectedTimeframe,
          label: (val) => val,
          onSelected: widget.onTimeframeChanged,
        ),
      ],
    );

    if (MobileGraphPage.isActive(context)) {
      return MobileGraphControls(value: widget.selectedParameter,
        values: const ['pH', 'EC'], onChanged: widget.onParameterChanged,
        trailing: _selector<String>(values: const ['7d', '30d', '90d'],
          selected: widget.selectedTimeframe, label: (value) => value,
          onSelected: widget.onTimeframeChanged));
    }
    if (!Responsive.isDesktop(context) || widget.compact) {
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

  Widget _buildLegend() {
    final currentColor = widget.selectedParameter == 'pH' ? phColor : ecColor;

    return Wrap(
      spacing: 18,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text('${widget.selectedParameter} measured values',
                style: AppTextStyles.cardMeta),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                  color: AppColors.alertBorder, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('Out of range (shown on hover)',
                style: AppTextStyles.cardMeta),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              Container(width: 4, height: 2, color: AppColors.alertBorder),
              if (i < 2) const SizedBox(width: 2),
            ],
            const SizedBox(width: 6),
            Text('Ideal range limits', style: AppTextStyles.cardMeta),
          ],
        ),
      ],
    );
  }

  /// Picks a tick step so the axis starts and ends on round numbers
  /// and never needs more than [maxIntervals] gridlines.
  static _AxisRange _niceAxis(
    double dataMin,
    double dataMax, {
    required int maxIntervals,
  }) {
    final range = dataMax - dataMin;
    final pad = math.max(range * 0.1, 0.1);
    final lowTarget = dataMin - pad;
    final highTarget = dataMax + pad;
    for (final step in _niceSteps) {
      var lo = (lowTarget / step).floorToDouble() * step;
      if (lo < 0) lo = 0;
      var hi = (highTarget / step).ceilToDouble() * step;
      var n = ((hi - lo) / step).round();
      if (n < 2) {
        hi = lo + 2 * step;
        n = 2;
      }
      if (n <= maxIntervals) return _AxisRange(lo, hi, step);
    }
    final low = math.max(lowTarget, 0.0);
    return _AxisRange(low, highTarget, (highTarget - low) / maxIntervals);
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

  /// 5.500000 -> "5.5", 1.25 -> "1.25"
  static String _compact(double value) =>
      double.parse(value.toStringAsFixed(2)).toString();

  LineChartData _buildTrendChartData(bool isMobile) {
    final spots = <FlSpot>[];
    for (int i = 0; i < widget.points.length; i++) {
      spots.add(FlSpot(i.toDouble(), widget.points[i].value));
    }

    final isPh = widget.selectedParameter == 'pH';
    final currentColor = isPh ? phColor : ecColor;
    bool isOut(double value) =>
        value < widget.minThreshold || value > widget.maxThreshold;
    var dataMin = widget.minThreshold;
    var dataMax = widget.maxThreshold;
    for (final point in widget.points) {
      if (!point.value.isFinite) continue;
      if (point.value < dataMin) dataMin = point.value;
      if (point.value > dataMax) dataMax = point.value;
    }
    final axis = _niceAxis(dataMin, dataMax, maxIntervals: isMobile ? 5 : 8);
    final labelIntervals = isMobile ? 5 : 6;
    final xInterval = widget.points.length > 1
        ? ((widget.points.length - 2 + labelIntervals) ~/ labelIntervals)
        : 1;

    final limitLabelStyle = AppTextStyles.cardMeta.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: AppColors.alertBorder,
    );

    return LineChartData(
      minX: 0,
      maxX:
          widget.points.isNotEmpty ? (widget.points.length - 1).toDouble() : 5,
      minY: axis.min,
      maxY: axis.max,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: axis.step,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.chartGrid.withValues(alpha: 0.55),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(bottom: BorderSide(color: AppColors.chartGrid)),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          axisNameSize: 20,
          axisNameWidget: Text(
            isPh ? 'pH' : 'EC (mS/cm)',
            style: AppTextStyles.cardMeta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: currentColor,
            ),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: isMobile ? 38 : 44,
            interval: axis.step,
            getTitlesWidget: (val, _) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                _tickLabel(val, axis.step),
                style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: xInterval.toDouble(),
            getTitlesWidget: (val, _) {
              final idx = val.toInt();
              if (idx < 0 ||
                  idx >= widget.points.length ||
                  (val - idx).abs() > 0.001 ||
                  idx % xInterval != 0) {
                return const SizedBox.shrink();
              }
              final label = widget.points[idx].label;
              final previousIdx = idx - xInterval;
              if (previousIdx >= 0 &&
                  widget.points[previousIdx].label == label) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  label,
                  style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
                  maxLines: 1,
                  softWrap: false,
                ),
              );
            },
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: widget.maxThreshold,
            color: AppColors.alertBorder,
            strokeWidth: 1.2,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 4, bottom: 2),
              style: limitLabelStyle,
              labelResolver: (_) => 'Max ${_compact(widget.maxThreshold)}',
            ),
          ),
          HorizontalLine(
            y: widget.minThreshold,
            color: AppColors.alertBorder,
            strokeWidth: 1.2,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 4, bottom: 2),
              style: limitLabelStyle,
              labelResolver: (_) => 'Min ${_compact(widget.minThreshold)}',
            ),
          ),
        ],
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        // The dot only appears on the hovered point: red when out of range,
        // the parameter colour when it is within range.
        getTouchedSpotIndicator: (barData, indexes) => indexes
            .map(
              (i) => TouchedSpotIndicatorData(
                FlLine(
                  color: currentColor.withValues(alpha: 0.4),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 5.5,
                    color: isOut(spot.y) ? AppColors.alertBorder : currentColor,
                    strokeWidth: 2.5,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
            )
            .toList(),
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.cardBackground,
          tooltipRoundedRadius: 10,
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tooltipMargin: 10,
          maxContentWidth: 240,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipBorder: BorderSide(color: AppColors.chartGrid),
          getTooltipItems: (spots) => spots.map((spot) {
            final idx = spot.x.toInt();
            final label = idx >= 0 && idx < widget.points.length
                ? widget.points[idx].label
                : '';
            final unit = isPh ? '' : ' mS/cm';
            final value = spot.y.toStringAsFixed(isPh ? 2 : 3);
            final range = '${_compact(widget.minThreshold)} - '
                '${_compact(widget.maxThreshold)}';
            final String verdict;
            final Color verdictColor;
            if (spot.y > widget.maxThreshold) {
              verdict = 'Out of range (above $range)';
              verdictColor = AppColors.alertBorder;
            } else if (spot.y < widget.minThreshold) {
              verdict = 'Out of range (below $range)';
              verdictColor = AppColors.alertBorder;
            } else {
              verdict = 'Within range ($range)';
              verdictColor = AppColors.accentGreen;
            }
            return LineTooltipItem(
              '$label\n',
              AppTextStyles.cardMeta.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.left,
              children: [
                TextSpan(
                  text: '${widget.selectedParameter} $value$unit\n',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: currentColor,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: verdict,
                  style: AppTextStyles.cardMeta.copyWith(
                    color: verdictColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.15,
          preventCurveOverShooting: true,
          color: currentColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          // No resting dots: out-of-range points show up on hover only.
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                currentColor.withValues(alpha: 0.16),
                currentColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AxisRange {
  final double min;
  final double max;
  final double step;
  const _AxisRange(this.min, this.max, this.step);
}