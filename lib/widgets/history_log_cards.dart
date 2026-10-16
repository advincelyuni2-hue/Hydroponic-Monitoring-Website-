import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/monitoring_models.dart';
import 'history_log_value.dart';

class HistoryLogCards extends StatelessWidget {
  final List<String> columns;
  final List<HistoryLogEntry> rows;
  final String selectedTab;

  const HistoryLogCards({
    super.key,
    required this.columns,
    required this.rows,
    this.selectedTab = 'Sensor logs',
  });

  int get _statusColumnIndex => columns.indexOf('Status');

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            selectedTab == 'Intervention logs'
                ? 'No interventions recorded for this period'
                : 'No logs yet.',
            style: AppTextStyles.cardMeta,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          _LogCard(
            columns: columns,
            entry: rows[r],
            statusIndex: _statusColumnIndex,
            isSensorLog: selectedTab == 'Sensor logs',
          ),
          if (r != rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  final List<String> columns;
  final HistoryLogEntry entry;
  final int statusIndex;
  final bool isSensorLog;

  const _LogCard({
    required this.columns,
    required this.entry,
    required this.statusIndex,
    required this.isSensorLog,
  });

  Widget _field(int index) {
    final range = entry.ranges[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(columns[index], style: AppTextStyles.cardMeta),
        const SizedBox(height: 4),
        if (range != null)
          HistoryLogValue(value: entry.values[index], range: range)
        else
          Text(entry.values[index],
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerFields = [
      for (var i = 0; i < columns.length; i++)
        if (columns[i] == 'Time' || columns[i] == 'Date') i,
    ];
    final detailFields = [
      for (var i = 0; i < columns.length; i++)
        if (!headerFields.contains(i) && i != statusIndex) i,
    ];
    final hasHeader = headerFields.isNotEmpty || statusIndex >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.card(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final index in headerFields) ...[
                        if (index != headerFields.first)
                          const SizedBox(height: 4),
                        Text(entry.values[index],
                            style: columns[index] == 'Time'
                                ? AppTextStyles.bodyBold.copyWith(fontSize: 13)
                                : AppTextStyles.cardMeta),
                      ],
                    ],
                  ),
                ),
                if (statusIndex >= 0) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: HistoryStatusBadge(status: entry.values[statusIndex]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
          if (isSensorLog)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final index in detailFields) ...[
                  if (index != detailFields.first) const SizedBox(width: 10),
                  Expanded(child: _field(index)),
                ],
              ],
            )
          else
            LayoutBuilder(builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 260 &&
                  MediaQuery.textScalerOf(context).scale(13) <= 18;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final index in detailFields)
                    SizedBox(
                      width: twoColumns &&
                              columns[index].toLowerCase() != 'notes' &&
                              columns[index].toLowerCase() != 'action taken'
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: _field(index),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}
