import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/monitoring_models.dart';
import '../utils/responsive.dart';


class ForecastChartCard extends StatefulWidget {
  final String title;
  final List<ForecastPoint> points;
  final VoidCallback? onExpand;

  const ForecastChartCard({
    super.key,
    required this.title,
    required this.points,
    this.onExpand,
  });

  @override
  State<ForecastChartCard> createState() => _ForecastChartCardState();
}

class _ForecastChartCardState extends State<ForecastChartCard> {
  // Currently selected time filter (4, 8, or 12 hours)
  int _selectedHours = 8;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    // Filter historical points to match selected hours (-_selectedHours to 0)
    final historical = widget.points
        .where((p) => !p.isPredicted && p.hour >= -_selectedHours)
        .toList();

    // Filter predicted points to match selected hours (0 to _selectedHours)
    final predicted = widget.points
        .where((p) => p.isPredicted && p.hour <= _selectedHours)
        .toList();

    // Prepend last historical point so the dashed line connects smoothly
    final predictedSpots = <FlSpot>[
      if (historical.isNotEmpty) FlSpot(historical.last.hour, historical.last.value),
      ...predicted.map((p) => FlSpot(p.hour, p.value)),
    ];
    final historicalSpots = historical.map((p) => FlSpot(p.hour, p.value)).toList();


    final allValues = [...historicalSpots, ...predictedSpots].map((s) => s.y).toList();
    final dataMin = allValues.reduce((a, b) => a < b ? a : b);
    final dataMax = allValues.reduce((a, b) => a > b ? a : b);
    final rawPadding = (dataMax - dataMin) * 0.2;
    final padding = rawPadding < 0.15 ? 0.15 : rawPadding; // avoid a flat/degenerate range
    final chartMinY = dataMin - padding;
    final chartMaxY = dataMax + padding;
    final axisInterval = (chartMaxY - chartMinY) / 4;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP HEADER ROW: Title on Left, Filter Pills on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: isMobile ? 18 : 22),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildTimeFilterPills(),
            ],
          ),
          const SizedBox(height: 4),

          // 2. SUBTITLE
          Text(
            'Real-time sensor tracking vs. 12-hour ML predictive trajectory',
            style: AppTextStyles.cardMeta,
          ),
          SizedBox(height: isMobile ? 12 : 16),

          // 3. GRAPH WITH ORIGINAL GRADIENT & CURVES
          SizedBox(
            height: isMobile ? 170 : 200,
            child: LineChart(
              LineChartData(
                minX: -_selectedHours.toDouble(),
                maxX: _selectedHours.toDouble(),
                minY: chartMinY,
                maxY: chartMaxY,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.chartGrid),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isMobile ? 34 : 40,
                      interval: axisInterval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
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
                      dashArray: [4, 4],
                    ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFFE5FFDE),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      if (touchedSpots.isEmpty) return [];

                      final primarySpot = touchedSpots.first;

                      return touchedSpots.map((spot) {
                        if (spot == primarySpot) {
                          return LineTooltipItem(
                            spot.y.toStringAsFixed(2),
                            AppTextStyles.cardMeta.copyWith(
                              color: const Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Historical Data Line (Curved + Gradient Fill)
                  LineChartBarData(
                    spots: historicalSpots,
                    isCurved: true,
                    color: AppColors.chartLine,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.chartLine.withValues(alpha: 0.22),
                          AppColors.chartLine.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Predicted Data Line (Curved + Dashed + Gradient Fill)
                  LineChartBarData(
                    spots: predictedSpots,
                    isCurved: true,
                    color: AppColors.chartLine,
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.chartLine.withValues(alpha: 0.10),
                          AppColors.chartLine.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 4. AXIS LABELS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '(Historical $_selectedHours Hours)',
                  style: AppTextStyles.cardMeta,
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: Text(
                  'Current Time',
                  style: AppTextStyles.cardMeta,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '(Predicted $_selectedHours Hours)',
                  style: AppTextStyles.cardMeta,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          // 5. VIEW MORE ACTION LINK
          // Built as a TextButton with AppTextStyles.cardMeta (same widget +
          // same style as "View all notifications" on the Recent
          // Notifications card), so both links share identical font size
          // and hover/press feedback instead of "View more" being a plain
          // GestureDetector with its own custom size/color.
          if (widget.onExpand != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onExpand,
                child: Text('View more', style: AppTextStyles.cardMeta),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Filter Pills (4hr / 8hr / 12hr)
  Widget _buildTimeFilterPills() {
    final options = [4, 8, 12];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((hours) {
        final isSelected = _selectedHours == hours;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedHours = hours;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryButton : const Color(0xFFE2E2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${hours}hr',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
