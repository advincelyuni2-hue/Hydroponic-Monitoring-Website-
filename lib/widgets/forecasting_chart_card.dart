import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/monitoring_models.dart';
import '../utils/responsive.dart';

class ForecastingChartCard extends StatelessWidget {
  final String activeTab; // 'pH Forecast' or 'EC Forecast'
  final ValueChanged<String> onTabChanged;
  final int selectedHours; // 6, 12, or 24
  final ValueChanged<int> onHoursChanged;
  final List<ForecastPoint> points;

  const ForecastingChartCard({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.selectedHours,
    required this.onHoursChanged,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final historical = points
        .where((p) => !p.isPredicted && p.hour >= -selectedHours)
        .toList();
    final predicted = points
        .where((p) => p.isPredicted && p.hour <= selectedHours)
        .toList();

    final historicalSpots = historical.map((p) => FlSpot(p.hour, p.value)).toList();
    final predictedSpots = <FlSpot>[
      if (historical.isNotEmpty) FlSpot(historical.last.hour, historical.last.value),
      ...predicted.map((p) => FlSpot(p.hour, p.value)),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. TABS & FILTER PILLS
          // Cramming both into one spaceBetween Row overflows on narrow
          // phones (tabs alone run ~240px, pills another ~135px, more
          // than a phone's available width) — so mobile stacks them
          // instead of squeezing them side by side.
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTab('pH Forecast', isMobile),
                        const SizedBox(width: 16),
                        _buildTab('EC Forecast', isMobile),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTimeFilterPills(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildTab('pH Forecast', isMobile),
                        const SizedBox(width: 24),
                        _buildTab('EC Forecast', isMobile),
                      ],
                    ),
                    _buildTimeFilterPills(),
                  ],
                ),
          const SizedBox(height: 12),
           Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
          const SizedBox(height: 24),

          // 2. CHART — same visual language as the dashboard's mini chart:
          // curved lines, gradient fill, gridlines, hover tooltip.
          SizedBox(
            height: isMobile ? 240 : 340,
            child: LineChart(
              LineChartData(
                minX: -selectedHours.toDouble(),
                maxX: selectedHours.toDouble(),
                minY: 3.0,
                maxY: 9.0,
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
                      reservedSize: isMobile ? 48 : 56,
                      interval: 0.5,
                      // fl_chart's `interval` already guarantees clean tick
                      // values, so there's no need to manually filter with
                      // a modulo check (which is unreliable with floating
                      // point numbers and can silently drop labels).
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'pH ${value.toStringAsFixed(1)}',
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
          const SizedBox(height: 12),

          // 3. AXIS LABELS — three fixed slots (not a spaceBetween Row) so
          // this can't overflow on narrow phones, same fix as the
          // dashboard's mini chart needed earlier.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '(Historical $selectedHours Hours)',
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
                  '(Predicted $selectedHours Hours)',
                  style: AppTextStyles.cardMeta,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isMobile) {
    final isActive = activeTab == title;
    return GestureDetector(
      onTap: () => onTabChanged(title),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: isMobile ? 16 : 20,
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isActive ? (isMobile ? 65 : 85) : 0,
            decoration: BoxDecoration(
              color: AppColors.primaryButton,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  /// Same rounded-pill visual language as the dashboard's mini chart's
  /// time filter, just with 6h/12h/24h instead of 4hr/8hr/12hr.
  Widget _buildTimeFilterPills() {
    final options = [6, 12, 24];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((hours) {
        final isSelected = selectedHours == hours;
        return GestureDetector(
          onTap: () => onHoursChanged(hours),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryButton : const Color(0xFFE2E2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${hours}h',
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
