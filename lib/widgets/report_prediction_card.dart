import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

class ReportPredictionCard extends StatelessWidget {
  final List<AnalyticsPoint> phPoints;
  final List<AnalyticsPoint> ecPoints;
  final String selectedParameter;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onParameterChanged;
  final String? accuracyText;

  const ReportPredictionCard({
    super.key,
    required this.phPoints,
    required this.ecPoints,
    required this.selectedParameter,
    required this.isLoading,
    required this.errorMessage,
    required this.onParameterChanged,
    this.accuracyText,
  });

  static Color get _phColor => AppColors.accentGreen;
  static Color get _ecColor => AppColors.accentTeal;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final noData = selectedParameter == 'Both'
        ? phPoints.isEmpty && ecPoints.isEmpty
        : selectedParameter == 'pH'
            ? phPoints.isEmpty
            : ecPoints.isEmpty;

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
            'Recorded sensor readings from Supabase. Historical model '
            'predictions are not currently stored for comparison.',
            style: AppTextStyles.cardMeta,
          ),
          SizedBox(height: isMobile ? 16 : 22),
          SizedBox(
            height: isMobile ? 230 : 350,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.cardMeta,
                        ),
                      )
                    : noData
                        ? Center(
                            child: Text(
                              'No readings available for this selection.',
                              style: AppTextStyles.cardMeta,
                            ),
                          )
                        : selectedParameter == 'Both'
                            ? Column(
                                children: [
                                  Expanded(
                                    child: _seriesChart(
                                      phPoints,
                                      'pH',
                                      _phColor,
                                      isMobile,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: _seriesChart(
                                      ecPoints,
                                      'EC',
                                      _ecColor,
                                      isMobile,
                                    ),
                                  ),
                                ],
                              )
                            : _seriesChart(
                                selectedParameter == 'pH'
                                    ? phPoints
                                    : ecPoints,
                                selectedParameter,
                                selectedParameter == 'pH'
                                    ? _phColor
                                    : _ecColor,
                                isMobile,
                              ),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final title = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.show_chart, color: AppColors.accentGreen),
        Text('Forecast Model Evaluation', style: AppTextStyles.sectionTitle),
        if (accuracyText != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusCardGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              accuracyText!,
              style: AppTextStyles.cardMeta.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.accentGreen,
                fontSize: 11,
              ),
            ),
          ),
        ],
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
    return Row(
      children: [
        Expanded(child: title),
        controls,
      ],
    );
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

  Widget _seriesChart(
    List<AnalyticsPoint> points,
    String parameter,
    Color color,
    bool isMobile,
  ) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No $parameter readings available for this period.',
          style: AppTextStyles.cardMeta,
        ),
      );
    }

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    final values = points.map((point) => point.value);
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    final span = maxY - minY;
    final padding = span == 0 ? math.max(maxY.abs() * 0.1, 0.1) : span * 0.15;
    minY = math.max(0, minY - padding);
    maxY += padding;
    if (maxY <= minY) maxY = minY + 0.5;
    final interval = math.max((maxY - minY) / 4, 0.1);
    final labelInterval = math.max(1, (points.length / 5).ceil());

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(points.length - 1, 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: true),
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
            axisNameWidget: Text(
              parameter == 'EC' ? 'mS/cm' : 'pH',
              style: AppTextStyles.cardMeta,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isMobile ? 38 : 48,
              interval: interval,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(1),
                style: AppTextStyles.cardMeta.copyWith(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: labelInterval.toDouble(),
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[index].label,
                    style: AppTextStyles.cardMeta.copyWith(fontSize: 8),
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
            getTooltipItems: (items) => items
                .map(
                  (spot) => LineTooltipItem(
                    '${spot.y.toStringAsFixed(2)}'
                    '${parameter == 'EC' ? ' mS/cm' : ''}',
                    AppTextStyles.bodyBold.copyWith(color: color),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final items = selectedParameter == 'Both'
        ? [('pH measured values', _phColor), ('EC measured values', _ecColor)]
        : [
            (
              '$selectedParameter measured values',
              selectedParameter == 'pH' ? _phColor : _ecColor,
            ),
          ];
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 3,
                decoration: BoxDecoration(
                  color: item.$2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(item.$1, style: AppTextStyles.cardMeta),
            ],
          ),
      ],
    );
  }
}
