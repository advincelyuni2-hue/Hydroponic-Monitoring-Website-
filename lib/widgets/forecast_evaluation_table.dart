import 'package:flutter/material.dart';

import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class ForecastEvaluationTable extends StatelessWidget {
  final ModelEvaluation evaluation;
  final String selectedParameter;
  final int selectedHorizon;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onParameterChanged;
  final ValueChanged<int> onHorizonChanged;

  const ForecastEvaluationTable({
    super.key,
    required this.evaluation,
    required this.selectedParameter,
    required this.selectedHorizon,
    required this.isLoading,
    required this.errorMessage,
    required this.onParameterChanged,
    required this.onHorizonChanged,
  });

  @override
  Widget build(BuildContext context) {
    final records = evaluation.records
        .where((record) =>
            selectedParameter == 'Both' ||
            record.parameter == selectedParameter.toLowerCase())
        .toList();

    int count(String status) =>
        records.where((record) => record.status == status).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Predicted vs actual', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          Text(
            'Intervention- and calibration-affected forecasts stay in the record but are excluded from model accuracy.',
            style: AppTextStyles.cardMeta,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final parameter in const ['Both', 'pH', 'EC'])
                ChoiceChip(
                  label: Text(parameter),
                  selected: selectedParameter == parameter,
                  onSelected: (_) => onParameterChanged(parameter),
                  selectedColor: AppColors.primaryButton,
                  labelStyle: TextStyle(
                    color: selectedParameter == parameter
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              const SizedBox(width: 8),
              for (final hours in const [4, 8, 12])
                ChoiceChip(
                  label: Text('${hours}h'),
                  selected: selectedHorizon == hours,
                  onSelected: (_) => onHorizonChanged(hours),
                  selectedColor: AppColors.primaryButton,
                  labelStyle: TextStyle(
                    color: selectedHorizon == hours
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Text(errorMessage!, style: AppTextStyles.cardMeta)
          else ...[
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _summary('Evaluated', count('evaluated')),
                _summary('Pending', count('pending')),
                _summary('Intervention excluded', count('intervened')),
                _summary('Calibration excluded', count('calibration_excluded')),
                _summary('Missing actual', count('missing_actual')),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Showing ${records.length} records from the latest 500 forecasts '
              'for this horizon.',
              style: AppTextStyles.cardMeta,
            ),
            const SizedBox(height: 16),
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No forecast records for this selection yet.',
                      style: AppTextStyles.cardMeta),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1120,
                  child: PaginatedDataTable(
                    key: ValueKey('$selectedParameter-$selectedHorizon'),
                    showCheckboxColumn: false,
                    rowsPerPage: 12,
                    availableRowsPerPage: const [12, 24, 48],
                    headingRowHeight: 40,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 68,
                    columnSpacing: 22,
                    columns: const [
                      DataColumn(label: Text('Target time')),
                      DataColumn(label: Text('Parameter')),
                      DataColumn(label: Text('Predicted')),
                      DataColumn(label: Text('Actual')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Logged action')),
                    ],
                    source: _ForecastRecordSource(records),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _summary(String label, int count) => Text(
        '$label: $count',
        style: AppTextStyles.cardMeta.copyWith(fontWeight: FontWeight.w600),
      );
}

class _ForecastRecordSource extends DataTableSource {
  final List<ForecastEvaluationRecord> records;

  _ForecastRecordSource(this.records);

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= records.length) return null;
    final record = records[index];
    final action = record.actionType != null || record.actionTimeLabel != null
        ? [
            record.actionType ?? 'Action recorded',
            if (record.actionTimeLabel != null) record.actionTimeLabel!,
            if (record.status == 'pending') 'Awaiting actual reading',
            if (record.interventionCount > 1)
              '${record.interventionCount} actions total',
          ].join('\n')
        : '—';
    return DataRow.byIndex(index: index, cells: [
      DataCell(Text(record.targetLabel)),
      DataCell(Text(record.parameter.toUpperCase())),
      DataCell(Text(_formatValue(record.predictedValue, record.parameter))),
      DataCell(Text(record.actualValue == null
          ? '—'
          : _formatValue(record.actualValue!, record.parameter))),
      DataCell(_statusLabel(record.status)),
      DataCell(Text(action)),
    ]);
  }

  String _formatValue(double value, String parameter) => parameter == 'ec'
      ? '${value.toStringAsFixed(3)} mS/cm'
      : value.toStringAsFixed(3);

  Widget _statusLabel(String status) {
    final label = switch (status) {
      'evaluated' => 'Evaluated',
      'intervened' => 'Intervened',
      'calibration_excluded' => 'Calibration excluded',
      'missing_actual' => 'Missing actual',
      _ => 'Pending',
    };
    final color = switch (status) {
      'evaluated' => AppColors.accentGreen,
      'intervened' => AppColors.warningYellow,
      _ => AppColors.textSecondary,
    };
    return Text(label, style: AppTextStyles.cardMeta.copyWith(color: color));
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => records.length;

  @override
  int get selectedRowCount => 0;
}
