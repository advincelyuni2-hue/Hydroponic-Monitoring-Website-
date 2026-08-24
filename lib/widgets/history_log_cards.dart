import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/monitoring_models.dart';
import '../utils/status_style.dart';

class HistoryLogCards extends StatelessWidget {
  final List<String> columns;
  final List<HistoryLogEntry> rows;

  const HistoryLogCards({super.key, required this.columns, required this.rows});

  int get _statusColumnIndex => columns.indexOf('Status');

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('No logs yet.', style: AppTextStyles.cardMeta),
        ),
      );
    }

    return Column(
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          _LogCard(columns: columns, values: rows[r].values, statusIndex: _statusColumnIndex),
          if (r != rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  final List<String> columns;
  final List<String> values;
  final int statusIndex;

  const _LogCard({required this.columns, required this.values, required this.statusIndex});

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
                i == statusIndex
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: StatusStyle.background(values[i]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          values[i],
                          style: AppTextStyles.cardMeta.copyWith(
                            fontWeight: FontWeight.w600,
                            color: StatusStyle.text(values[i]),
                          ),
                        ),
                      )
                    : Flexible(
                        child: Text(
                          values[i],
                          style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
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
