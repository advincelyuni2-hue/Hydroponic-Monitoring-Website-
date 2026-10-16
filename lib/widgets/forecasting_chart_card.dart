import 'mobile_graph_card.dart';
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
  final bool isOffline;
  final bool isCalibrating;
  final String? forecastIssue;
  final DateTime? latestSensorRecordedAt;

  const ForecastingChartCard({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.selectedHours,
    required this.onHoursChanged,
    required this.points,
    this.ecPoints,
    this.generatedAt,
    this.isOffline = false,
    this.isCalibrating = false,
    this.forecastIssue,
    this.latestSensorRecordedAt,
  });

  @override
  State<ForecastingChartCard> createState() => ForecastingChartCardState();
}

class ForecastingChartCardState extends State<ForecastingChartCard> {
  static Color get phHistoricalColor => AppColors.accentGreen;
  static Color get ecHistoricalColor => AppColors.accentTeal;
  static Color get predictedColor => AppColors.warningYellow;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    if (widget.isOffline || widget.forecastIssue != null) {
      final lastReceived = widget.latestSensorRecordedAt == null
          ? 'No sensor data received'
          : 'Last received ${formatManilaDateTime(toManilaTime(widget.latestSensorRecordedAt!))}';

      return Container(
        width: double.infinity,
        height: MobileGraphPage.isActive(context) ? null : (isDesktop ? 689 : 420),
        padding: MobileGraphPage.isActive(context) ? EdgeInsets.zero : EdgeInsets.all(isMobile ? 16 : 20),
        decoration: MobileGraphPage.isActive(context) ? null : AppDecorations.card(),
        child: MobileGraphComposition(
          chartIndex: 1,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isCalibrating ? Icons.tune : Icons.cloud_off,
                      size: 46,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isCalibrating
                          ? 'Calibration in progress'
                          : 'Sensor offline',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isCalibrating
                          ? 'Forecasting and reservoir history are paused while the probe is in calibration solution.'
                          : 'Forecasting requires a recent five-minute sensor reading.',
                      style: AppTextStyles.cardMeta,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.isOffline) ...[
                      const SizedBox(height: 4),
                      Text(lastReceived, style: AppTextStyles.cardMeta),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final showPh = widget.activeTab == 'pH' || widget.activeTab == 'Both';
    final showEc = widget.activeTab == 'EC' || widget.activeTab == 'Both';

    final allFiltered = _filterPoints(widget.points);
    final ecFiltered = _filterPoints(widget.ecPoints ?? []);

    final phFiltered = (widget.activeTab == 'Both' && ecFiltered.isEmpty)
        ? allFiltered.where((p) => p.value >= 3.0).toList()
        : (showPh ? allFiltered : <ForecastPoint>[]);

    final ecPointsResolved = (widget.activeTab == 'Both' && ecFiltered.isEmpty)
        ? allFiltered.where((p) => p.value <= 3.0).toList()
        : (showEc ? (ecFiltered.isNotEmpty ? ecFiltered : allFiltered) : <ForecastPoint>[]);

    final hasFallbackHistory = [...phFiltered, ...ecPointsResolved].any(
      (point) => !point.isPredicted && point.isFallback,
    );

    final phRange = _computeRange(phFiltered, defaultMin: 5.0, defaultMax: 10.0);
    final ecRange = _computeRange(ecPointsResolved, defaultMin: 0.0, defaultMax: 3.0);

    late ChartRange chartRange;
    if (widget.activeTab == 'EC') {
      chartRange = ecRange;
    } else if (widget.activeTab == 'pH') {
      chartRange = phRange;
    } else {
      chartRange = const ChartRange(0.0, 15.0);
    }

    final currentLabel = getReadingLabel(
      phFiltered,
      ecPointsResolved,
      showPh,
      showEc,
      predicted: false,
    );

    final forecastLabel = getReadingLabel(
      phFiltered,
      ecPointsResolved,
      showPh,
      showEc,
      predicted: true,
    );

    return Container(
      width: double.infinity,
      height: isDesktop ? 689 : null,
      padding: MobileGraphPage.isActive(context) ? EdgeInsets.zero : EdgeInsets.all(isMobile ? 16 : 20),
      decoration: MobileGraphPage.isActive(context) ? null : AppDecorations.card(),
      child: MobileGraphComposition(
        chartIndex: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isDesktop ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _buildHeader(isMobile),
           SizedBox(height: isMobile ? 12 : 16),
          Expanded(
            flex: isDesktop ? 1 : 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 28), // Space for callout badge & hover tooltips
                    child: SizedBox(
                      height: MobileGraphPage.isActive(context)
                          ? null
                          : widget.activeTab == 'Both' ? 750 : (isDesktop ? 500 : 320),
                      width: double.infinity,
                      child: MobileGraphTimeline(
                        pointCount: math.max(phFiltered.length, ecPointsResolved.length),
                        child: MobileLineChart(
                        buildChartData(
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
                  ),
                  buildCalloutBadge(isMobile, currentLabel, forecastLabel),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendAndDate(isMobile, hasFallbackHistory),
        ],
      ),
    );
  }

  Widget buildCalloutBadge(
    bool isMobile,
    String currentLabel,
    String forecastLabel,
  ) {
    return Positioned(
      top: 0,
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
                const TextSpan(text: '   Forecast '),
                TextSpan(
                  text: forecastLabel,
                  style: TextStyle(
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

  LineChartData buildChartData(
    ChartRange chartRange,
    bool isMobile,
    List<ForecastPoint> phFiltered,
    List<ForecastPoint> ecFiltered,
    bool showPh,
    bool showEc,
  ) {
    return LineChartData(
      clipData: const FlClipData.none(), // Allow hover tooltips to render without clipping
      minX: -widget.selectedHours.toDouble(),
      maxX: widget.selectedHours.toDouble(),
      minY: chartRange.minimum,
      maxY: chartRange.maximum,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.chartGrid.withValues(alpha: 0.65),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: AppColors.chartGrid.withValues(alpha: 0.35),
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
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.cardBackground,
          tooltipRoundedRadius: 8,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipMargin: 8,
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
              '$label ${spot.y.toStringAsFixed(6)}$unit',
              AppTextStyles.bodyBold.copyWith(color: color, fontSize: 11),
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
    final tabItems = ['pH Forecast', 'EC Forecast', 'Both'].map((tabLabel) {
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
                  color: isSelected ? AppColors.primaryButton : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              tabLabel,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: isMobile ? 14 : 16,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList();
    final tabs = isMobile
        ? Wrap(spacing: 0, runSpacing: 4, children: tabItems)
        : Row(mainAxisSize: MainAxisSize.min, children: tabItems);

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
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryButton : Colors.transparent,
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

  FlTitlesData _buildTitlesData(ChartRange range, bool isMobile) {
    final interval = math.max(1.0, ((range.maximum - range.minimum) / 8).roundToDouble());
    const decimals = 6;
    final centerTime = widget.generatedAt ?? manilaNow();
    final horizontalInterval = isMobile ? widget.selectedHours.toDouble() : widget.selectedHours / 2;

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: isMobile ? 62 : 72,
          interval: interval,
          getTitlesWidget: (val, meta) => Text(
            val.toStringAsFixed(decimals),
            style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
          ),
        ),
      ),
      rightTitles: AxisTitles(
        axisNameWidget: Text('Value', style: AppTextStyles.cardMeta),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: isMobile ? 62 : 72,
          interval: interval,
          getTitlesWidget: (val, meta) => Text(
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
          getTitlesWidget: (val, meta) {
            final time = centerTime.add(Duration(minutes: (val * 60).round()));
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                formatManilaClockTime(time),
                style: AppTextStyles.cardMeta.copyWith(fontSize: isMobile ? 10 : null),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegendAndDate(bool isMobile, bool hasFallbackHistory) {
    final legend = Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        if (widget.activeTab != 'EC')
          _legendItem(
            hasFallbackHistory ? 'pH Estimated baseline' : 'pH Historical',
            phHistoricalColor,
            isDashed: false,
          ),
        if (widget.activeTab != 'pH')
          _legendItem(
            hasFallbackHistory ? 'EC Estimated baseline' : 'EC Historical',
            ecHistoricalColor,
            isDashed: false,
          ),
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

  List<LineChartBarData> _buildSeriesBars(
    List<ForecastPoint> points, {
    required Color color,
  }) {
    final historical = points.where((p) => !p.isPredicted).toList();
    final predicted = points.where((p) => p.isPredicted).toList();

    final historicalSpots = historical.map((p) => FlSpot(p.hour, p.value)).toList();
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
            color: color.withValues(alpha: 0.10),
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
            color: predictedColor.withValues(alpha: 0.06),
          ),
        ),
    ];
  }

  String getReadingLabel(
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
      return point.value.toStringAsFixed(6);
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

  ChartRange _computeRange(
    List<ForecastPoint> points, {
    required double defaultMin,
    required double defaultMax,
  }) {
    if (points.isEmpty) {
      return ChartRange(defaultMin, defaultMax);
    }
    final values = points.map((p) => p.value).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final spread = maxVal - minVal;
    final padding = math.max(spread * 0.18, 0.2);

    return ChartRange(
      math.max(0, minVal - padding),
      maxVal + padding,
    );
  }
}

class ChartRange {
  final double minimum;
  final double maximum;
  const ChartRange(this.minimum, this.maximum);
}
