import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/reports_models.dart';
import '../utils/responsive.dart';

class ReportPredictionCard extends StatelessWidget {
  final List<PredictedAnalyticsPoint> points;
  final String selectedParameter;
  final VoidCallback? onApplyRecommendation;
  final VoidCallback? onDismissRecommendation;

  const ReportPredictionCard({
    super.key,
    required this.points,
    required this.selectedParameter,
    this.onApplyRecommendation,
    this.onDismissRecommendation,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hasData = points.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visual analytics', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 2),
                    Text(
                      'Actual vs. Predicted ($selectedParameter)',
                      style: AppTextStyles.cardMeta,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.statusCardGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '95.8% Accuracy',
                  style: AppTextStyles.cardMeta.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryButton,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendItem('Actual Value', AppColors.primaryButton),
              const SizedBox(width: 16),
              _legendItem('Predicted Value', const Color(0xFFE67E22)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 20),
          SizedBox(
            height: isMobile ? 220 : 320,
            child: hasData
                ? LineChart(_buildChartData())
                : Center(
                    child: Text('No prediction data yet',
                        style: AppTextStyles.cardMeta),
                  ),
          ),
          if (onApplyRecommendation != null ||
              onDismissRecommendation != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (onApplyRecommendation != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApplyRecommendation,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Apply recommendation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (onApplyRecommendation != null &&
                    onDismissRecommendation != null)
                  const SizedBox(width: 12),
                if (onDismissRecommendation != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDismissRecommendation,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Dismiss'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.cardMeta.copyWith(fontSize: 12)),
      ],
    );
  }

  LineChartData _buildChartData() {
    final actualSpots = <FlSpot>[];
    final predictedSpots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      actualSpots.add(FlSpot(i.toDouble(), points[i].actualValue));
      predictedSpots.add(FlSpot(i.toDouble(), points[i].predictedValue));
    }

    return LineChartData(
      minX: 0,
      maxX: points.length > 1 ? (points.length - 1).toDouble() : 1,
      minY: 5.0,
      maxY: 7.5,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (val) => const FlLine(
          color: AppColors.chartGrid,
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(
          show: true, border: Border.all(color: AppColors.chartGrid)),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 0.5,
            getTitlesWidget: (val, meta) => Text(
              val.toStringAsFixed(1),
              style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx >= 0 && idx < points.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    points[idx].label,
                    style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1A1A1A),
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            final idx = touchedSpots.first.spotIndex;
            if (idx < 0 || idx >= points.length) return [];
            final pt = points[idx];
            return touchedSpots.map((spot) {
              if (spot.barIndex == 0) {
                return LineTooltipItem(
                  'Actual: ${pt.actualValue}\nPredicted: ${pt.predictedValue}\nDiff: \u00b1${pt.delta.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.3,
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
          spots: actualSpots,
          isCurved: true,
          color: AppColors.primaryButton,
          barWidth: 2.5,
          dotData: const FlDotData(show: true),
        ),
        LineChartBarData(
          spots: predictedSpots,
          isCurved: true,
          color: const Color(0xFFE67E22),
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }
}