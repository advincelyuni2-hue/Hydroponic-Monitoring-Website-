import 'package:flutter/material.dart';

import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import 'legend_dialog.dart';
import '../utils/responsive.dart';

class ForecastEvaluationTable extends StatefulWidget {
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
  State<ForecastEvaluationTable> createState() => _ForecastEvaluationTableState();
}

class _ForecastEvaluationTableState extends State<ForecastEvaluationTable> {
  final _infoTooltipKey = GlobalKey<TooltipState>();
  static const _explanation =
      'Intervention- and calibration-affected forecasts stay in the record but are excluded from model accuracy.';

  int _page = 0;
  int _rowsPerPage = 12;

  static const _statuses = [
    'evaluated', 'pending', 'intervened', 'calibration_excluded', 'missing_actual',
  ];
  static const _columns = [
    'Target time', 'Parameter', 'Predicted', 'Actual', 'Status', 'Logged action',
  ];

  @override
  void didUpdateWidget(covariant ForecastEvaluationTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedParameter != widget.selectedParameter ||
        oldWidget.selectedHorizon != widget.selectedHorizon) {
      _page = 0;
    }
    final count = _records.length;
    final lastPage = count == 0 ? 0 : (count - 1) ~/ _rowsPerPage;
    if (_page > lastPage) _page = lastPage;
  }

  List<ForecastEvaluationRecord> get _records => widget.evaluation.records
      .where((record) => widget.selectedParameter == 'Both' ||
          record.parameter == widget.selectedParameter.toLowerCase())
      .toList();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final records = _records;
    final visible = records.skip(_page * _rowsPerPage).take(_rowsPerPage).toList();
    return LayoutBuilder(builder: (context, constraints) {
      // Use cards for narrow windows and enlarged text, not a squeezed table.
      final cards = constraints.maxWidth < 820 ||
          MediaQuery.textScalerOf(context).scale(13) > 18;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(cards ? 16 : 20),
        decoration: AppDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) _mobileHeader(records) else _header(records),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 14),
            if (widget.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (widget.errorMessage != null)
              Text(widget.errorMessage!, style: AppTextStyles.cardMeta)
            else ...[
              if (isMobile)
                _mobileRecordInfo(records.length)
              else Text(
                'Showing ${records.length} records from the latest 500 forecasts '
                'for this horizon.',
                style: AppTextStyles.cardMeta,
              ),
              const SizedBox(height: 16),
              if (records.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text(
                    'No forecast records for this selection yet.',
                    style: AppTextStyles.cardMeta,
                  )),
                )
              else ...[
                if (cards)
                  Column(children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      _recordCard(visible[i]),
                      if (i < visible.length - 1) const SizedBox(height: 10),
                    ],
                  ])
                else
                  _desktopTable(visible),
                const SizedBox(height: 14),
                _pagination(records.length),
              ],
            ],
          ],
        ),
      );
    });
  }

  Widget _mobileHeader(List<ForecastEvaluationRecord> records) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(),
      const SizedBox(height: 12),
      if (!widget.isLoading && widget.errorMessage == null) ...[
        _mobileCounter('evaluated', records, featured: true),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
          final twoColumns = constraints.maxWidth >= 220 * scale;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in const [
                'pending', 'missing_actual',
                'calibration_excluded', 'intervened',
              ])
                SizedBox(
                  width: twoColumns
                      ? (constraints.maxWidth - 8) / 2 : constraints.maxWidth,
                  child: _mobileCounter(status, records),
                ),
            ],
          );
        }),
        const SizedBox(height: 12),
      ],
      LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final sideBySide = constraints.maxWidth >= 240 * scale;
        final width = sideBySide
            ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            SizedBox(width: width, child: _mobileFilter(
              'PARAMETER', const ['Both', 'pH', 'EC'],
              widget.selectedParameter, widget.onParameterChanged,
            )),
            SizedBox(width: width, child: _mobileFilter(
              'HORIZON', const ['4h', '8h', '12h'],
              '${widget.selectedHorizon}h',
              (value) => widget.onHorizonChanged(
                  int.parse(value.substring(0, value.length - 1))),
            )),
          ],
        );
      }),
    ],
  );

  Widget _mobileCounter(String status, List<ForecastEvaluationRecord> records,
      {bool featured = false}) {
    final label = Text(_statusLabel(status), style: AppTextStyles.cardMeta);
    final value = Text(
      '${records.where((r) => r.status == status).length}',
      style: AppTextStyles.bodyBold.copyWith(fontSize: featured ? 20 : 17),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: featured ? AppColors.statusCardGreen : AppColors.tableStripe,
        borderRadius: BorderRadius.circular(12),
      ),
      child: featured
          ? Row(children: [
              Expanded(child: label),
              const SizedBox(width: 8),
              Flexible(
                child: Align(alignment: Alignment.centerRight, child: value),
              ),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 2), value],
            ),
    );
  }

  Widget _mobileFilter(String label, List<String> values, String selected,
      ValueChanged<String> onSelected) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.cardMeta.copyWith(fontSize: 11)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.pillBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          for (final value in values)
            Expanded(child: Semantics(
              selected: value == selected,
              child: TextButton(
                onPressed: () => onSelected(value),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: value == selected
                      ? AppColors.primaryButton : Colors.transparent,
                  foregroundColor: value == selected
                      ? Colors.white : AppColors.pillText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  textStyle: AppTextStyles.cardMeta.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text(value, textAlign: TextAlign.center),
              ),
            )),
        ]),
      ),
    ],
  );

  Widget _mobileRecordInfo(int count) => LayoutBuilder(
    builder: (context, constraints) {
      final info = Text(
        'Showing $count records from the latest 500 forecasts for this horizon.',
        style: AppTextStyles.cardMeta,
      );
      final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
      if (constraints.maxWidth < 240 * scale) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            info,
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerRight, child: _legendButton()),
          ],
        );
      }
      return Row(children: [
        Expanded(child: info),
        const SizedBox(width: 8),
        _legendButton(),
      ]);
    },
  );

  Widget _header(List<ForecastEvaluationRecord> records) {
    final titleAndCounters = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _heading(),
        if (!widget.isLoading && widget.errorMessage == null)
          for (final status in _statuses)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.tableStripe,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: '${_statusLabel(status)}  ',
                    style: AppTextStyles.cardMeta),
                TextSpan(
                  text: '${records.where((r) => r.status == status).length}',
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                ),
              ])),
            ),
      ],
    );
    // Keep each group compact, putting spare desktop width between them.
    // Both groups still wrap naturally when the available width is smaller.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [titleAndCounters, _filters()],
      ),
    );
  }

  Widget _heading() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.accentGreen, width: 2)),
          ),
          child: Text('Predicted vs actual', style: AppTextStyles.sectionTitle),
        ),
      ),
      const SizedBox(width: 4),
      Tooltip(
        key: _infoTooltipKey,
        message: _explanation,
        triggerMode: TooltipTriggerMode.tap,
        child: IconButton(
          onPressed: () => _infoTooltipKey.currentState?.ensureTooltipVisible(),
          icon: Icon(Icons.info_outline, size: 16, color: AppColors.accentGreen),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ),
    ],
  );

  Widget _filters() => Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _filterGroup(
                  label: 'Parameter',
                  values: const ['Both', 'pH', 'EC'],
                  selected: widget.selectedParameter,
                  onSelected: widget.onParameterChanged,
                ),
                _filterGroup(
                  label: 'Forecast horizon',
                  values: const ['4h', '8h', '12h'],
                  selected: '${widget.selectedHorizon}h',
                  onSelected: (value) => widget.onHorizonChanged(
                      int.parse(value.substring(0, value.length - 1))),
                ),
                _legendButton(),
              ],
            );

  Widget _legendButton() => TextButton(
                  onPressed: _showLegend,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentGreen,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: AppTextStyles.cardMeta.copyWith(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 15),
                      SizedBox(width: 4),
                      Text('See legend'),
                    ],
                  ),
                );

  Widget _filterGroup({
    required String label,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) => Semantics(
    label: label,
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 2,
        runSpacing: 4,
        children: [
          for (final value in values)
            Semantics(
              selected: value == selected,
              child: TextButton(
                onPressed: () => onSelected(value),
                style: TextButton.styleFrom(
                  minimumSize: const Size(40, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  backgroundColor: value == selected
                      ? AppColors.primaryButton : Colors.transparent,
                  foregroundColor: value == selected
                      ? Colors.white : AppColors.pillText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  textStyle: AppTextStyles.cardMeta.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(value),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _desktopTable(List<ForecastEvaluationRecord> records) => Table(
    columnWidths: const {
      0: FlexColumnWidth(1.5),
      1: FlexColumnWidth(1),
      2: FlexColumnWidth(1),
      3: FlexColumnWidth(1),
      4: FlexColumnWidth(1.5),
      5: FlexColumnWidth(1.3),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: [
      TableRow(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder),
            bottom: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        children: [
          for (final column in _columns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Semantics(
                header: true,
                child: Text(column, textAlign: TextAlign.center, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
              ),
            ),
        ],
      ),
      for (var i = 0; i < records.length; i++)
        TableRow(
          decoration: BoxDecoration(
            color: i.isOdd ? AppColors.tableStripe : AppColors.cardBackground,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          children: [
            for (final cell in <Widget>[
              Text(records[i].targetLabel, style: AppTextStyles.bodySmall),
              Text(_parameter(records[i]), style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
              Text(_formatValue(records[i].predictedValue, records[i].parameter), style: AppTextStyles.bodySmall),
              Text(_actual(records[i]), style: AppTextStyles.bodySmall),
              Align(alignment: Alignment.center, child: _statusBadge(records[i].status)),
              Text(_action(records[i]), style: AppTextStyles.bodySmall),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: DefaultTextStyle.merge(
                  textAlign: TextAlign.center,
                  child: cell,
                ),
              ),
          ],
        ),
    ],
  );

  // Mirrors HistoryLogCards: time/status header, divider, two-column fields,
  // full-width action text, and a one-column fallback for large text.
  Widget _recordCard(ForecastEvaluationRecord record) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: AppDecorations.card(radius: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final time = _field('Target time', record.targetLabel);
          if (constraints.maxWidth < 260 ||
              MediaQuery.textScalerOf(context).scale(13) > 18) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [time, const SizedBox(height: 8), _statusBadge(record.status)],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: time),
              const SizedBox(width: 8),
              Flexible(child: Align(
                alignment: Alignment.topRight,
                child: _statusBadge(record.status),
              )),
            ],
          );
        }),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 260 &&
              MediaQuery.textScalerOf(context).scale(13) <= 18;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final field in <Widget>[
                _field('Parameter', _parameter(record)),
                _field('Predicted', _formatValue(record.predictedValue, record.parameter)),
                _field('Actual', _actual(record)),
              ])
                SizedBox(
                  width: twoColumns ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                  child: field,
                ),
              SizedBox(width: constraints.maxWidth, child: _field('Logged action', _action(record))),
            ],
          );
        }),
      ],
    ),
  );

  Widget _field(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: AppTextStyles.cardMeta),
      const SizedBox(height: 4),
      Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
    ],
  );

  Widget _pagination(int count) {
    final lastPage = (count - 1) ~/ _rowsPerPage;
    final end = ((_page + 1) * _rowsPerPage).clamp(0, count);
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Rows per page', style: AppTextStyles.cardMeta),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _rowsPerPage,
            style: AppTextStyles.bodySmall,
            underline: const SizedBox.shrink(),
            items: [for (final count in const [12, 24, 48])
              DropdownMenuItem(value: count, child: Text('$count'))],
            onChanged: (value) {
              if (value == null) return;
              setState(() { _rowsPerPage = value; _page = 0; });
            },
          ),
        ]),
        Text('${_page * _rowsPerPage + 1}–$end of $count', style: AppTextStyles.cardMeta),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'First page',
            onPressed: _page == 0 ? null : () => setState(() => _page = 0),
            icon: const Icon(Icons.first_page),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: _page == 0 ? null : () => setState(() => _page--),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: _page == lastPage ? null : () => setState(() => _page++),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'Last page',
            onPressed: _page == lastPage ? null : () => setState(() => _page = lastPage),
            icon: const Icon(Icons.last_page),
          ),
        ]),
      ],
    );
  }

  void _showLegend() => showDialog<void>(
    context: context,
    builder: (context) => LegendDialog(
      title: 'Evaluation status legend',
      entries: [
        for (final status in _statuses)
          LegendEntry(
            icon: _statusIcon(status),
            color: _statusColor(status),
            title: _statusLabel(status),
            subtitle: switch (status) {
              'evaluated' => 'Included in model accuracy evaluation.',
              'pending' => 'Awaiting evaluation against an actual reading.',
              'intervened' => 'Affected by a logged intervention; excluded from model accuracy.',
              'calibration_excluded' => 'Affected by calibration; excluded from model accuracy.',
              _ => 'No matching actual reading is available for evaluation.',
            },
          ),
      ],
    ),
  );

  String _parameter(ForecastEvaluationRecord record) => record.parameter == 'ph' ? 'pH' : record.parameter.toUpperCase();
  String _formatValue(double value, String parameter) => parameter == 'ec'
      ? '${value.toStringAsFixed(3)} mS/cm' : value.toStringAsFixed(3);
  String _actual(ForecastEvaluationRecord record) => record.actualValue == null
      ? '—' : _formatValue(record.actualValue!, record.parameter);

  String _action(ForecastEvaluationRecord record) =>
      record.actionType != null || record.actionTimeLabel != null
          ? [
              record.actionType ?? 'Action recorded',
              if (record.actionTimeLabel != null) record.actionTimeLabel!,
              if (record.status == 'pending') 'Awaiting actual reading',
              if (record.interventionCount > 1) '${record.interventionCount} actions total',
            ].join('\n')
          : '—';

  String _statusLabel(String status) => switch (status) {
    'evaluated' => 'Evaluated',
    'intervened' => 'Intervention excluded',
    'calibration_excluded' => 'Calibration excluded',
    'missing_actual' => 'Missing actual',
    _ => 'Pending',
  };

  Color _statusColor(String status) => switch (status) {
      'evaluated' => AppColors.accentGreen,
      'intervened' => AppColors.warningYellow,
      'calibration_excluded' => AppColors.warningYellow,
      'missing_actual' => AppColors.criticalRed,
      _ => AppColors.textSecondary,
    };

  IconData _statusIcon(String status) => switch (status) {
    'evaluated' => Icons.check_rounded,
    'pending' => Icons.schedule,
    _ => Icons.info_outline,
  };

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        TextSpan(children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                _statusIcon(status),
                size: 12,
                color: color,
              ),
            ),
          ),
          TextSpan(text: _statusLabel(status)),
        ]),
        style: AppTextStyles.cardMeta.copyWith(
          color: color, fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
