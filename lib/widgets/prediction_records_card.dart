import 'package:flutter/material.dart';

import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// A presentation-only summary of the records already loaded for Reports.
class PredictionRecordsCard extends StatelessWidget {
  const PredictionRecordsCard({
    super.key,
    required this.evaluation,
    required this.selectedParameter,
    required this.selectedHorizon,
    required this.isLoading,
    required this.errorMessage,
    required this.onViewTable,
  });

  final ModelEvaluation evaluation;
  final String selectedParameter;
  final int selectedHorizon;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onViewTable;

  @override
  Widget build(BuildContext context) {
    final records = evaluation.records.where((record) =>
        selectedParameter == 'Both' ||
        record.parameter == selectedParameter.toLowerCase()).toList();
    final statuses = [
      ('evaluated', 'Evaluated', AppColors.accentGreen),
      ('pending', 'Pending', AppColors.textSecondary),
      ('calibration_excluded', 'Calibration excluded', AppColors.warningYellow),
      ('missing_actual', 'Missing actual', AppColors.criticalRed),
      ('intervened', 'Intervention excluded', AppColors.accentTeal),
    ];
    final counts = {
      for (final status in statuses)
        status.$1: records.where((record) => record.status == status.$1).length,
    };
    final accuracy = evaluation.accuracyFor(selectedParameter);
    final total = records.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: 4),
          Text('Predicted vs actual', style: AppTextStyles.cardMeta),
          if (selectedParameter != 'Both') ...[
            const SizedBox(height: 4),
            Text('$selectedParameter forecasts', style: AppTextStyles.cardMeta),
          ],
          const SizedBox(height: 8),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (total == 0)
            Text(errorMessage ?? 'No forecast records for this selection yet.',
                style: AppTextStyles.cardMeta)
          else ...[
            LayoutBuilder(builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
              final sideBySide = constraints.maxWidth >= 240 * scale;
              final tileWidth = sideBySide
                  ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(width: tileWidth, child: _metric(
                    'EVALUATED', '${counts['evaluated']}', 'of $total forecasts',
                    color: AppColors.accentGreen,
                  )),
                  SizedBox(width: tileWidth, child: _metric(
                    'ACCURACY', accuracy == null ? '—' : '${accuracy.toStringAsFixed(1)}%',
                    accuracy == null ? 'No eligible comparisons' : '${selectedHorizon}h forecasts',
                  )),
                ],
              );
            }),
            const SizedBox(height: 8),
            Text('RECORD BREAKDOWN', style: AppTextStyles.cardMeta.copyWith(
                fontWeight: FontWeight.w600, letterSpacing: .8)),
            const SizedBox(height: 8),
            Semantics(
              label: 'Record breakdown: ${statuses.map((s) => '${s.$2}: ${counts[s.$1]}').join(', ')}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 12,
                  child: Row(children: [
                    for (final status in statuses)
                      if (counts[status.$1]! > 0)
                        Expanded(
                          flex: counts[status.$1]!,
                          child: ColoredBox(color: status.$3,
                              child: const SizedBox.expand()),
                        ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final status in statuses)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: status.$3, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(status.$2, style: AppTextStyles.cardMeta)),
                  const SizedBox(width: 8),
                  Text('${counts[status.$1]}',
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                ]),
              ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewTable,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentGreen,
                side: BorderSide(color: AppColors.accentGreen),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.table_chart_outlined, size: 17),
                  Text('View table', style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 13, color: AppColors.accentGreen)),
                  const Icon(Icons.arrow_forward, size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => Text(
        'Prediction Records',
        style: AppTextStyles.sectionTitle.copyWith(
          fontSize: Responsive.isDesktop(context) ? 16 : 18,
        ),
      );

  Widget _metric(String label, String value, String detail, {Color? color}) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.tableStripe,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.cardMeta.copyWith(
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .8)),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 24, color: color ?? AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(detail, style: AppTextStyles.cardMeta.copyWith(fontSize: 11)),
          ],
        ),
      );
}