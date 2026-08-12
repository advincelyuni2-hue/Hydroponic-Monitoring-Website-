import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/reports_models.dart';

class TargetDistributionCard extends StatelessWidget {
  final TargetDistributionData data;
  final String selectedParam;
  final ValueChanged<String> onParamChanged;

  const TargetDistributionCard({
    super.key,
    required this.data,
    required this.selectedParam,
    required this.onParamChanged,
  });

  @override
  Widget build(BuildContext context) {

    final total = data.optimalPercentage + data.warningPercentage + data.criticalPercentage;
    final hasData = total > 0;

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
                child: Text(
                  'Target Distribution',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildParamPill(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: hasData
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: data.optimalPercentage,
                          color: AppColors.primaryButton,
                          title: '${data.optimalPercentage.toInt()}%',
                          radius: 30,
                          titleStyle: AppTextStyles.cardMeta.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: data.warningPercentage,
                          color: const Color(0xFFF39C12),
                          title: '${data.warningPercentage.toInt()}%',
                          radius: 30,
                          titleStyle: AppTextStyles.cardMeta.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: data.criticalPercentage,
                          color: AppColors.alertBorder,
                          title: '${data.criticalPercentage.toInt()}%',
                          radius: 30,
                          titleStyle: AppTextStyles.cardMeta.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(child: Text('No data yet', style: AppTextStyles.cardMeta)),
          ),
          const SizedBox(height: 16),
          _legendRow('Optimal (In Target)', AppColors.primaryButton,
              '${data.optimalPercentage.toInt()}%'),
          const SizedBox(height: 6),
          _legendRow('Warning Zone', const Color(0xFFF39C12),
              '${data.warningPercentage.toInt()}%'),
          const SizedBox(height: 6),
          _legendRow('Critical Bounds', AppColors.alertBorder,
              '${data.criticalPercentage.toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildParamPill() {
    final options = ['pH', 'EC', 'Air'];
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((p) {
          final isSelected = selectedParam == p;
          return GestureDetector(
            onTap: () => onParamChanged(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryButton : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _legendRow(String label, Color color, String percent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.cardMeta.copyWith(fontSize: 12)),
          ],
        ),
        Text(percent, style: AppTextStyles.bodyBold.copyWith(fontSize: 12)),
      ],
    );
  }
}