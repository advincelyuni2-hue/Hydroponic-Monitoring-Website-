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
  /// Height of the wide (desktop) body strip. Lower it to shrink the card more.
  static const double _bodyHeight = 116;

  String _selected = 'pH';

  bool get _isPh => _selected == 'pH';

  List<ForecastPoint> get _points =>
      _isPh ? widget.phForecast : widget.ecForecast;

  ForecastInsightSummary get _summary {
    final ranges = appParameterRanges.value;
    return ForecastInsightSummary(
      forecast: _points
          .map((p) => forecasting.ForecastingChartPoint(
              hour: p.hour,
              value: p.value,
              isPredicted: p.isPredicted,
              isFallback: p.isFallback))
          .toList(),
      minimum: _isPh ? ranges.phMin : ranges.ecMin,
      maximum: _isPh ? ranges.phMax : ranges.ecMax,
    );
  }

  bool get _modelOffline =>
      widget.isOffline ||
      widget.isCalibrating ||
      widget.forecastIssue != null ||
      _summary.points.isEmpty;

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: AppDecorations.card(radius: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 820 ||
              MediaQuery.textScalerOf(context).scale(14) > 16.8;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(narrow),
              const SizedBox(height: 8),
              if (_modelOffline)
                Container(
                  width: double.infinity,
                  height: narrow ? null : _bodyHeight,
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Center(
                    child: Text(
                      'model is offline',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                _forecastBody(narrow),
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
          child: Text(
            'Latest Forecast Insight',
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
      child: const Text('View forecast details'),
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
          Row(
            children: [
              toggle,
              const Spacer(),
              Flexible(child: details),
            ],
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

  Widget _forecastBody(bool narrow) {
    final summary = _summary;
    final threshold = summary.thresholdLabel(unit: _isPh ? '' : 'mS/cm');
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
          Text('$_selected, next 12h', style: AppTextStyles.cardMeta),
        ],
      ),
    );

    final horizonPanel = LayoutBuilder(builder: (context, constraints) {
      final stacked = narrow &&
          constraints.maxWidth <
              270 * MediaQuery.textScalerOf(context).scale(14) / 14;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
          Flexible(
            flex: narrow ? 0 : 1,
            child: Text(
              summary.explanation(_selected),
              style: AppTextStyles.cardMeta.copyWith(height: 1.35),
              maxLines: narrow ? null : 2,
              overflow: narrow ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
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
      height: _bodyHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 20, child: trendPanel),
          Expanded(
            flex: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: horizonPanel,
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: AppColors.cardBorder),
          Expanded(flex: 34, child: outlookPanel),
        ],
      ),
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
