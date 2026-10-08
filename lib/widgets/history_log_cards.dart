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

  const _LogCard({
    required this.columns,
    required this.entry,
    required this.statusIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.card(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < columns.length; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(columns[i], style: AppTextStyles.cardMeta),
                const SizedBox(width: 12),
                if (i == statusIndex)
                  HistoryStatusBadge(status: entry.values[i])
                else
                  Flexible(
                    child: entry.ranges[i] != null
                        ? HistoryLogValue(
                            value: entry.values[i],
                            range: entry.ranges[i]!,
                            alignRight: true,
                          )
                        : Tooltip(
                            message: entry.values[i],
                            child: Text(
                              entry.values[i],
                              style:
                                  AppTextStyles.bodyBold.copyWith(fontSize: 13),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
              ],
            ),
            if (i != columns.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
