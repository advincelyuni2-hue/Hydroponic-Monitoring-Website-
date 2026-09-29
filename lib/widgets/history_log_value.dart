import 'package:flutter/material.dart';

import '../models/monitoring_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/status_style.dart';

class HistoryLogValue extends StatelessWidget {
  final String value;
  final HistoryValueRange range;
  final bool alignRight;
  final bool showRange;

  const HistoryLogValue({
    super.key,
    required this.value,
    required this.range,
    this.alignRight = false,
    this.showRange = true,
  });

  @override
  Widget build(BuildContext context) {
    final direction = range.isHigh
        ? Icons.arrow_upward_rounded
        : range.isLow
            ? Icons.arrow_downward_rounded
            : null;
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                style: AppTextStyles.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (direction != null) ...[
              const SizedBox(width: 5),
              Tooltip(
                message:
                    range.isHigh ? 'Above ideal range' : 'Below ideal range',
                child: Icon(direction, size: 17, color: AppColors.textPrimary),
              ),
            ],
          ],
        ),
        if (showRange) ...[
          const SizedBox(height: 2),
          Text(
            'Ideal: ${range.label}',
            style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}

class HistoryStatusBadge extends StatelessWidget {
  final String status;

  const HistoryStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final icon = switch (normalized) {
      'critical' || 'failed' => Icons.error_outline_rounded,
      'warning' => Icons.warning_amber_rounded,
      'stable' || 'normal' || 'success' => Icons.check_circle_outline_rounded,
      _ => Icons.info_outline_rounded,
    };
    final label = normalized == 'normal' ? 'Stable' : status;
    final color = StatusStyle.text(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: StatusStyle.background(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.cardMeta.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
