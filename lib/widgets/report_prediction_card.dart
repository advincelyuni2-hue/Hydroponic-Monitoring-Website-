import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

class ReportPredictionCard extends StatefulWidget {
  final List<PredictedAnalyticsPoint> points;
  final List<AnalyticsPoint> phPoints;
  final List<AnalyticsPoint> ecPoints;
  final String selectedParameter;
  final String? accuracyText;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String>? onParameterChanged;

  const ReportPredictionCard({
    super.key,
    this.points = const [],
    this.phPoints = const [],
    this.ecPoints = const [],
    required this.selectedParameter,
    this.accuracyText,
    this.isLoading = false,
    this.errorMessage,
    this.onParameterChanged,
  });

  @override
  State<ReportPredictionCard> createState() => ReportPredictionCardState();
}

class ReportPredictionCardState extends State<ReportPredictionCard> {
  late String _activeParam;
  static const phColor = AppColors.primaryButton;

  @override
  void initState() {
    super.initState();
    _activeParam = widget.selectedParameter;
  }

  @override
  void didUpdateWidget(covariant ReportPredictionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedParameter != widget.selectedParameter) {
      _activeParam = widget.selectedParameter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hasHistoricalData = _activeParam == 'Both'
        ? widget.phPoints.isNotEmpty || widget.ecPoints.isNotEmpty
        : _activeParam == 'pH'
            ? widget.phPoints.isNotEmpty
            : widget.ecPoints.isNotEmpty;
    final hasNoData = widget.points.isEmpty && !hasHistoricalData;
    final usesHistoricalData = widget.points.isEmpty && hasHistoricalData;

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
            usesHistoricalData
                ? 'Recorded sensor readings from Supabase.'
                : 'Actual vs. Machine Learning predicted trajectory',
            style: AppTextStyles.cardMeta,
          ),
          SizedBox(height: isMobile ? 16 : 22),
          SizedBox(
            height: isMobile ? 230 : 350,
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.errorMessage != null
                    ? Center(
                        child: Text(
                          widget.errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.cardMeta,
                        ),
                      )
                    : hasNoData
                        ? Center(
                            child: Text(
                              'No readings available for this selection.',
                              style: AppTextStyles.cardMeta,
                            ),
                          )
                        : usesHistoricalData
                            ? _buildHistoricalCharts(isMobile)
                            : LineChart(_buildChartData(isMobile)),
          ),
          const SizedBox(height: 12),
          usesHistoricalData ? _buildHistoricalLegend() : _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHistoricalCharts(bool isMobile) {
    final phAvailable = widget.phPoints.isNotEmpty;
    final ecAvailable = widget.ecPoints.isNotEmpty;
    if (_activeParam == 'Both' && phAvailable && ecAvailable) {
      return Column(
        children: [
          Expanded(
            child: _historicalChart(widget.phPoints, 'pH', phColor, isMobile),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _historicalChart(
              widget.ecPoints,
              'EC',
              const Color(0xFF1599A8),
              isMobile,
            ),
          ),
        ],
      );
    }
    final usePh = _activeParam == 'pH' || !ecAvailable;
    final points = usePh ? widget.phPoints : widget.ecPoints;
    final label = usePh ? 'pH' : 'EC';
    final color = usePh ? phColor : const Color(0xFF1599A8);
    return _historicalChart(points, label, color, isMobile);
  }

  Widget _historicalChart(
    List<AnalyticsPoint> points,
    String label,
    Color color,
    bool isMobile,
  ) {
    final values = points.map((point) => point.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final padding = math.max((maxValue - minValue) * 0.15, 0.1);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: points.length > 1 ? (points.length - 1).toDouble() : 1,
        minY: minValue - padding,
        maxY: maxValue + padding,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.chartGrid.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.chartGrid),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: Text(label, style: AppTextStyles.cardMeta),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isMobile ? 38 : 46,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(1),
                style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    points[index].label,
                    style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var index = 0; index < points.length; index++)
                FlSpot(index.toDouble(), points[index].value),
            ],
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalLegend() {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        if (widget.phPoints.isNotEmpty)
          _legendItem('pH history', phColor, isDashed: false),
        if (widget.ecPoints.isNotEmpty)
          _legendItem('EC history', const Color(0xFF1599A8), isDashed: false),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    final title = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(Icons.show_chart, color: AppColors.primaryButton),
        Text('Forecast Model Evaluation', style: AppTextStyles.sectionTitle),
        if (widget.accuracyText != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusCardGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.accuracyText!,
              style: AppTextStyles.cardMeta.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryButton,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );

    final controls = _selector<String>(
      values: const ['Both', 'pH', 'EC'],
      selected: _activeParam,
      label: (value) => value,
      onSelected: (value) {
        setState(() => _activeParam = value);
        widget.onParameterChanged?.call(value);
      },
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

  Widget _selector<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected == value
                      ? AppColors.primaryButton
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label(value),
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

  Widget _buildLegend() {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        _legendItem('Actual Value', AppColors.primaryButton, isDashed: false),
        _legendItem('Predicted Value', const Color(0xFFD97706), isDashed: true),
      ],
    );
  }

  Widget _legendItem(String label, Color color, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.cardMeta),
      ],
    );
  }

  LineChartData _buildChartData(bool isMobile) {
    final actualSpots = <FlSpot>[];
    final predictedSpots = <FlSpot>[];

    for (int i = 0; i < widget.points.length; i++) {
      actualSpots.add(FlSpot(i.toDouble(), widget.points[i].actualValue));
      predictedSpots.add(
          FlSpot(i.toDouble(), widget.points[i].predictedValue));
    }

    return LineChartData(
      minX: 0,
      maxX: widget.points.isNotEmpty
          ? (widget.points.length - 1).toDouble()
          : 5,
      minY: 5.0,
      maxY: 7.5,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(
          axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: isMobile ? 33 : 42,
            interval: 0.5,
            getTitlesWidget: (val, _) => Text(
              val.toStringAsFixed(1),
              style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
            ),
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: isMobile ? 33 : 42,
            interval: 0.5,
            getTitlesWidget: (val, _) => Text(
              val.toStringAsFixed(1),
              style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (val, _) {
              final idx = val.toInt();
              if (idx >= 0 && idx < widget.points.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.points[idx].label,
                    style: AppTextStyles.cardMeta.copyWith(
                      fontSize: isMobile ? 10 : null,
                    ),
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
          getTooltipColor: (_) => AppColors.cardBackground,
          tooltipRoundedRadius: 8,
          getTooltipItems: (spots) => spots.map((spot) {
            final isActual = spot.barIndex == 0;
            final label = isActual ? 'Actual' : 'Predicted';
            final color = isActual ? phColor : const Color(0xFFD97706);

            return LineTooltipItem(
              '$label ${spot.y.toStringAsFixed(2)}',
              AppTextStyles.bodyBold.copyWith(color: color),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: actualSpots,
          isCurved: true,
          color: phColor,
          barWidth: 2.5,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: phColor.withValues(alpha: 0.10),
          ),
        ),
        LineChartBarData(
          spots: predictedSpots,
          isCurved: true,
          color: const Color(0xFFD97706),
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFFD97706).withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}