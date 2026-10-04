import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

class ReportsAnalyticsCard extends StatefulWidget {
  final String selectedParameter;
  final String selectedTimeframe;
  final List<AnalyticsPoint> points;
  final double minThreshold;
  final double maxThreshold;
  final ValueChanged<String> onParameterChanged;
  final ValueChanged<String> onTimeframeChanged;

  const ReportsAnalyticsCard({
    super.key,
    required this.selectedParameter,
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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

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
            'Historical sensor trends and parameter telemetry',
            style: AppTextStyles.cardMeta,
          ),
          SizedBox(height: isMobile ? 16 : 22),
          SizedBox(
            height: isMobile ? 230 : 350,
            child: LineChart(_buildTrendChartData(isMobile)),
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
        Text('Historical Telemetry Trends', style: AppTextStyles.sectionTitle),
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
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: currentColor, shape: BoxShape.circle),
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
            Text('Out of range (hover for details)',
                style: AppTextStyles.cardMeta),
          ],
        ),
      ],
    );
  }

  LineChartData _buildTrendChartData(bool isMobile) {
    final spots = <FlSpot>[];
    for (int i = 0; i < widget.points.length; i++) {
      spots.add(FlSpot(i.toDouble(), widget.points[i].value));
    }

    final currentColor = widget.selectedParameter == 'pH' ? phColor : ecColor;
    bool isOut(double value) =>
      value < widget.minThreshold || value > widget.maxThreshold;
    var dataMin = widget.minThreshold;
    var dataMax = widget.maxThreshold;
    for (final point in widget.points) {
      if (!point.value.isFinite) continue;
      if (point.value < dataMin) dataMin = point.value;
      if (point.value > dataMax) dataMax = point.value;
    }
    final dataRange = dataMax - dataMin;
    final padding = (dataRange * 0.1).clamp(0.1, double.infinity).toDouble();
    final paddedMinY = ((dataMin - padding) / 0.5).floorToDouble() * 0.5;
    final minY = paddedMinY < 0 ? 0.0 : paddedMinY;
    final maxY = (((dataMax + padding) / 0.5).ceilToDouble() * 0.5)
        .clamp(0.5, double.infinity)
        .toDouble();
    final labelIntervals = isMobile ? 5 : 6;
    final xInterval = widget.points.length > 1
        ? ((widget.points.length - 2 + labelIntervals) ~/ labelIntervals)
        : 1;

    return LineChartData(
      minX: 0,
      maxX:
          widget.points.isNotEmpty ? (widget.points.length - 1).toDouble() : 5,
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
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
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: isMobile ? 33 : 42,
            interval: 0.5,
            getTitlesWidget: (val, _) => Text(
              val.toStringAsFixed(1),
              style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
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
          ),
          HorizontalLine(
            y: widget.minThreshold,
            color: AppColors.alertBorder,
            strokeWidth: 1.2,
            dashArray: [5, 5],
          ),
        ],
      ),
      lineTouchData: LineTouchData(
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
                    radius: 6,
                    color: isOut(spot.y) ? AppColors.alertBorder : currentColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
            )
            .toList(),
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.cardBackground,
          tooltipRoundedRadius: 8,
          getTooltipItems: (spots) => spots.map((spot) {
            final idx = spot.x.toInt();
            final label = idx >= 0 && idx < widget.points.length
                ? widget.points[idx].label
                : '';
            final unit = widget.selectedParameter == 'pH' ? '' : ' mS/cm';
            final range =
                '${widget.minThreshold.toStringAsFixed(1)} - '
                '${widget.maxThreshold.toStringAsFixed(1)}';
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
              AppTextStyles.cardMeta,
              children: [
                TextSpan(
                  text:
                      '${widget.selectedParameter} ${spot.y.toStringAsFixed(2)}$unit\n',
                  style: AppTextStyles.bodyBold.copyWith(color: currentColor),
                ),
                TextSpan(
                  text: verdict,
                  style: AppTextStyles.cardMeta.copyWith(
                    color: verdictColor,
                    fontWeight: FontWeight.w700,
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
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, _) => isOut(spot.y),
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4.5,
              color: AppColors.alertBorder,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: currentColor.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}
