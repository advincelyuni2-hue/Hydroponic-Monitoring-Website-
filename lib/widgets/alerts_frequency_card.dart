import 'card_info_tooltip.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class AlertFrequencyCard extends StatelessWidget {
  final List<AlertFrequencyData> alerts;
  final String dateRangeLabel;
  final bool horizontal;

  const AlertFrequencyCard({
    super.key,
    required this.alerts,
    this.horizontal = false,
    required this.dateRangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final totalAlerts = alerts.fold<int>(0, (total, alert) => total + alert.count);
    if (horizontal) return _buildHorizontal(totalAlerts);
    final hasData = alerts.any((a) => a.count > 0);
    final highestCount = hasData
        ? alerts.map((a) => a.count).reduce((a, b) => a > b ? a : b)
        : 0;
    final chartMaxY = (highestCount + 2).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardInfoTitle('Critical Alert Frequency', description: 'Shows the number of critical alerts for each monitored parameter over the displayed period.',
                        style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Last 30 days', style: AppTextStyles.cardMeta),
                    Text(dateRangeLabel,
                        style: AppTextStyles.cardMeta.copyWith(fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('$totalAlerts',
                      style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 22, color: AppColors.alertText)),
                  ),
                  Text('total alerts',
                      style: AppTextStyles.cardMeta.copyWith(fontSize: 10)),
                ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 172,
            child: hasData
                ? BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
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
                  )
                : Center(
                    child: Text(
                      'No alerts recorded',
                      style: AppTextStyles.cardMeta,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final alert in alerts)
                Expanded(
                  child: Text(alert.category + ' (' + alert.count.toString() + ')',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardMeta.copyWith(fontSize: 10)),
                ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildHorizontal(int totalAlerts) {
    final highest = alerts.fold<int>(0,
        (value, alert) => alert.count > value ? alert.count : value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardInfoTitle('Critical Alert Frequency', description: 'Shows the number of critical alerts for each monitored parameter over the displayed period.',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text('Last 30 days', style: AppTextStyles.cardMeta),
          Text(dateRangeLabel,
              style: AppTextStyles.cardMeta.copyWith(fontSize: 10)),
          const SizedBox(height: 8),
          Text('$totalAlerts', style: AppTextStyles.bodyBold.copyWith(
              fontSize: 22, color: AppColors.alertText)),
          Text('total alerts', style: AppTextStyles.cardMeta.copyWith(fontSize: 10)),
          const SizedBox(height: 14),
          for (final alert in alerts) ...[
            Row(children: [
              Expanded(child: Text(alert.category,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 12))),
              Text(alert.count.toString() + ' ? ' +
                  (totalAlerts == 0 ? '0' :
                      (alert.count * 100 / totalAlerts).toStringAsFixed(0)) + '%',
                  style: AppTextStyles.cardMeta.copyWith(fontSize: 11)),
            ]),
            const SizedBox(height: 6),
            Tooltip(
              message: alert.category + ': ' + alert.count.toString(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: highest == 0 ? 0 : alert.count / highest,
                  minHeight: 8,
                  color: AppColors.alertBorder,
                  backgroundColor: AppColors.alertBackground,
                ),
              ),
            ),
            if (alert != alerts.last) const SizedBox(height: 14),
          ],
          if (totalAlerts == 0) ...[
            const SizedBox(height: 12),
            Text('No alerts recorded', style: AppTextStyles.cardMeta),
          ],
        ],
      ),
    );
  }

}
