import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/manila_time.dart';
import '../utils/responsive.dart';

class ForecastingChartCard extends StatefulWidget {
  final String activeTab; // 'pH', 'EC', or 'Both'
  final ValueChanged<String> onTabChanged;
  final int selectedHours; // 4, 8, or 12
  final ValueChanged<int> onHoursChanged;
  final List<ForecastPoint> points;
  final List<ForecastPoint>? ecPoints;
  final DateTime? generatedAt;

  const ForecastingChartCard({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.selectedHours,
    required this.onHoursChanged,
    required this.points,
    this.ecPoints,
    this.generatedAt,
  });

  @override
  State<ForecastingChartCard> createState() => ForecastingChartCardState();
}

class ForecastingChartCardState extends State<ForecastingChartCard> {
  static const phHistoricalColor = AppColors.primaryButton;
  static const ecHistoricalColor = Color(0xFF1599A8);
  static const predictedColor = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    final showPh = widget.activeTab == 'pH' || widget.activeTab == 'Both';
    final showEc = widget.activeTab == 'EC' || widget.activeTab == 'Both';

    // Extract pH and EC points from real model streams
    final allFiltered = _filterPoints(widget.points);
    final ecFiltered = _filterPoints(widget.ecPoints ?? []);

    // If activeTab == 'Both' and ecPoints was omitted, extract EC spots vs pH spots by value range
    final phFiltered = (widget.activeTab == 'Both' && ecFiltered.isEmpty)
        ? allFiltered.where((p) => p.value > 3.0).toList()
        : (showPh ? allFiltered : <ForecastPoint>[]);

    final ecPointsResolved = (widget.activeTab == 'Both' && ecFiltered.isEmpty)
        ? allFiltered.where((p) => p.value <= 3.0).toList()
        : (showEc ? (ecFiltered.isNotEmpty ? ecFiltered : allFiltered) : <ForecastPoint>[]);

    final phRange = _computeRange(phFiltered, defaultMin: 5.0, defaultMax: 10.0);
    final ecRange = _computeRange(ecPointsResolved, defaultMin: 0.0, defaultMax: 3.0);

    late _ChartRange chartRange;
    if (widget.activeTab == 'EC') {
      chartRange = ecRange;
    } else if (widget.activeTab == 'pH') {
      chartRange = phRange;
    } else {
      chartRange = const _ChartRange(0.0, 15.0);
    }

    final currentLabel = _getReadingLabel(
      phFiltered,
      ecPointsResolved,
      showPh,
      showEc,
      predicted: false,
    );
    final forecastLabel = _getReadingLabel(
      phFiltered,
      ecPointsResolved,
      showPh,
      showEc,
      predicted: true,
    );

    return Container(
      width: double.infinity,
      height: isDesktop ? 689 : null,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isDesktop ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 6),
          Text(
            'Real-time sensor tracking vs. machine-learning forecast trajectory',
            style: AppTextStyles.cardMeta,
          ),
          SizedBox(height: isMobile ? 12 : 16),

          // Scrollable Chart Viewport
          Expanded(
            flex: isDesktop ? 1 : 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height: widget.activeTab == 'Both' ? 750 : (isDesktop ? 500 : 320),
                      width: double.infinity,
                      child: LineChart(
                        _buildChartData(
                          chartRange,
                          isMobile,
                          phFiltered,
                          ecPointsResolved,
                          showPh,
                          showEc,
                        ),
                      ),
                    ),
                  ),
                  _buildCalloutBadge(isMobile, currentLabel, forecastLabel),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          _buildLegendAndDate(isMobile),
        ],
      ),
    );
  }

  Widget _buildCalloutBadge(
      bool isMobile, String currentLabel, String forecastLabel) {
    return Positioned(
      top: 8,
      left: isMobile ? 35 : 50,
      right: isMobile ? 35 : 50,
      child: IgnorePointer(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.cardMeta.copyWith(
                fontSize: isMobile ? 9 : 11,
              ),
              children: [
                const TextSpan(text: 'Current '),
                TextSpan(
                  text: currentLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '  Forecast '),
                TextSpan(
                  text: forecastLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: predictedColor,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData(
    _ChartRange chartRange,
    bool isMobile,
    List<ForecastPoint> phFiltered,
    List<ForecastPoint> ecFiltered,
    bool showPh,
    bool showEc,
  ) {
    return LineChartData(
      minX: -widget.selectedHours.toDouble(),
      maxX: widget.selectedHours.toDouble(),
      minY: chartRange.minimum,
      maxY: chartRange.maximum,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.chartGrid.withOpacity(0.65),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (_) => FlLine(
          color: AppColors.chartGrid.withOpacity(0.35),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppColors.chartGrid),
      ),
      titlesData: _buildTitlesData(chartRange, isMobile),
      extraLinesData: ExtraLinesData(
        verticalLines: [
          VerticalLine(
            x: 0,
            color: AppColors.textSecondary,
            strokeWidth: 1,
            dashArray: [5, 4],
          ),
        ],
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.cardBackground,
          tooltipRoundedRadius: 8,
          getTooltipItems: (spots) => spots.map((spot) {
            final isConnector = spot.x <= 0 && spot.barIndex.isOdd;
            if (isConnector) return null;

            final isPh = spot.y > 3.0;
            final label = isPh ? 'pH' : 'EC';
            final isPredicted = spot.barIndex.isOdd;
            final color = isPredicted
                ? predictedColor
                : (isPh ? phHistoricalColor : ecHistoricalColor);
            final unit = isPh ? '' : ' mS/cm';

            return LineTooltipItem(
              '$label ${spot.y.toStringAsFixed(2)}$unit',
              AppTextStyles.bodyBold.copyWith(color: color),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        if (showPh && phFiltered.isNotEmpty)
          ..._buildSeriesBars(phFiltered, color: phHistoricalColor),
        if (showEc && ecFiltered.isNotEmpty)
          ..._buildSeriesBars(ecFiltered, color: ecHistoricalColor),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    final tabs = Row(
      mainAxisSize: MainAxisSize.min,
      children: ['pH Forecast', 'EC Forecast', 'Both'].map((tabLabel) {
        final key = tabLabel.contains('pH')
            ? 'pH'
            : tabLabel.contains('EC')
                ? 'EC'
                : 'Both';
        final isSelected = widget.activeTab == key;

        return GestureDetector(
          onTap: () => widget.onTabChanged(key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected
                      ? AppColors.primaryButton
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              tabLabel,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: isMobile ? 14 : 16,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );

    final hourControls = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.calloutBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [4, 8, 12].map((h) {
          final isSelected = widget.selectedHours == h;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => widget.onHoursChanged(h),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primaryButton : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${h}h',
                style: AppTextStyles.cardMeta.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tabs,
          const SizedBox(height: 12),
          hourControls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        tabs,
        hourControls,
      ],
    );
  }

  FlTitlesData _buildTitlesData(_ChartRange range, bool isMobile) {
    final interval = math.max(1.0, ((range.maximum - range.minimum) / 8).roundToDouble());
    final decimals = widget.activeTab == 'EC' ? 2 : 1;
    final centerTime = widget.generatedAt ?? manilaNow();
    final horizontalInterval = isMobile
        ? widget.selectedHours.toDouble()
        : widget.selectedHours / 2;

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: isMobile ? 38 : 46,
          interval: interval,
          getTitlesWidget: (val, _) => Text(
            val.toStringAsFixed(decimals),
            style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
          ),
        ),
      ),
      rightTitles: AxisTitles(
        axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: isMobile ? 38 : 46,
          interval: interval,
          getTitlesWidget: (val, _) => Text(
            val.toStringAsFixed(decimals),
            style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: horizontalInterval,
          getTitlesWidget: (val, _) {
            final time = centerTime.add(Duration(minutes: (val * 60).round()));
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                formatManilaClockTime(time),
                style: AppTextStyles.cardMeta
                    .copyWith(fontSize: isMobile ? 10 : null),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegendAndDate(bool isMobile) {
    final legend = Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        if (widget.activeTab != 'EC')
          _legendItem('pH Historical', phHistoricalColor, isDashed: false),
        if (widget.activeTab != 'pH')
          _legendItem('EC Historical', ecHistoricalColor, isDashed: false),
        _legendItem('Predicted (ML)', predictedColor, isDashed: true),
      ],
    );

    final generated = widget.generatedAt == null
        ? null
        : Text(
            'Generated ${formatManilaDateTime(widget.generatedAt!)}',
            style: AppTextStyles.cardMeta,
          );

    if (generated == null) return legend;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          legend,
          const SizedBox(height: 8),
          generated,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        legend,
        generated,
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

  List<ForecastPoint> _filterPoints(List<ForecastPoint> pts) {
    return pts.where((p) {
      if (p.isPredicted) {
        return p.hour <= widget.selectedHours;
      } else {
        return p.hour >= -widget.selectedHours;
      }
    }).toList();
  }

  List<LineChartBarData> _buildSeriesBars(List<ForecastPoint> points,
      {required Color color}) {
    final historical = points.where((p) => !p.isPredicted).toList();
    final predicted = points.where((p) => p.isPredicted).toList();

    final historicalSpots =
        historical.map((p) => FlSpot(p.hour, p.value)).toList();
    final predictedSpots = <FlSpot>[
      if (historical.isNotEmpty)
        FlSpot(historical.last.hour, historical.last.value),
      ...predicted.map((p) => FlSpot(p.hour, p.value)),
    ];

    return [
      if (historicalSpots.isNotEmpty)
        LineChartBarData(
          spots: historicalSpots,
          isCurved: true,
          color: color,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: color.withOpacity(0.10),
          ),
        ),
      if (predictedSpots.isNotEmpty)
        LineChartBarData(
          spots: predictedSpots,
          isCurved: true,
          color: predictedColor,
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: predictedColor.withOpacity(0.06),
          ),
        ),
    ];
  }

  String _getReadingLabel(
    List<ForecastPoint> ph,
    List<ForecastPoint> ec,
    bool showPh,
    bool showEc, {
    required bool predicted,
  }) {
    String? valueFor(List<ForecastPoint> pts) {
      final matching = pts.where((p) => p.isPredicted == predicted).toList();
      if (matching.isEmpty) return null;
      final point = predicted
          ? matching.reduce((a, b) =>
              (a.hour - widget.selectedHours).abs() <=
                      (b.hour - widget.selectedHours).abs()
                  ? a
                  : b)
          : matching.reduce((a, b) => a.hour >= b.hour ? a : b);
      return point.value.toStringAsFixed(2);
    }

    final values = <String>[];
    if (showPh && ph.isNotEmpty) {
      final val = valueFor(ph);
      if (val != null) values.add('pH $val');
    }
    if (showEc && ec.isNotEmpty) {
      final val = valueFor(ec);
      if (val != null) values.add('EC $val');
    }

    return values.isEmpty ? '--' : values.join(' / ');
  }

  _ChartRange _computeRange(
    List<ForecastPoint> points, {
    required double defaultMin,
    required double defaultMax,
  }) {
    if (points.isEmpty) {
      return _ChartRange(defaultMin, defaultMax);
    }
    final values = points.map((p) => p.value).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final spread = maxVal - minVal;
    final padding = math.max(spread * 0.18, 0.2);
    return _ChartRange(
      math.max(0, minVal - padding),
      maxVal + padding,
    );
  }
}

class _ChartRange {
  final double minimum;
  final double maximum;
  const _ChartRange(this.minimum, this.maximum);
}