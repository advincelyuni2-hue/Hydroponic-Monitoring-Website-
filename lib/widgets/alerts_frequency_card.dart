import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/reports_models.dart';
import '../utils/responsive.dart';

class AlertFrequencyCard extends StatelessWidget {
  final List<AlertFrequencyData> alerts;
  final int fixedCount;
  final int activeCount;

  const AlertFrequencyCard({
    super.key,
    required this.alerts,
    required this.fixedCount,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = alerts.isNotEmpty;
    final highestCount = hasData ? alerts.map((a) => a.count).reduce((a, b) => a > b ? a : b) : 0;
    final chartMaxY = (highestCount + 2).toDouble();
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Alert frequency', style: AppTextStyles.sectionTitle, overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusCardGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$fixedCount Fixed',
                  style: AppTextStyles.cardMeta.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryButton),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 20),

          if (!hasData)
            SizedBox(height: 150, child: Center(child: Text('No alerts yet', style: AppTextStyles.cardMeta)))
          else if (isMobile)
            Column(
              children: [
                SizedBox(height: 150, child: _buildChart(chartMaxY)),
                const SizedBox(height: 16),
                _buildStatsColumn(),
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: SizedBox(height: 160, child: _buildChart(chartMaxY)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: _buildStatsColumn(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChart(double chartMaxY) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < alerts.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(alerts[idx].category, style: AppTextStyles.cardMeta.copyWith(fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: [
          for (int i = 0; i < alerts.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: alerts[i].count.toDouble(),
                  color: AppColors.alertBorder,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatsColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final alert in alerts) ...[
          _statRow(alert.category, alert.count),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.alertBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
              children: [
                const TextSpan(text: 'Active unresolved: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '$activeCount'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.calloutBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.alertBorder, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          Text('$count', style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}