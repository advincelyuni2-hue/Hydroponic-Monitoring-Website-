import 'card_info_tooltip.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../utils/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class TargetDistributionCard extends StatelessWidget {
  final TargetDistributionData data;
  final bool legendBelow;
  final String selectedParam;
  final bool isLoading;
  final String? errorMessage;
  final String dateRangeLabel;
  final ValueChanged<String> onParamChanged;

  const TargetDistributionCard({
    super.key,
    required this.data,
    this.legendBelow = false,
    required this.selectedParam,
    this.isLoading = false,
    this.errorMessage,
    required this.dateRangeLabel,
    required this.onParamChanged,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.optimalPercentage +
        data.warningPercentage +
        data.criticalPercentage;
    final hasData = total > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Keep the parameter control beside the report heading.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: CardInfoTitle('Frequency Distribution', description: 'Shows the proportions of readings in optimal, warning, and critical ranges for the selected parameter.',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              _buildParamPill(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Last 30 days',
            style: AppTextStyles.cardMeta,
          ),
          const SizedBox(height: 2),
          Text(
            dateRangeLabel,
            style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final sideBySide = !legendBelow &&
                constraints.maxWidth >= (Responsive.isDesktop(context) ? 280 : 360) &&
                MediaQuery.textScalerOf(context).scale(12) <= 16;
            final chart = SizedBox(
              height: legendBelow ? 144 : 160,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
                          child: Text(
                            'Unable to load distribution data.',
                            style: AppTextStyles.cardMeta,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : hasData
                          ? PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 38,
                                sections: [
                                  PieChartSectionData(
                                    value: data.optimalPercentage,
                                    color: AppColors.primaryButton,
                                    title: '${data.optimalPercentage.toInt()}%',
                                    radius: 28,
                                    titleStyle: AppTextStyles.cardMeta.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: data.warningPercentage,
                                    color: const Color(0xFFF39C12),
                                    title: '${data.warningPercentage.toInt()}%',
                                    radius: 28,
                                    titleStyle: AppTextStyles.cardMeta.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: data.criticalPercentage,
                                    color: AppColors.alertBorder,
                                    title: '${data.criticalPercentage.toInt()}%',
                                    radius: 28,
                                    titleStyle: AppTextStyles.cardMeta.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: Text(
                                'No data available',
                                style: AppTextStyles.cardMeta,
                              ),
                            ),
            );
            final legend = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _legendRow(
                  'Optimal (In Target)',
                  AppColors.primaryButton,
                  _percentageLabel(data.optimalPercentage),
                ),
                const SizedBox(height: 6),
                _legendRow(
                  'Warning Zone',
                  const Color(0xFFF39C12),
                  _percentageLabel(data.warningPercentage),
                ),
                const SizedBox(height: 6),
                _legendRow(
                  'Critical Bounds',
                  AppColors.alertBorder,
                  _percentageLabel(data.criticalPercentage),
                ),
              ],
            );
            if (sideBySide) {
              return SizedBox(
                height: 184,
                child: Row(children: [
                  SizedBox(width: 136, child: chart),
                  const SizedBox(width: 12),
                  Expanded(child: legend),
                ]),
              );
            }
            return Column(children: [
              chart,
              const SizedBox(height: 12),
              legend,
            ]);
          }),
        ],
      ),
    );
  }

  String _percentageLabel(double value) {
    if (isLoading || errorMessage != null) return '—';
    return '${value.toInt()}%';
  }

  Widget _buildParamPill() {
    final options = ['pH', 'EC', 'Temp'];
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
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primaryButton : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 10,
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
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: AppTextStyles.cardMeta.copyWith(fontSize: 11)),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 32,
          child: Text(percent, textAlign: TextAlign.right,
              style: AppTextStyles.bodyBold.copyWith(fontSize: 12)),
        ),
      ],
    );
  }
}
