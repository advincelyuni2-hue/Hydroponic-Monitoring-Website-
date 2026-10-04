import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

class ReportPredictionCard extends StatelessWidget {
  final ModelEvaluation evaluation;
  final String selectedParameter; // 'Both', 'pH' or 'EC'
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onParameterChanged;

  const ReportPredictionCard({
    super.key,
    required this.evaluation,
    required this.selectedParameter,
    required this.isLoading,
    required this.errorMessage,
    required this.onParameterChanged,
  });

  static Color get _phColor => AppColors.accentGreen;
  static Color get _ecColor => AppColors.accentTeal;

  bool get _showPh => selectedParameter != 'EC';
  bool get _showEc => selectedParameter != 'pH';

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 5),
          Text(
            'Compares what ${evaluation.modelName} predicted '
            '${evaluation.horizonHours} hours ahead with what the sensors '
            'actually measured. Dashed lines are predictions.',
            style: AppTextStyles.cardMeta,
          ),
          SizedBox(height: isMobile ? 16 : 22),
          SizedBox(
            height: isMobile ? 230 : 350,
            child: _buildBody(isMobile),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Comparing model predictions with sensor readings...',
              style: AppTextStyles.cardMeta,
            ),
          ],
        ),
      );
    }
    if (evaluation.samples.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            errorMessage ?? 'No model predictions are available yet.',
            textAlign: TextAlign.center,
            style: AppTextStyles.cardMeta,
          ),
        ),
      );
    }
    return _buildChart(isMobile);
  }

  Widget _buildHeader(bool isMobile) {
    final accuracy = evaluation.accuracyFor(selectedParameter);
    final title = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.show_chart, color: AppColors.accentGreen),
        Text('Forecast Model Evaluation', style: AppTextStyles.sectionTitle),
        if (accuracy != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusCardGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${accuracy.toStringAsFixed(1)}% accuracy',
              style: AppTextStyles.cardMeta.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.accentGreen,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
    final controls = _selector(
      const ['Both', 'pH', 'EC'],
      selectedParameter,
      onParameterChanged,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 12), controls],
      );
    }
    return Row(children: [Expanded(child: title), controls]);
  }

  Widget _selector(
    List<String> values,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.calloutBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in values)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: selected == value
                      ? AppColors.primaryButton
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: AppTextStyles.cardMeta.copyWith(
                    color: selected == value
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_Series> _series() {
    final samples = evaluation.samples;
    List<FlSpot> spots(double? Function(EvaluationSample) pick) => [
          for (var i = 0; i < samples.length; i++)
            if (pick(samples[i]) != null)
              FlSpot(i.toDouble(), pick(samples[i])!),
        ];

    final list = <_Series>[
      if (_showPh) ...[
        _Series('pH measured', _phColor, false, spots((s) => s.phActual)),
        _Series('pH predicted', _phColor, true, spots((s) => s.phPredicted)),
      ],
      if (_showEc) ...[
        _Series('EC measured', _ecColor, false, spots((s) => s.ecActual)),
        _Series('EC predicted', _ecColor, true, spots((s) => s.ecPredicted)),
      ],
    ];
    return list.where((s) => s.spots.isNotEmpty).toList();
  }

  Widget _buildChart(bool isMobile) {
    final samples = evaluation.samples;
    final series = _series();
    if (series.isEmpty) {
      return Center(
        child: Text('No readings for this selection.',
            style: AppTextStyles.cardMeta),
      );
    }

    var maxValue = 0.0;
    for (final s in series) {
      for (final spot in s.spots) {
        maxValue = math.max(maxValue, spot.y);
      }
    }
    final maxY = math.max(1.0, ((maxValue * 1.15) / 0.5).ceilToDouble() * 0.5);
    final labelInterval =
        math.max(1, (samples.length / (isMobile ? 3 : 4)).ceil());

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(samples.length - 1, 1).toDouble(),
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.chartGrid.withValues(alpha: 0.65),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: AppColors.chartGrid.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.chartGrid),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isMobile ? 33 : 42,
              interval: maxY / 4,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(1),
                style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: labelInterval.toDouble(),
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 ||
                    index >= samples.length ||
                    (value - index).abs() > 0.001 ||
                    index % labelInterval != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    samples[index].label,
                    style: AppTextStyles.cardMeta.copyWith(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.cardBackground,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touched) => [
              for (var i = 0; i < touched.length; i++)
                LineTooltipItem(
                  '${i == 0 ? '${samples[touched[i].x.toInt()].label}\n' : ''}'
                  '${series[touched[i].barIndex].name}: '
                  '${touched[i].y.toStringAsFixed(2)}'
                  '${series[touched[i].barIndex].name.startsWith('EC') ? ' mS/cm' : ''}',
                  AppTextStyles.bodyBold.copyWith(
                    color: series[touched[i].barIndex].color,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          for (final s in series)
            LineChartBarData(
              spots: s.spots,
              isCurved: false,
              color: s.color,
              barWidth: 2.5,
              dashArray: s.predicted ? [6, 4] : null,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: s.color,
                  strokeWidth: 1.5,
                  strokeColor: AppColors.cardBackground,
                ),
              ),
              belowBarData: BarAreaData(
                show: !s.predicted,
                color: s.color.withValues(alpha: 0.08),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final items = _series();
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        for (final s in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.predicted)
                Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      Container(width: 4, height: 3, color: s.color),
                      if (i < 2) const SizedBox(width: 2),
                    ],
                  ],
                )
              else
                Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 6),
              Text(s.name, style: AppTextStyles.cardMeta),
            ],
          ),
      ],
    );
  }
}

class _Series {
  final String name;
  final Color color;
  final bool predicted;
  final List<FlSpot> spots;
  const _Series(this.name, this.color, this.predicted, this.spots);
}