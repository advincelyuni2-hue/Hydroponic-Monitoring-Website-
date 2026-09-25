import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/forecasting_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

class ForecastingChartCard extends StatelessWidget {
  final String activeTab; // 'pH Forecast' or 'EC Forecast'
  final ValueChanged<String> onTabChanged;
  final int selectedHours; // 4, 8, or 12
  final ValueChanged<int> onHoursChanged;
  final List<ForecastingChartPoint> points;

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
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    final historical = points
        .where((p) => !p.isPredicted && p.hour >= -selectedHours)
        .toList();
    final predicted = points
        .where((p) => p.isPredicted && p.hour <= selectedHours)
        .toList();

    final historicalSpots =
        historical.map((p) => FlSpot(p.hour, p.value)).toList();
    final predictedSpots = <FlSpot>[
      if (historical.isNotEmpty)
        FlSpot(historical.last.hour, historical.last.value),
      ...predicted.map((p) => FlSpot(p.hour, p.value)),
    ];

    bool isPh = activeTab.contains('pH');

    return Container(
      height: isDesktop ? 689 : null,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isDesktop ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // 1. Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTab('pH Forecast', isMobile),
                  SizedBox(width: isMobile ? 12 : 20),
                  _buildTab('EC Forecast', isMobile),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _buildTimeFilterPills(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),

          // 2. Scrollable Chart Viewport
          WidgetChildWrapper(
            isDesktop: isDesktop,
            child: ClipRRect(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: 650,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: LineChart(
                      LineChartData(
                        minX: -selectedHours.toDouble(),
                        maxX: selectedHours.toDouble(),
                        minY: 0.0,
                        maxY: 15.0,
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: AppColors.chartGrid),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: isMobile ? 48 : 56,
                              interval: 1.0,
                              getTitlesWidget: (value, meta) {
                                final label = isPh
                                    ? 'pH ${value.toStringAsFixed(1)}'
                                    : '${value.toStringAsFixed(1)} mS';
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    label,
                                    style: AppTextStyles.cardMeta
                                        .copyWith(fontSize: 11),
                                    textAlign: TextAlign.right,
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
                              dashArray: [4, 4],
                            ),
                          ],
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) =>
                                const Color(0xFFE5FFDE),
                            tooltipRoundedRadius: 8,
                            getTooltipItems: (touchedSpots) {
                              if (touchedSpots.isEmpty) return [];
                              final primarySpot = touchedSpots.first;
                              return touchedSpots.map((spot) {
                                if (spot == primarySpot) {
                                  return LineTooltipItem(
                                    spot.y.toStringAsFixed(2),
                                    AppTextStyles.cardMeta.copyWith(
                                      color: AppColors.textPrimary,
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
                                  AppColors.chartLine.withOpacity(0.22),
                                  AppColors.chartLine.withOpacity(0.0),
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
                                  AppColors.chartLine.withOpacity(0.10),
                                  AppColors.chartLine.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. X-Axis Time Labels
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
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: isMobile ? 15 : 18,
                color:
                    isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryButton : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterPills() {
    final options = [4, 8, 12];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((hours) {
        final isSelected = selectedHours == hours; // Fixed equality operator
        return GestureDetector(
          onTap: () => onHoursChanged(hours),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryButton
                  : const Color(0xFFE2E2E2),
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

class WidgetChildWrapper extends StatelessWidget {
  final bool isDesktop;
  final Widget child;

  const WidgetChildWrapper({
    super.key,
    required this.isDesktop,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Expanded(child: child);
    }
    return SizedBox(height: 380, child: child);
  }
}