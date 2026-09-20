import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/reports_models.dart';
import '../utils/responsive.dart';

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
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Target distribution',
                  style: AppTextStyles.sectionTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildParamPill(),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 20),

          if (!hasData)
            SizedBox(
              height: 150,
              child: Center(
                child: Text('No data yet', style: AppTextStyles.cardMeta),
              ),
            )
          else if (isMobile)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 160, child: _buildChart()),
                const SizedBox(height: 16),
                _buildLegendList(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(height: 170, child: _buildChart()),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 5,
                  child: _buildLegendList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return PieChart(
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
    );
  }

  Widget _buildLegendList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _legendRow('Optimal (in target)', AppColors.primaryButton, '${data.optimalPercentage.toInt()}%'),
        const SizedBox(height: 12),
        _legendRow('Warning zone', const Color(0xFFF39C12), '${data.warningPercentage.toInt()}%'),
        const SizedBox(height: 12),
        _legendRow('Critical bounds', AppColors.alertBorder, '${data.criticalPercentage.toInt()}%'),
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.calloutBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Using Flexible instead of Expanded inside nested Row prevents unbounded crashes
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(percent, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}