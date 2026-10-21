import 'sensor_offline_state.dart';
import 'mobile_graph_card.dart';
import 'mobile_graph_legend.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'card_info_tooltip.dart';
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
  final bool isLoading;
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
    this.isLoading = false,
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

  // Steps used to pick "nice" axis ticks (5, 6, 7 ... / 1.5, 2, 2.5 ...).
  static const List<double> _niceSteps = [
    0.05,
    0.1,
    0.2,
    0.25,
    0.5,
    1,
    2,
    2.5,
    5,
    10,
    20,
    25,
    50,
    100,
    200,
    250,
    500,
    1000,
  ];

  static double _identity(double value) => value;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    if (widget.isLoading || widget.isOffline || widget.forecastIssue != null) {
      final lastReceived = widget.latestSensorRecordedAt == null
          ? 'No sensor data received'
          : 'Last received ${formatManilaDateTime(toManilaTime(widget.latestSensorRecordedAt!))}';

      return Container(
        width: double.infinity,
        height:
            MobileGraphPage.isActive(context) ? null : (isDesktop ? 689 : 420),
        padding: MobileGraphPage.isActive(context)
            ? EdgeInsets.zero
            : EdgeInsets.all(isMobile ? 16 : 20),
        decoration:
            MobileGraphPage.isActive(context) ? null : AppDecorations.card(),
        child: MobileGraphComposition(
          chartIndex: 1,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.isOffline && !widget.isCalibrating
                ? OfflineHeader(child: _buildHeader(isMobile))
                : _buildHeader(isMobile),
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.isOffline && !widget.isCalibrating
                  ? const SensorOfflineBody.forecast()
                  : Center(
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
        : (showEc
            ? (ecFiltered.isNotEmpty ? ecFiltered : allFiltered)
            : <ForecastPoint>[]);

    final hasFallbackHistory = [...phFiltered, ...ecPointsResolved].any(
      (point) => !point.isPredicted && point.isFallback,
    );

    final phRange =
        _computeRange(phFiltered, defaultMin: 5.0, defaultMax: 10.0);
    final ecRange =
        _computeRange(ecPointsResolved, defaultMin: 0.0, defaultMax: 3.0);

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
      padding: MobileGraphPage.isActive(context)
          ? EdgeInsets.zero
          : EdgeInsets.all(isMobile ? 16 : 20),
      decoration:
          MobileGraphPage.isActive(context) ? null : AppDecorations.card(),
      child: MobileGraphComposition(
        chartIndex: 4,
        subtitle: 'Historical readings and ML forecast',
        sheetTitle: 'Forecast details',
        sheetContent: [
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(20)),
              child: _buildLegendAndDate(true, hasFallbackHistory)),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, space) {
            final cards = [
              _mobileReadingCard('Current', currentLabel),
              _mobileReadingCard('Forecast', forecastLabel, forecast: true),
            ];
            if (space.maxWidth < 260 ||
                MediaQuery.textScalerOf(context).scale(12) > 17) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    cards.first,
                    const SizedBox(height: 8),
                    cards.last
                  ]);
            }
            return IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Expanded(child: cards.first),
                  const SizedBox(width: 8),
                  Expanded(child: cards.last)
                ]));
          }),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isDesktop ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 8),
          _readingBadges(phFiltered, ecPointsResolved, showPh, showEc),
          const SizedBox(height: 12),
          Expanded(
            flex: isDesktop ? 1 : 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: MobileGraphPage.isActive(context)
                          ? null
                          : widget.activeTab == 'Both'
                              ? 750
                              : (isDesktop ? 500 : 320),
                      width: double.infinity,
                      child: MobileGraphTimeline(
                        pointCount: math.max(
                            phFiltered.length, ecPointsResolved.length),
                        child: MobileLineChart(
                          continuousTimeLabels: true,
                          preserveAxes: MobileGraphPage.isActive(context),
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

  Widget _readingBadges(List<ForecastPoint> ph, List<ForecastPoint> ec,
      bool showPh, bool showEc) {
    Widget badge(String parameter, Color color, bool isPh) {
      final current = getReadingLabel(ph, ec, isPh, !isPh, predicted: false)
          .replaceFirst('$parameter ', '');
      final forecast = getReadingLabel(ph, ec, isPh, !isPh, predicted: true)
          .replaceFirst('$parameter ', '');
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('$parameter  ',
                style: AppTextStyles.cardMeta
                    .copyWith(fontWeight: FontWeight.w600)),
            Text(current, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
            Text('  ?  ', style: AppTextStyles.cardMeta),
            Text(forecast,
                style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
          ]));
    }

    return Wrap(spacing: 12, runSpacing: 8, children: [
      if (showPh && ph.isNotEmpty) badge('pH', phHistoricalColor, true),
      if (showEc && ec.isNotEmpty) badge('EC', ecHistoricalColor, false),
    ]);
  }

  Widget _mobileReadingCard(String title, String reading,
      {bool forecast = false}) {
    final values = <String, String>{};
    for (final item in reading.split(' / ')) {
      final parts = item.split(' ');
      if (parts.length == 2) values[parts.first] = parts.last;
    }
    final style = AppTextStyles.cardMeta.copyWith(fontSize: 12);
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: forecast ? const Color(0xFFFFF4E5) : Colors.white,
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title.toUpperCase(),
                    style: style.copyWith(
                        color: forecast
                            ? const Color(0xFFAD4D00)
                            : AppColors.primaryButton,
                        fontWeight: FontWeight.w700)),
                if (forecast)
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                          color: predictedColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('+${widget.selectedHours}h',
                          style: style.copyWith(fontSize: 10))),
              ]),
          const SizedBox(height: 12),
          for (final parameter in ['pH', 'EC'])
            if (widget.activeTab == 'Both' || widget.activeTab == parameter)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parameter == 'EC' && widget.activeTab == 'Both') ...[
                        Divider(
                            color: forecast
                                ? const Color(0xFFFFD9AF)
                                : const Color(0xFFE2E6D4)),
                        const SizedBox(height: 4),
                      ],
                      Row(children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: parameter == 'pH'
                                    ? phHistoricalColor
                                    : ecHistoricalColor)),
                        const SizedBox(width: 6),
                        Text(parameter, style: style),
                        if (parameter == 'EC')
                          Flexible(
                              child: Text('  mS/cm',
                                  style: style.copyWith(fontSize: 10))),
                      ]),
                      Text(values[parameter] ?? '?',
                          style: AppTextStyles.bodyBold.copyWith(fontSize: 26)),
                    ]),
              ),
        ]));
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
    final hasPh = showPh && phFiltered.isNotEmpty;
    final hasEc = showEc && ecFiltered.isNotEmpty;
    final dual = hasPh && hasEc;
    final maxIntervals = isMobile ? 5 : 8;

    // Left axis follows pH (or EC when it is the only parameter). With both
    // parameters EC gets its own right-hand axis: it is drawn scaled into the
    // pH range, while labels and tooltips show the real EC values.
    final _AxisRange left;
    _AxisRange? right;
    if (dual) {
      final phRange =
          _computeRange(phFiltered, defaultMin: 5.0, defaultMax: 10.0);
      final ecRange =
          _computeRange(ecFiltered, defaultMin: 0.0, defaultMax: 3.0);
      left = _niceAxis(phRange.minimum, phRange.maximum,
          maxIntervals: maxIntervals);
      right = _alignedAxis(ecRange.minimum, ecRange.maximum, left.intervals);
    } else {
      left = _niceAxis(chartRange.minimum, chartRange.maximum,
          maxIntervals: maxIntervals);
    }
    final r = right;
    final scale = r == null ? 1.0 : (left.max - left.min) / (r.max - r.min);
    double ecToPlot(double v) => r == null ? v : left.min + (v - r.min) * scale;
    double ecToReal(double y) => r == null ? y : r.min + (y - left.min) / scale;

    final plots = <_PlotBar>[
      if (hasPh)
        ..._buildSeriesBars(
          phFiltered,
          param: 'pH',
          color: phHistoricalColor,
          fillHistorical: true,
          fillPredicted: !dual,
        ),
      if (hasEc)
        ..._buildSeriesBars(
          ecFiltered,
          param: 'EC',
          color: ecHistoricalColor,
          toPlot: ecToPlot,
          toReal: ecToReal,
          fillHistorical: !hasPh,
          fillPredicted: !dual,
        ),
    ];
    final infos = [for (final p in plots) p.info];

    return LineChartData(
      clipData: const FlClipData
          .none(), // Allow hover tooltips to render without clipping
      minX: -widget.selectedHours.toDouble(),
      maxX: widget.selectedHours.toDouble(),
      minY: left.min,
      maxY: left.max,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: left.step,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.chartGrid.withValues(alpha: 0.55),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
            bottom: BorderSide(color: AppColors.chartGrid),
            left: BorderSide(
                color: hasEc && !hasPh ? ecHistoricalColor : phHistoricalColor,
                width: 2.5),
            right: dual
                ? BorderSide(color: ecHistoricalColor, width: 2.5)
                : BorderSide.none),
      ),
      titlesData: _buildTitlesData(
        left: left,
        right: right,
        leftIsEc: hasEc && !hasPh,
        isMobile: isMobile,
      ),
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
        handleBuiltInTouches: true,
        // Dots only appear on the hovered point, one per line.
        getTouchedSpotIndicator: (barData, indexes) => [
          for (final _ in indexes)
            TouchedSpotIndicatorData(
              FlLine(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  // The forecast line starts at the last measured point;
                  // skip its duplicate dot at "now".
                  final isConnector = bar.dashArray != null && spot.x <= 0;
                  return FlDotCirclePainter(
                    radius: isConnector ? 0 : 5,
                    color: bar.color ?? phHistoricalColor,
                    strokeWidth: isConnector ? 0 : 2.5,
                    strokeColor: AppColors.cardBackground,
                  );
                },
              ),
            ),
        ],
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.cardBackground,
          tooltipRoundedRadius: 10,
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          maxContentWidth: 220,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipMargin: 10,
          tooltipBorder: BorderSide(color: AppColors.chartGrid),
          getTooltipItems: (spots) {
            var headerShown = false;
            return spots.map((spot) {
              final info = infos[spot.barIndex];
              final isConnector = spot.x <= 0 && info.predicted;
              if (isConnector) return null;

              final isPh = info.param == 'pH';
              final value = info.toReal(spot.y).toStringAsFixed(isPh ? 2 : 3);
              final unit = isPh ? '' : ' mS/cm';
              final name =
                  info.predicted ? '${info.param} forecast' : info.param;
              final dotColor = info.predicted
                  ? predictedColor
                  : (isPh ? phHistoricalColor : ecHistoricalColor);
              // Yellow text is hard to read on white; darken it for the value.
              final textColor = info.predicted
                  ? Color.lerp(predictedColor, Colors.black, 0.35)!
                  : dotColor;
              final header = headerShown ? '' : '${_timeAtHour(spot.x)}\n';
              headerShown = true;

              return LineTooltipItem(
                header,
                AppTextStyles.cardMeta.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.left,
                children: [
                  TextSpan(
                    text: '● ',
                    style: TextStyle(color: dotColor, fontSize: 12),
                  ),
                  TextSpan(
                    text: '$name  ',
                    style: AppTextStyles.cardMeta.copyWith(fontSize: 12),
                  ),
                  TextSpan(
                    text: '$value$unit',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: textColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [for (final p in plots) p.bar],
    );
  }

  Widget _buildHeader(bool isMobile) {
    final tabs = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: AppColors.calloutBackground,
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final parameter in ['Both', 'pH', 'EC'])
            InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => widget.onTabChanged(parameter),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                        color: widget.activeTab == parameter
                            ? AppColors.primaryButton
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(parameter,
                        style: AppTextStyles.cardMeta.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.activeTab == parameter
                                ? Colors.white
                                : AppColors.textPrimary)))),
        ]));

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

    if (MobileGraphPage.isActive(context)) {
      return MobileGraphControls(
          value: widget.activeTab,
          values: const ['pH', 'EC', 'Both'],
          onChanged: widget.onTabChanged,
          trailing: hourControls);
    }
    final title = CardInfoTitle('Forecasting Chart',
        description:
            'Shows recent readings and model forecasts for pH and EC over the selected horizon.',
        style:
            AppTextStyles.sectionTitle.copyWith(fontSize: isMobile ? 17 : 19));
    return LayoutBuilder(builder: (context, space) {
      final controls =
          Wrap(spacing: 10, runSpacing: 8, children: [tabs, hourControls]);
      if (space.maxWidth <
          660 * (MediaQuery.textScalerOf(context).scale(14) / 14)) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 8), controls]);
      }
      return Row(children: [
        title,
        const SizedBox(width: 16),
        Expanded(child: controls)
      ]);
    });
  }

  FlTitlesData _buildTitlesData({
    required _AxisRange left,
    required _AxisRange? right,
    required bool leftIsEc,
    required bool isMobile,
  }) {
    final centerTime = widget.generatedAt ?? manilaNow();
    final horizontalInterval =
        isMobile ? widget.selectedHours.toDouble() : widget.selectedHours / 2;

    TextStyle axisNameStyle(Color color) => AppTextStyles.cardMeta.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        );

    final r = right;

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        axisNameSize: 20,
        axisNameWidget: Text(
          leftIsEc ? 'EC (mS/cm)' : 'pH',
          style:
              axisNameStyle(leftIsEc ? ecHistoricalColor : phHistoricalColor),
        ),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: isMobile ? 38 : 44,
          interval: left.step,
          getTitlesWidget: (val, meta) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              _tickLabel(val, left.step),
              style: AppTextStyles.cardMeta.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: leftIsEc ? ecHistoricalColor : phHistoricalColor),
            ),
          ),
        ),
      ),
      rightTitles: r == null
          ? const AxisTitles(sideTitles: SideTitles(showTitles: false))
          : AxisTitles(
              axisNameSize: 20,
              axisNameWidget: Text(
                'EC (mS/cm)',
                style: axisNameStyle(ecHistoricalColor),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isMobile ? 38 : 44,
                interval: left.step,
                getTitlesWidget: (val, meta) {
                  final real = r.min +
                      (val - left.min) *
                          (r.max - r.min) /
                          (left.max - left.min);
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      _tickLabel(real, r.step),
                      style: AppTextStyles.cardMeta.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ecHistoricalColor),
                    ),
                  );
                },
              ),
            ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: horizontalInterval,
          getTitlesWidget: (val, meta) {
            final time = centerTime.add(Duration(minutes: (val * 60).round()));
            if (MobileGraphPage.isActive(context) && val.abs() < 0.001) {
              return Text('Current time\n${formatManilaClockTime(time)}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardMeta
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w600));
            }
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

  Widget _buildLegendAndDate(bool isMobile, bool hasFallbackHistory) {
    final legend = MobileGraphPage.isActive(context)
        ? MobileForecastLegend(parameter: widget.activeTab,
            phColor: phHistoricalColor, ecColor: ecHistoricalColor,
            estimated: hasFallbackHistory)
        : Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        if (widget.activeTab != 'EC')
          _legendItem(
            hasFallbackHistory ? 'pH estimated' : 'pH measured',
            phHistoricalColor,
            isDashed: false,
          ),
        if (widget.activeTab != 'pH')
          _legendItem(
            hasFallbackHistory ? 'EC estimated' : 'EC measured',
            ecHistoricalColor,
            isDashed: false,
          ),
        if (widget.activeTab != 'EC')
          _legendItem('pH forecast', phHistoricalColor, isDashed: true),
        if (widget.activeTab != 'pH')
          _legendItem('EC forecast', ecHistoricalColor, isDashed: true),
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
        if (isDashed)
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Container(width: 4, height: 3, color: color),
                if (i < 2) const SizedBox(width: 2),
              ],
            ],
          )
        else
          Container(
            width: 14,
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

  LinearGradient _fade(Color color, double alpha) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0.0),
        ],
      );

  List<_PlotBar> _buildSeriesBars(
    List<ForecastPoint> points, {
    required String param,
    required Color color,
    double Function(double) toPlot = _identity,
    double Function(double) toReal = _identity,
    required bool fillHistorical,
    required bool fillPredicted,
  }) {
    final historical = points.where((p) => !p.isPredicted).toList();
    final predicted = points.where((p) => p.isPredicted).toList();

    final historicalSpots =
        historical.map((p) => FlSpot(p.hour, toPlot(p.value))).toList();
    final predictedSpots = <FlSpot>[
      if (historical.isNotEmpty)
        FlSpot(historical.last.hour, toPlot(historical.last.value)),
      ...predicted.map((p) => FlSpot(p.hour, toPlot(p.value))),
    ];

    return [
      if (historicalSpots.isNotEmpty)
        _PlotBar(
          LineChartBarData(
            spots: historicalSpots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: fillHistorical,
              gradient: _fade(color, 0.16),
            ),
          ),
          _BarInfo(param, false, toReal),
        ),
      if (predictedSpots.isNotEmpty)
        _PlotBar(
          LineChartBarData(
            spots: predictedSpots,
            isCurved: true,
            color: color,
            barWidth: 2.25,
            isStrokeCapRound: true,
            dashArray: [6, 4],
            // No resting dots: they only appear on hover.
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: fillPredicted,
              gradient: _fade(color, 0.08),
            ),
          ),
          _BarInfo(param, true, toReal),
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
    String? valueFor(List<ForecastPoint> pts, int decimals) {
      final matching = pts.where((p) => p.isPredicted == predicted).toList();
      if (matching.isEmpty) return null;
      final point = predicted
          ? matching.reduce((a, b) => (a.hour - widget.selectedHours).abs() <=
                  (b.hour - widget.selectedHours).abs()
              ? a
              : b)
          : matching.reduce((a, b) => a.hour >= b.hour ? a : b);
      return point.value.toStringAsFixed(decimals);
    }

    final values = <String>[];
    if (showPh && ph.isNotEmpty) {
      final val = valueFor(ph, 2);
      if (val != null) values.add('pH $val');
    }
    if (showEc && ec.isNotEmpty) {
      final val = valueFor(ec, 3);
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

  String _timeAtHour(double hour) {
    final center = widget.generatedAt ?? manilaNow();
    return formatManilaClockTime(
      center.add(Duration(minutes: (hour * 60).round())),
    );
  }

  /// Round axis bounds + step covering [low]..[high] with at most
  /// [maxIntervals] gridlines.
  static _AxisRange _niceAxis(
    double low,
    double high, {
    required int maxIntervals,
  }) {
    for (final step in _niceSteps) {
      var lo = (low / step).floorToDouble() * step;
      if (lo < 0) lo = 0;
      var hi = (high / step).ceilToDouble() * step;
      var n = ((hi - lo) / step).round();
      if (n < 2) {
        hi = lo + 2 * step;
        n = 2;
      }
      if (n <= maxIntervals) return _AxisRange(lo, hi, step);
    }
    final lo = math.max(low, 0.0);
    return _AxisRange(lo, high, (high - lo) / maxIntervals);
  }

  /// Round axis bounds covering [low]..[high] with exactly [intervals]
  /// gridlines, so a second axis lines up with the first one.
  static _AxisRange _alignedAxis(double low, double high, int intervals) {
    for (final step in _niceSteps) {
      var lo = (low / step).floorToDouble() * step;
      if (lo < 0) lo = 0;
      final hi = lo + intervals * step;
      if (hi >= high - 1e-9) return _AxisRange(lo, hi, step);
    }
    final span = math.max(high - low, 0.1);
    return _AxisRange(low, low + span, span / intervals);
  }

  static String _tickLabel(double value, double step) {
    if (step >= 1 && (step - step.roundToDouble()).abs() < 1e-9) {
      return value.toStringAsFixed(0);
    }
    final tenths = step * 10;
    if ((tenths - tenths.roundToDouble()).abs() < 1e-9) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }
}

class ChartRange {
  final double minimum;
  final double maximum;
  const ChartRange(this.minimum, this.maximum);
}

class _AxisRange {
  final double min;
  final double max;
  final double step;
  const _AxisRange(this.min, this.max, this.step);

  int get intervals => ((max - min) / step).round();
}

/// Which parameter a plotted line belongs to, so tooltips can show the real
/// value even when a series is drawn scaled onto the other axis.
class _BarInfo {
  final String param;
  final bool predicted;
  final double Function(double) toReal;
  const _BarInfo(this.param, this.predicted, this.toReal);
}

class _PlotBar {
  final LineChartBarData bar;
  final _BarInfo info;
  const _PlotBar(this.bar, this.info);
}
