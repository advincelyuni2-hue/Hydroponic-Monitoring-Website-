import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/reports_models.dart';
import '../utils/responsive.dart';
import 'date_picker_button.dart';

class ReportsAnalyticsCard extends StatelessWidget {
  final String selectedParameter;
  final String selectedTimeframe;
  final List<AnalyticsPoint> points;
  final double minThreshold;
  final double maxThreshold;
  final ValueChanged<String> onParameterChanged;
  final ValueChanged<String> onTimeframeChanged;
  final VoidCallback? onDatePickerTap;

  const ReportsAnalyticsCard({
    super.key,
    required this.selectedParameter,
    required this.selectedTimeframe,
    required this.points,
    required this.minThreshold,
    required this.maxThreshold,
    required this.onParameterChanged,
    required this.onTimeframeChanged,
    this.onDatePickerTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTitleSection(),
                        _buildParameterTogglePill(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTimeframeFilterPills(context),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        _buildTitleSection(),
                        const SizedBox(width: 16),
                        _buildParameterTogglePill(),
                      ],
                    ),
                    _buildTimeframeFilterPills(context),
                  ],
                ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
          const SizedBox(height: 24),
          SizedBox(
            height: isMobile ? 240 : 340,
            child: LineChart(_buildTrendChartData()),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visual analytics', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 2),
        Text(
          '$selectedParameter trend, last 30 days',
          style: AppTextStyles.cardMeta,
        ),
      ],
    );
  }

  Widget _buildParameterTogglePill() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleOption('pH'),
          _toggleOption('EC'),
        ],
      ),
    );
  }

  Widget _toggleOption(String label) {
    final isSelected = selectedParameter == label;
    return GestureDetector(
      onTap: () => onParameterChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryButton : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeFilterPills(BuildContext context) {
    final options = ['7d', '30d', '90d'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tf in options) ...[
          GestureDetector(
            onTap: () => onTimeframeChanged(tf),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: selectedTimeframe == tf
                    ? AppColors.primaryButton
                    : const Color(0xFFE2E2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tf,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: selectedTimeframe == tf ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        DatePickerButton(
          onTap: onDatePickerTap ??
              () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Date picker coming soon')),
                  ),
        ),
      ],
    );
  }

  LineChartData _buildTrendChartData() {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value));
    }

    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 5.0,
      maxY: 7.5,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: AppColors.chartGrid,
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppColors.chartGrid),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 0.5,
            getTitlesWidget: (val, meta) {
              return Text(
                val.toStringAsFixed(1),
                style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (val, meta) {
              final index = val.toInt();
              if (index >= 0 && index < points.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    points[index].label,
                    style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: maxThreshold,
            color: const Color(0xFFC0392B),
            strokeWidth: 1.2,
            dashArray: [5, 5],
          ),
          HorizontalLine(
            y: minThreshold,
            color: const Color(0xFFC0392B),
            strokeWidth: 1.2,
            dashArray: [5, 5],
          ),
        ],
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFFE5FFDE),
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
          spots: spots,
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
      ],
    );
  }
}