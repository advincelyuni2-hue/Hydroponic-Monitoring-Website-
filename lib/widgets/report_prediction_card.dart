import 'card_info_tooltip.dart';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'mobile_graph_card.dart';

class ReportPredictionCard extends StatelessWidget {
  final ModelEvaluation evaluation;
  final String selectedParameter; // 'Both', 'pH' or 'EC'
  final int selectedHorizon;
  final ValueChanged<int> onHorizonChanged;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onParameterChanged;
  final VoidCallback onViewTable;

  const ReportPredictionCard({
    super.key,
    required this.evaluation,
    required this.selectedParameter,
    required this.selectedHorizon,
    required this.onHorizonChanged,
    required this.isLoading,
    required this.errorMessage,
    required this.onParameterChanged,
    required this.onViewTable,
  });

  static Color get _phColor => AppColors.accentGreen;
  static Color get _ecColor => AppColors.accentTeal;

  bool get _showPh => selectedParameter != 'EC';
  bool get _showEc => selectedParameter != 'pH';

  // Steps used to pick "nice" axis ticks (0, 2, 4 ... / 0, 0.25, 0.5 ...).
  static const List<double> _niceSteps = [
    0.05, 0.1, 0.2, 0.25, 0.5, 1, 2, 2.5, 5, 10, 20, 25, 50, 100, 200, 250,
    500, 1000,
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: MobileGraphPage.isActive(context) ? EdgeInsets.zero : const EdgeInsets.all(16),
      decoration: MobileGraphPage.isActive(context) ? null : AppDecorations.card(),
      child: MobileGraphComposition(
        chartIndex: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isMobile),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final chartHeight = isMobile
                ? (context.findAncestorWidgetOfExactType<MobileGraphPage>() != null ? 320.0 : 230.0)
                : (constraints.maxWidth * 0.42).clamp(240.0, 280.0);
            return SizedBox(
              height: MobileGraphPage.isActive(context) ? constraints.maxHeight : chartHeight,
              child: MobileGraphTimeline(
                pointCount: isLoading || evaluation.samples.isEmpty ? 0 : evaluation.samples.length,
                child: _buildBody(isMobile),
              ),
            );
          }),
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

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final accuracy = evaluation.accuracyFor(selectedParameter);

    final title = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!MobileGraphPage.isActive(context)) ...[
        Icon(Icons.show_chart, color: AppColors.accentGreen),
        CardInfoTitle('Forecast Model Evaluation', description: 'Compares actual sensor readings with model predictions to evaluate forecasting performance.', style: isMobile
            ? AppTextStyles.sectionTitle
            : AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
        ],
        if (!Responsive.isDesktop(context)) TextButton.icon(
          onPressed: onViewTable,
          icon: const Icon(Icons.table_chart_outlined, size: 17),
          label: const Text('View table'),
        ),
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

    final parameterControls = _selector(
      const ['Both', 'pH', 'EC'],
      selectedParameter,
      onParameterChanged,
    );

    final horizonControls = _horizonSelector();

    final controls = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [parameterControls, horizonControls],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
        if (isMobile || constraints.maxWidth < 640 * textScale) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), controls],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            controls,
          ],
        );
      },
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

  Widget _horizonSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.calloutBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final hours in const [4, 8, 12])
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onHorizonChanged(hours),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selectedHorizon == hours
                      ? AppColors.primaryButton
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${hours}h',
                  style: AppTextStyles.cardMeta.copyWith(
                    color: selectedHorizon == hours
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

  static double _maxOf(Iterable<_Series> items) {
    var maxValue = 0.0;
    for (final s in items) {
      for (final spot in s.spots) {
        maxValue = math.max(maxValue, spot.y);
      }
    }
    return maxValue;
  }

  /// Picks a tick step so the axis ends on a round number
  /// (e.g. pH 0..16 every 2, EC 0..2 every 0.25).
  static _AxisScale _niceScale(double maxValue, {required int maxIntervals}) {
    final target = math.max(maxValue * 1.08, 0.1);
    for (final step in _niceSteps) {
      final n = (target / step).ceil();
      if (n <= maxIntervals) {
        final count = math.max(n, 2);
        return _AxisScale(count * step, step, count);
      }
    }
    return _AxisScale(target, target / maxIntervals, maxIntervals);
  }

  static double _niceStep(double target) {
    for (final step in _niceSteps) {
      if (step >= target) return step;
    }
    return target;
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

  Widget _buildChart(bool isMobile) {
    final samples = evaluation.samples;
    final series = _series();
    if (series.isEmpty) {
      return Center(
        child: Text('No readings for this selection.',
            style: AppTextStyles.cardMeta),
      );
    }

    final hasPh = series.any((s) => !s.isEc);
    final hasEc = series.any((s) => s.isEc);
    final dual = hasPh && hasEc;

    // Left axis follows pH when it is shown, otherwise EC.
    final leftScale = _niceScale(
      _maxOf(series.where((s) => hasPh ? !s.isEc : s.isEc)),
      maxIntervals: isMobile ? 5 : 8,
    );

    // With both parameters, EC gets its own right-hand axis. EC is drawn
    // scaled into the pH range; tooltips and labels show the real values.
    var ecStep = 0.0;
    var ecAxisMax = 0.0;
    var ecScale = 1.0;
    if (dual) {
      final ecMax = _maxOf(series.where((s) => s.isEc));
      ecStep = _niceStep(math.max(ecMax * 1.08, 0.1) / leftScale.intervals);
      ecAxisMax = ecStep * leftScale.intervals;
      ecScale = leftScale.max / ecAxisMax;
    }

    final plotted = [
      for (final s in series) dual && s.isEc ? s.scaled(ecScale) : s,
    ];

    final labelInterval =
        math.max(1, (samples.length / (isMobile ? 3 : 4)).ceil());

    final axisNameStyle = AppTextStyles.cardMeta.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );

    LineTooltipItem tooltipItem(LineBarSpot spot, String? header) {
      final s = plotted[spot.barIndex];
      final real = spot.y / s.scale;
      final value = s.isEc
          ? '${real.toStringAsFixed(3)} mS/cm'
          : real.toStringAsFixed(2);
      return LineTooltipItem(
        header == null ? '' : '$header\n',
        AppTextStyles.cardMeta.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.left,
        children: [
          TextSpan(
            text: '● ',
            style: TextStyle(color: s.lineColor, fontSize: 12),
          ),
          TextSpan(
            text: '${s.name}  ',
            style: AppTextStyles.cardMeta.copyWith(fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: AppTextStyles.bodyBold.copyWith(
              color: s.color,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return MobileLineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(samples.length - 1, 1).toDouble(),
        minY: 0,
        maxY: leftScale.max,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: leftScale.interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.chartGrid.withValues(alpha: 0.55),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(bottom: BorderSide(color: AppColors.chartGrid)),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: dual
              ? AxisTitles(
                  axisNameSize: 20,
                  axisNameWidget: Text(
                    'EC (mS/cm)',
                    style: axisNameStyle.copyWith(color: _ecColor),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: isMobile ? 38 : 44,
                    interval: leftScale.interval,
                    getTitlesWidget: (value, _) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        _tickLabel(value / leftScale.max * ecAxisMax, ecStep),
                        style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                )
              : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameSize: 20,
            axisNameWidget: Text(
              hasPh ? 'pH' : 'EC (mS/cm)',
              style: axisNameStyle.copyWith(
                color: hasPh ? _phColor : _ecColor,
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isMobile ? 34 : 40,
              interval: leftScale.interval,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  _tickLabel(value, leftScale.interval),
                  style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
                ),
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
                    style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          // Dots only appear on the hovered x position, one per line.
          getTouchedSpotIndicator: (barData, spotIndexes) => [
            for (final _ in spotIndexes)
              TouchedSpotIndicatorData(
                FlLine(
                  color: AppColors.textPrimary.withValues(alpha: 0.18),
                  strokeWidth: 1,
                  dashArray: [3, 3],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 5,
                    color: bar.color ?? _phColor,
                    strokeWidth: 2.5,
                    strokeColor: AppColors.cardBackground,
                  ),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.cardBackground,
            tooltipRoundedRadius: 10,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 10,
            maxContentWidth: 220,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorder: BorderSide(color: AppColors.chartGrid),
            getTooltipItems: (touched) => [
              for (var i = 0; i < touched.length; i++)
                tooltipItem(
                  touched[i],
                  i == 0 ? samples[touched[i].x.toInt()].label : null,
                ),
            ],
          ),
        ),
        lineBarsData: [
          for (final s in plotted)
            LineChartBarData(
              spots: s.plotSpots,
              isCurved: false,
              color: s.lineColor,
              barWidth: s.predicted ? 1.75 : 2.25,
              isStrokeCapRound: true,
              dashArray: s.predicted ? [6, 4] : null,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                // Fill only the main measured line; EC gets a fill only
                // when it is the only parameter shown.
                show: !s.predicted && (!s.isEc || !hasPh),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    s.color.withValues(alpha: 0.16),
                    s.color.withValues(alpha: 0.0),
                  ],
                ),
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
                      Container(width: 4, height: 3, color: s.lineColor),
                      if (i < 2) const SizedBox(width: 2),
                    ],
                  ],
                )
              else
                Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    color: s.lineColor,
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

  /// Multiplier applied when plotting (used to draw EC on the pH scale).
  final double scale;

  const _Series(this.name, this.color, this.predicted, this.spots,
      {this.scale = 1});

  bool get isEc => name.startsWith('EC');

  /// Predicted lines use a lighter tint so they read apart from measured.
  Color get lineColor =>
      predicted ? Color.lerp(color, Colors.white, 0.4)! : color;

  List<FlSpot> get plotSpots => scale == 1
      ? spots
      : [for (final p in spots) FlSpot(p.x, p.y * scale)];

  _Series scaled(double factor) =>
      _Series(name, color, predicted, spots, scale: factor);
}

class _AxisScale {
  final double max;
  final double interval;
  final int intervals;
  const _AxisScale(this.max, this.interval, this.intervals);
}
