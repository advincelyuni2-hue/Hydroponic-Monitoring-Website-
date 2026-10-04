<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/reports_models.dart';

class AlertFrequencyCard extends StatelessWidget {
  final List<AlertFrequencyData> alerts;
  final int fixedCount;
=======
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class AlertFrequencyCard extends StatelessWidget {
  final List<AlertFrequencyData> alerts;
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  final int activeCount;

  const AlertFrequencyCard({
    super.key,
    required this.alerts,
<<<<<<< HEAD
    required this.fixedCount,
=======
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = alerts.isNotEmpty;
    final highestCount = hasData
        ? alerts.map((a) => a.count).reduce((a, b) => a > b ? a : b)
        : 0;
    final chartMaxY = (highestCount + 2).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Alert Frequency',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusCardGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$fixedCount Fixed',
                  style: AppTextStyles.cardMeta.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryButton,
                  ),
                ),
              ),
            ],
=======
          Text(
            'Critical Alert Frequency',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
            overflow: TextOverflow.ellipsis,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: hasData
                ? BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      titlesData: FlTitlesData(
<<<<<<< HEAD
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
=======
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
                              final idx = val.toInt();
                              if (idx >= 0 && idx < alerts.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    alerts[idx].category,
<<<<<<< HEAD
                                    style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
=======
                                    style: AppTextStyles.cardMeta
                                        .copyWith(fontSize: 10),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
                                  ),
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
                  )
<<<<<<< HEAD
                : Center(child: Text('No alerts yet', style: AppTextStyles.cardMeta)),
=======
                : Center(
                    child: Text(
                      'No alerts recorded',
                      style: AppTextStyles.cardMeta,
                    ),
                  ),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
          ),
          const SizedBox(height: 12),
          Text(
            'Total active unresolved: $activeCount',
            style: AppTextStyles.cardMeta.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.alertText,
            ),
          ),
        ],
      ),
    );
  }
}