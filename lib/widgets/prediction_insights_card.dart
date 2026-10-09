import 'package:flutter/material.dart';
import '../screens/notifications_screen.dart';
import '../models/forecasting_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_mode_controller.dart';
import '../theme/forecast_severity_style.dart';
import '../models/forecast_insight_summary.dart';
import '../services/app_state.dart';
import '../utils/sensor_value_format.dart';

class PredictionInsightsCard extends StatelessWidget {
  final PredictionInsightDetail detail;
  final List<ForecastingChartPoint> forecastPoints;
  final double currentPh;
  final double currentEc;
  final bool showParamSelector;
  final String? selectedInsightParam;
  final ValueChanged<String>? onInsightParamChanged;

  const PredictionInsightsCard({
    super.key,
    required this.detail,
    required this.forecastPoints,
    required this.currentPh,
    required this.currentEc,
    this.showParamSelector = false,
    this.selectedInsightParam,
    this.onInsightParamChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appThemeMode,
      builder: (context, _) => ValueListenableBuilder<ParameterRangeConfig>(
        valueListenable: appParameterRanges,
        builder: (context, ranges, _) => _content(context, ranges),
      ),
    );
  }

  Widget _content(BuildContext context, ParameterRangeConfig ranges) {
    final isPh = detail.statusLabel.contains('pH');
    final parameter = isPh ? 'pH' : 'EC';
    final summary = ForecastInsightSummary(
      forecast: forecastPoints,
      minimum: isPh ? ranges.phMin : ranges.ecMin,
      maximum: isPh ? ranges.phMax : ranges.ecMax,
    );
    final severity = ForecastSeverityStyle(summary.severity);
    final icon = summary.trend == 'Rising'
        ? Icons.trending_up
        : summary.trend == 'Falling'
            ? Icons.trending_down
            : Icons.trending_flat;
    final explanation = summary.explanation(parameter);
    final threshold = summary.thresholdLabel(unit: isPh ? '' : 'mS/cm');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final title =
                Text('Prediction Insights', style: AppTextStyles.sectionTitle);
            final selector = showParamSelector && onInsightParamChanged != null;
            if (constraints.maxWidth < 320 ||
                MediaQuery.textScalerOf(context).scale(14) > 18) {
              return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [title, if (selector) _buildParamPill()]);
            }
            return Row(children: [
              Expanded(child: title),
              if (selector) _buildParamPill()
            ]);
          }),
          _divider(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: severity.tint,
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: severity.text, width: 4)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: severity.text),
                    Text('$parameter Trend', style: AppTextStyles.bodyBold),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: severity.tint,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(summary.trend,
                          style: AppTextStyles.cardMeta
                              .copyWith(color: severity.text)),
                    ),
                  ]),
              const SizedBox(height: 6),
              Text(explanation,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textPrimary)),
            ]),
          ),
          _divider(),
          Text('Forecast', style: AppTextStyles.bodyBold),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final stacked = constraints.maxWidth < 260 ||
                MediaQuery.textScalerOf(context).scale(14) > 21;
            final tiles = [4, 8, 12].map((hour) {
              final value = summary.valueAt(hour);
              final style = ForecastSeverityStyle(summary.severityAt(hour));
              final tile = Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                    color: style.tint, borderRadius: BorderRadius.circular(10)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${hour}hr',
                      style:
                          AppTextStyles.cardMeta.copyWith(color: style.text)),
                  const SizedBox(height: 4),
                  Text(
                      value == null
                          ? 'model is offline'
                          : formatSensorValue(value),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyBold
                          .copyWith(fontSize: 14, color: style.text)),
                  if (!isPh) Text('mS/cm', style: AppTextStyles.cardMeta),
                ]),
              );
              return stacked
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 6), child: tile)
                  : Expanded(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: tile));
            }).toList();
            return stacked
                ? Column(children: tiles)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: tiles);
          }),
          _divider(),
          Text('Outlook', style: AppTextStyles.bodyBold),
          const SizedBox(height: 6),
          _fact('Threshold', threshold),
          _fact('Crosses in', summary.crossingLabel),
          _divider(),
          Text('Contributing factors', style: AppTextStyles.bodyBold),
          const SizedBox(height: 6),
          _fact('Temperature',
              detail.temperature.isEmpty ? 'Unavailable' : detail.temperature),
          _fact(isPh ? 'EC level' : 'pH level',
              '${formatSensorValue(isPh ? currentEc : currentPh)}${isPh ? ' mS/cm' : ''}'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.calloutBackground,
                borderRadius: BorderRadius.circular(10)),
            child: Text(
                detail.calloutText.trim().isEmpty
                    ? 'Review the forecast alongside recent sensor readings.'
                    : detail.calloutText,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 12),
          // Updated pill button matching the Dismiss button layout
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen())),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentGreen,
                side: BorderSide(color: AppColors.accentGreen, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              label: Text(
                'View recent notifications',
                textAlign: TextAlign.center,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.accentGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: AppColors.cardBorder));

  Widget _fact(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text('$label:', style: AppTextStyles.cardMeta),
              Text(value,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textPrimary))
            ]),
      );

  Widget _buildParamPill() {
    final options = ['pH', 'EC'];
    final activeParam = selectedInsightParam ?? 'pH';

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((p) {
          final isSelected = activeParam == p;
          return GestureDetector(
            onTap: () => onInsightParamChanged?.call(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primaryButton : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.pillText,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
