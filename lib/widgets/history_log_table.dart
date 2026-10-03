import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'history_log_value.dart';

class HistoryLogTable extends StatelessWidget {
  final List<String> columns;
  final List<HistoryLogEntry> rows;

  const HistoryLogTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  int get _statusColumnIndex => columns.indexOf('Status');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamically compute comfortable table width based on column count
        final minCalculatedWidth = math.max(620.0, columns.length * 180.0);
        final tableWidth = math.max(minCalculatedWidth, constraints.maxWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.symmetric(
                      horizontal: BorderSide(color: AppColors.textSecondary),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (int c = 0; c < columns.length; c++)
                        Expanded(child: Center(child: _header(c))),
                    ],
                  ),
                ),

                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No logs yet.',
                        style: AppTextStyles.cardMeta,
                      ),
                    ),
                  )
                else
                  for (int r = 0; r < rows.length; r++)
                    Container(
                      height: 62,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: r.isOdd ? AppColors.tableStripe : null,
                        border: Border(
                          bottom: BorderSide(color: AppColors.textSecondary),
                        ),
                      ),
                      child: Row(
                        children: [
                          for (int c = 0; c < columns.length; c++)
                            Expanded(
                              child: c == _statusColumnIndex
                                  ? Align(
                                      alignment: Alignment.center,
                                      child: HistoryStatusBadge(
                                        status: rows[r].values[c],
                                      ),
                                    )
                                  : rows[r].ranges[c] != null
                                      ? Center(
                                          child: HistoryLogValue(
                                            value: rows[r].values[c],
                                            range: rows[r].ranges[c]!,
                                            showRange: false,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            rows[r].values[c],
                                            style: AppTextStyles.body,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                            ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(int index) {
    final range = rows.isEmpty ? null : rows.first.ranges[index];
    final parameter = switch (index) {
      2 => 'pH',
      3 => 'EC',
      4 => 'Temp',
      _ => '',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          columns[index],
          style: AppTextStyles.cardLabel,
          textAlign: TextAlign.center,
        ),
        if (range != null)
          Text(
            'Ideal $parameter Range: ${range.label}',
            style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}