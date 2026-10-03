import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'history_log_value.dart';

class HistoryLogTable extends StatelessWidget {
  final List<String> columns;
  final List<HistoryLogEntry> rows;
  final String selectedTab;
  final bool isAdmin;
  final bool isSelectionMode;
  final Set<int> selectedIndices;
  final ValueChanged<bool?>? onSelectAll;
  final ValueChanged<int>? onToggleRow;
  final ValueChanged<int>? onDeleteRow;
  final ValueChanged<int>? onEditRow;

  const HistoryLogTable({
    super.key,
    required this.columns,
    required this.rows,
    this.selectedTab = 'Sensor logs',
    this.isAdmin = false,
    this.isSelectionMode = false,
    this.selectedIndices = const {},
    this.onSelectAll,
    this.onToggleRow,
    this.onDeleteRow,
    this.onEditRow,
  });

  int get _statusColumnIndex => columns.indexOf('Status');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double colWidthMultiplier = columns.length * 170.0;
        if (isSelectionMode) colWidthMultiplier += 80;
        if (isAdmin) colWidthMultiplier += 100;

        final minCalculatedWidth = math.max(620.0, colWidthMultiplier);
        final tableWidth =
            math.max(minCalculatedWidth, constraints.maxWidth);

        String emptyText = 'No logs yet.';
        if (selectedTab == 'Reports logs') {
          emptyText = 'No report logs documented yet';
        } else if (selectedTab == 'Calibration logs') {
          emptyText = 'No calibration logs documented yet';
        }

        final bool allSelected =
            rows.isNotEmpty && selectedIndices.length == rows.length;

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
                      if (isSelectionMode)
                        SizedBox(
                          width: 80,
                          child: InkWell(
                            onTap: () => onSelectAll?.call(!allSelected),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Text(
                                allSelected ? 'Deselect' : 'Select All',
                                style: AppTextStyles.cardMeta.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryButton,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      for (int c = 0; c < columns.length; c++)
                        Expanded(child: Center(child: _header(c))),
                      if (isAdmin && !isSelectionMode)
                        SizedBox(
                          width: 90,
                          child: Center(
                            child: Text(
                              'Actions',
                              style: AppTextStyles.cardLabel,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        emptyText,
                        style: AppTextStyles.cardMeta.copyWith(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
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
                        color: selectedIndices.contains(r)
                            ? AppColors.primaryButton.withValues(alpha: 0.08)
                            : (r.isOdd ? AppColors.tableStripe : null),
                        border: Border(
                          bottom: BorderSide(color: AppColors.textSecondary),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isSelectionMode)
                            SizedBox(
                              width: 80,
                              child: Center(
                                child: Checkbox(
                                  value: selectedIndices.contains(r),
                                  activeColor: AppColors.primaryButton,
                                  onChanged: (_) => onToggleRow?.call(r),
                                ),
                              ),
                            ),
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
                          if (isAdmin && !isSelectionMode)
                            SizedBox(
                              width: 90,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined,
                                        size: 18, color: AppColors.textPrimary),
                                    tooltip: 'Edit log entry',
                                    onPressed: () => onEditRow?.call(r),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.alertText),
                                    tooltip: 'Delete log entry',
                                    onPressed: () => onDeleteRow?.call(r),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
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
    final colName = columns[index];

    String? subtitle;
    if (colName == 'Average pH') {
      subtitle = 'Ideal pH Range: 5.50–6.50';
    } else if (colName == 'Average EC') {
      subtitle = 'Ideal EC Range: 1.20–1.80 mS/cm';
    } else if (colName == 'Average Temp') {
      subtitle = 'Ideal Temp Range: 18.0–24.0 °C';
    } else if (colName == 'Critical Alerts') {
      subtitle = 'Total count recorded';
    } else if (range != null) {
      subtitle = 'Ideal Range: ${range.label}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          colName,
          style: AppTextStyles.cardLabel,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}