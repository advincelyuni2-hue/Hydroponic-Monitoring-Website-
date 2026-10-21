import 'sensor_offline_state.dart';
import 'card_info_tooltip.dart';
import 'package:flutter/material.dart';
import '../models/forecast_insight_summary.dart';
import '../services/app_state.dart';
import '../utils/sensor_value_format.dart';

import '../models/forecasting_models.dart' as forecasting;
import '../models/monitoring_models.dart'
    show ForecastPoint, ForecastHorizonSummary, ParameterStatus;
import '../theme/app_colors.dart';
import '../theme/forecast_severity_style.dart';
import '../theme/theme_mode_controller.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

/// Dashboard-only forecast insight. Uses existing dashboard forecast data.
class DashboardInsightCard extends StatefulWidget {
  const DashboardInsightCard({
    super.key,
    required this.phForecast,
    required this.ecForecast,
    required this.summaries,
    required this.parameterStatuses,
    required this.onViewDetails,
    this.phInsight,
    this.ecInsight,
    this.isOffline = false,
    this.isCalibrating = false,
    this.forecastIssue,
  });

  final List<ForecastPoint> phForecast;
  final List<ForecastPoint> ecForecast;
  final List<ForecastHorizonSummary> summaries;
  final List<ParameterStatus> parameterStatuses;
  final forecasting.PredictionInsightDetail? phInsight;
  final forecasting.PredictionInsightDetail? ecInsight;
  final VoidCallback onViewDetails;
  final bool isOffline;
  final bool isCalibrating;
  final String? forecastIssue;

  @override
  State<DashboardInsightCard> createState() => _DashboardInsightCardState();
}

class _DashboardInsightCardState extends State<DashboardInsightCard> {
  String _selected = 'pH';

  ForecastInsightSummary _summaryFor(bool isPh) {
    final ranges = appParameterRanges.value;
    return ForecastInsightSummary(
      forecast: (isPh ? widget.phForecast : widget.ecForecast)
          .map((p) => forecasting.ForecastingChartPoint(
              hour: p.hour,
              value: p.value,
              isPredicted: p.isPredicted,
              isFallback: p.isFallback))
          .toList(),
      minimum: isPh ? ranges.phMin : ranges.ecMin,
      maximum: isPh ? ranges.phMax : ranges.ecMax,
    );
  }

  bool _modelOffline(bool isPh) =>
      widget.isOffline ||
      widget.isCalibrating ||
      widget.forecastIssue != null ||
      _summaryFor(isPh).points.isEmpty;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appThemeMode,
        builder: (context, _) => ValueListenableBuilder<ParameterRangeConfig>(
          valueListenable: appParameterRanges,
          builder: (context, _, __) => _buildCard(context),
        ),
      );

  Widget _buildCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: MediaQuery.sizeOf(context).width <= 600
          ? const EdgeInsets.all(16)
          : const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: AppDecorations.card(radius: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700 ||
              MediaQuery.textScalerOf(context).scale(14) > 16.8;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.isOffline && !widget.isCalibrating
                  ? OfflineHeader(child: _header(narrow)) : _header(narrow),
              const SizedBox(height: 8),
              // Both bodies participate in layout; only the selected one paints.
              // Longer EC units and different warnings cannot resize the card.
              IndexedStack(
                index: _selected == 'pH' ? 0 : 1,
                children: [
                  for (final isPh in [true, false])
                    if (widget.isOffline && !widget.isCalibrating)
                      const SizedBox(height: 140, child: SensorOfflineBody.insight())
                    else if (_modelOffline(isPh))
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 140),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Center(
                            child: Text('model is offline',
                                style: AppTextStyles.bodyBold
                                    .copyWith(color: AppColors.textSecondary))),
                      )
                    else
                      _forecastBody(narrow, isPh, constraints.maxWidth),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(bool narrow) {
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.trending_down_rounded,
            size: 22, color: AppColors.warningYellow),
        const SizedBox(width: 8),
        Flexible(
          child: CardInfoTitle('Latest Forecast Insight', description: 'Summarizes the predicted trend, future values, and possible threshold crossings for pH or EC.',
            style:
                AppTextStyles.sectionTitle.copyWith(fontSize: narrow ? 17 : 19),
          ),
        ),
      ],
    );

    final details = TextButton(
      onPressed: widget.onViewDetails,
      style: TextButton.styleFrom(
        // No right padding, so the text lines up with the card's right edge.
        padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
        foregroundColor: AppColors.accentGreen,
      ),
      child: Text(narrow ? 'View forecast details' : 'View insight details'),
    );

    final toggle = _selector<String>(
      values: const ['pH', 'EC'],
      selected: _selected,
      label: (value) => value,
      onSelected: (value) => setState(() => _selected = value),
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 8),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.start,
            spacing: 12,
            overflowSpacing: 4,
            children: [toggle, details],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(child: title),
              const SizedBox(width: 16),
              toggle,
            ],
          ),
        ),
        details,
      ],
    );
  }

  /// Rounded-rectangle selector (matches the Forecast Overview pill).
  Widget _selector<T>({
    required List<T> values,
    required T selected,
    required String Function(T value) label,
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
                  color: value == selected
                      ? AppColors.primaryButton
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label(value),
                  style: AppTextStyles.cardMeta.copyWith(
                    color: value == selected
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

  Widget _forecastBody(bool narrow, bool isPh, double width) {
    final summary = _summaryFor(isPh);
    final selected = isPh ? 'pH' : 'EC';
    final threshold = summary.thresholdLabel(unit: isPh ? '' : 'mS/cm');
    final crossing = summary.crossingLabel;
    final severity = ForecastSeverityStyle(summary.severity);

    final trendPanel = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: severity.tint,
        borderRadius: narrow
            ? BorderRadius.circular(13)
            : const BorderRadius.horizontal(left: Radius.circular(13)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Trend', style: AppTextStyles.cardMeta),
          const SizedBox(height: 2),
          Text(
            summary.trend,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 19,
              color: severity.text,
            ),
          ),
          const SizedBox(height: 2),
          Text('$selected, next 12h', style: AppTextStyles.cardMeta),
        ],
      ),
    );

    final horizonPanel = Builder(builder: (context) {
      final stacked = narrow &&
          (width - 16) < 270 * MediaQuery.textScalerOf(context).scale(14) / 14;
      final tiles = [4, 8, 12].map((hour) {
        final value = summary.valueAt(hour);
        final style = ForecastSeverityStyle(summary.severityAt(hour));
        final tile = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: stacked ? 0 : 3,
            vertical: stacked ? 3 : 0,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: style.tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${hour}hr',
                  style: AppTextStyles.cardMeta.copyWith(
                    color: style.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value == null ? 'model is offline' : formatSensorValue(value),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 22,
                    color: style.text,
                  ),
                ),
              ],
            ),
          ),
        );
        return stacked ? tile : Expanded(child: tile);
      }).toList();
      if (stacked) return Column(children: tiles);
      final row = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: tiles,
      );
      return narrow ? IntrinsicHeight(child: row) : row;
    });

    final outlookPanel = Padding(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 8 : 14, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Outlook', style: AppTextStyles.bodyBold),
          const SizedBox(height: 4),
          _outlookRow('Threshold:', threshold),
          const SizedBox(height: 3),
          _outlookRow('Crosses in:', crossing, color: severity.text),
          const SizedBox(height: 6),
          Text(
            summary.explanation(selected),
            style: AppTextStyles.cardMeta.copyWith(height: 1.35),
          ),
        ],
      ),
    );

    if (narrow) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            trendPanel,
            const SizedBox(height: 8),
            horizonPanel,
            const SizedBox(height: 8),
            Divider(color: AppColors.cardBorder, height: 1),
            outlookPanel,
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 18, child: trendPanel),
          Expanded(
            flex: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: horizonPanel,
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: AppColors.cardBorder),
          Expanded(flex: 40, child: outlookPanel),
        ],
      )),
    );
  }

  /// Label and value sit together on one line, so there is no empty gap
  /// between them (and it wraps cleanly on narrow screens).
  Widget _outlookRow(String label, String value, {Color? color}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label ', style: AppTextStyles.cardMeta),
          TextSpan(
            text: value,
            style: AppTextStyles.bodyBold.copyWith(
              fontSize: 12,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
