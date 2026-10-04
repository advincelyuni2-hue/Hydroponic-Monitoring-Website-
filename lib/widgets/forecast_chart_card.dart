import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/manila_time.dart';
import '../utils/responsive.dart';

class ForecastChartCard extends StatefulWidget {
  final String title;
  final List<ForecastPoint> points;
  final DateTime? generatedAt;
  final VoidCallback? onExpand;

  const ForecastChartCard({
    super.key,
    required this.title,
    required this.points,
    this.generatedAt,
    this.onExpand,
  });

  @override
  State<ForecastChartCard> createState() => _ForecastChartCardState();
}

class _ForecastChartCardState extends State<ForecastChartCard> {
  int selectedHours = 8;

  static Color get chartLineColor => AppColors.accentGreen;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    // Filter points based on selected hour window (-selectedHours to +selectedHours)
    final filteredPoints = widget.points.where((point) {
      if (point.isPredicted) {
        return point.hour <= selectedHours;
      } else {
        return point.hour >= -selectedHours;
      }
    }).toList();

    final historical = filteredPoints.where((p) => !p.isPredicted).toList();
    final predicted = filteredPoints.where((p) => p.isPredicted).toList();

    final historicalSpots =
        historical.map((p) => FlSpot(p.hour, p.value)).toList();
    final predictedSpots = <FlSpot>[
      if (historical.isNotEmpty)
        FlSpot(historical.last.hour, historical.last.value),
      ...predicted.map((p) => FlSpot(p.hour, p.value)),
    ];

    // Compute dynamic Y-axis min/max
    final allValues = filteredPoints.map((p) => p.value).toList();
    final dataMin =
        allValues.isNotEmpty ? allValues.reduce(math.min) : 5.0;
    final dataMax =
        allValues.isNotEmpty ? allValues.reduce(math.max) : 7.5;
    final spread = dataMax - dataMin;
    final padding = math.max(spread * 0.18, 0.15);

    final chartMinY = math.max(0.0, dataMin - padding);
    final chartMaxY = dataMax + padding;

    // Current & Forecast Reading values
    final currentVal = historical.isNotEmpty
        ? historical.last.value.toStringAsFixed(2)
        : '--';
    final forecastVal = predicted.isNotEmpty
        ? predicted
            .reduce((a, b) =>
                (a.hour - selectedHours).abs() <= (b.hour - selectedHours).abs()
                    ? a
                    : b)
            .value
            .toStringAsFixed(2)
        : '--';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 4),
          Text(
            'Real-time sensor tracking vs. machine-learning forecast trajectory',
            style: AppTextStyles.cardMeta,
          ),
          SizedBox(height: isMobile ? 16 : 22),
          SizedBox(
            height: isMobile ? 220 : 320,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    minX: -selectedHours.toDouble(),
                    maxX: selectedHours.toDouble(),
                    minY: chartMinY,
                    maxY: chartMaxY,
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
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                        axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: isMobile ? 33 : 42,
                          interval: (chartMaxY - chartMinY) / 4,
                          getTitlesWidget: (val, _) => Text(
                            val.toStringAsFixed(1),
                            style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: isMobile ? 33 : 42,
                          interval: (chartMaxY - chartMinY) / 4,
                          getTitlesWidget: (val, _) => Text(
                            val.toStringAsFixed(1),
                            style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: selectedHours.toDouble(),
                          getTitlesWidget: (val, _) {
                            final centerTime =
                                widget.generatedAt ?? manilaNow();
                            final time = centerTime.add(
                              Duration(minutes: (val * 60).round()),
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
                    ),
                    extraLinesData: ExtraLinesData(
                      verticalLines: [
                        VerticalLine(
                          x: 0,
                          color: AppColors.textSecondary,
                          strokeWidth: 1,
                          dashArray: [5, 4],
                        ),
                      ],
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.cardBackground,
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (spots) => spots.map((spot) {
                          final isConnector = spot.x <= 0 && spot.barIndex.isOdd;
                          if (isConnector) return null;
                          return LineTooltipItem(
                            'Value ${spot.y.toStringAsFixed(2)}',
                            AppTextStyles.bodyBold.copyWith(
                              color: chartLineColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: historicalSpots,
                        isCurved: true,
                        color: chartLineColor,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: chartLineColor.withValues(alpha: 0.10),
                        ),
                      ),
                      LineChartBarData(
                        spots: predictedSpots,
                        isCurved: true,
                        color: chartLineColor,
                        barWidth: 2,
                        dashArray: [6, 4],
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: chartLineColor.withValues(alpha: 0.05),
                        ),
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
                              text: currentVal,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: '  Forecast '),
                            TextSpan(
                              text: forecastVal,
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
          _buildLegendAndFooter(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final titleWidget = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.show_chart, color: AppColors.accentGreen),
        Text(widget.title, style: AppTextStyles.sectionTitle),
      ],
    );

    final timeFilterControls = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.calloutBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [4, 8, 12].map((hours) {
          final isSelected = selectedHours == hours;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => selectedHours = hours),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryButton
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${hours}h',
                style: AppTextStyles.cardMeta.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          const SizedBox(height: 12),
          timeFilterControls,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titleWidget),
        timeFilterControls,
      ],
    );
  }

  Widget _buildLegendAndFooter(bool isMobile) {
    final legend = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: chartLineColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text('Measured / Predicted trajectory', style: AppTextStyles.cardMeta),
      ],
    );

    final viewMoreBtn = widget.onExpand != null
        ? TextButton(
            onPressed: widget.onExpand,
            child: Text('View forecast details', style: AppTextStyles.cardMeta),
          )
        : null;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          legend,
          if (viewMoreBtn != null) ...[
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: viewMoreBtn),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        legend,
        if (viewMoreBtn != null) viewMoreBtn,
      ],
    );
  }
}