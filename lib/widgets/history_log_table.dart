import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/monitoring_models.dart';
import '../utils/status_style.dart';

class HistoryLogTable extends StatelessWidget {
  final List<String> columns;
  final List<HistoryLogEntry> rows;

  const HistoryLogTable({super.key, required this.columns, required this.rows});

  int get _statusColumnIndex => columns.indexOf('Status');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            for (final column in columns)
              Expanded(
                child: Text(column, style: AppTextStyles.cardLabel),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.cardBorder),

        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('No logs yet.', style: AppTextStyles.cardMeta),
            ),
          )
        else
          for (int r = 0; r < rows.length; r++)
            Container(
              color: r.isOdd ? AppColors.tableStripe : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  for (int c = 0; c < columns.length; c++)
                    Expanded(
                      child: c == _statusColumnIndex
                          ? _StatusPill(status: rows[r].values[c])
                          : Text(
                              rows[r].values[c],
                              style: AppTextStyles.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: StatusStyle.background(status),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          status,
          style: AppTextStyles.cardMeta.copyWith(
            fontWeight: FontWeight.w600,
            color: StatusStyle.text(status),
          ),
        ),
      ),
    );
  }
}