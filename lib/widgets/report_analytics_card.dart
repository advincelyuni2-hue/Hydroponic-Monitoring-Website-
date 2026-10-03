import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

class ReportsAnalyticsCard extends StatefulWidget {
  final String selectedParameter;
  final String selectedTimeframe;
  final List<AnalyticsPoint> points;
  final double minThreshold;
  final double maxThreshold;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onParameterChanged;
  final ValueChanged<String> onTimeframeChanged;

  const ReportsAnalyticsCard({
    super.key,
    required this.selectedParameter,
    required this.selectedTimeframe,
    required this.points,
    required this.minThreshold,
    required this.maxThreshold,
    this.isLoading = false,
    this.errorMessage,
    required this.onParameterChanged,
    required this.onTimeframeChanged,
  });

  @override
  State<ReportsAnalyticsCard> createState() => ReportsAnalyticsCardState();
}

class ReportsAnalyticsCardState extends State<ReportsAnalyticsCard> {
  static const phColor = AppColors.primaryButton;
  static const ecColor = Color(0xFF1599A8);

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
            'Historical sensor trends and parameter telemetry',
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
                    : widget.points.isEmpty
                        ? Center(
                            child: Text(
                              'No sensor readings available for this period.',
                              style: AppTextStyles.cardMeta,
                            ),
                          )
                        : LineChart(_buildTrendChartData(isMobile)),
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
        const Icon(Icons.show_chart, color: AppColors.primaryButton),
        Text('Historical Telemetry Trends', style: AppTextStyles.sectionTitle),
      ],
    );

    final controls = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _selector<String>(
          values: const ['pH', 'EC'],
          selected: widget.selectedParameter,
          label: (val) => val,
          onSelected: widget.onParameterChanged,
        ),
        _selector<String>(
          values: const ['7d', '30d', '90d'],
          selected: widget.selectedTimeframe,
          label: (val) => val,
          onSelected: widget.onTimeframeChanged,
        ),
      ],
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
    final currentColor =
        widget.selectedParameter == 'pH' ? phColor : ecColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: currentColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${widget.selectedParameter} measured values',
          style: AppTextStyles.cardMeta,
        ),
      ],
    );
  }

  LineChartData _buildTrendChartData(bool isMobile) {
    final spots = <FlSpot>[];
    for (int i = 0; i < widget.points.length; i++) {
      spots.add(FlSpot(i.toDouble(), widget.points[i].value));
    }

    final currentColor =
        widget.selectedParameter == 'pH' ? phColor : ecColor;
    final values = widget.points.map((point) => point.value).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    minY = minY < widget.minThreshold ? minY : widget.minThreshold;
    maxY = maxY > widget.maxThreshold ? maxY : widget.maxThreshold;
    final span = maxY - minY;
    final padding = span == 0 ? (maxY.abs() * 0.1).clamp(0.1, 1.0) : span * 0.12;
    minY -= padding;
    maxY += padding;
    final interval = (maxY - minY) / 5;
    final titleInterval = (widget.points.length / 6).ceil().clamp(1, 1000);

    return LineChartData(
      minX: 0,
      maxX: (widget.points.length - 1).clamp(1, 100000).toDouble(),
      minY: minY,
      maxY: maxY,
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
            interval: interval,
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
            interval: interval,
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
            interval: titleInterval.toDouble(),
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
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: widget.maxThreshold,
            color: AppColors.alertBorder,
            strokeWidth: 1.2,
            dashArray: [5, 5],
          ),
          HorizontalLine(
            y: widget.minThreshold,
            color: AppColors.alertBorder,
            strokeWidth: 1.2,
            dashArray: [5, 5],
          ),
        ],
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.cardBackground,
          tooltipRoundedRadius: 8,
          getTooltipItems: (spots) => spots.map((spot) {
            final unit = widget.selectedParameter == 'pH' ? '' : ' mS/cm';
            return LineTooltipItem(
              '${widget.selectedParameter} ${spot.y.toStringAsFixed(2)}$unit',
              AppTextStyles.bodyBold.copyWith(color: currentColor),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: currentColor,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: currentColor.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}