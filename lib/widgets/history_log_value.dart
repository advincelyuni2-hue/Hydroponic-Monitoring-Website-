import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import 'legend_dialog.dart';
import '../theme/app_text_styles.dart';
import '../utils/status_style.dart';
import '../services/app_state.dart';

String historyRangeLabel(HistoryValueRange range) {
  if (range.unit == '°C') {
    return formatTempRange(range.minimum, range.maximum);
  }
  return range.label;
}

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
    IconData icon;
    Color iconColor;
    String tooltipMsg;

    if (range.isCriticalHigh) {
      icon = Icons.arrow_upward_rounded;
      iconColor = const Color(0xFFDC2626);
      tooltipMsg = 'Above ideal range (Critical)';
    } else if (range.isCriticalLow) {
      icon = Icons.arrow_downward_rounded;
      iconColor = const Color(0xFFDC2626);
      tooltipMsg = 'Below ideal range (Critical)';
    } else if (range.isHigh) {
      icon = Icons.arrow_upward_rounded;
      iconColor = const Color(0xFFE79A08);
      tooltipMsg = 'Above stable range (Warning)';
    } else if (range.isLow) {
      icon = Icons.arrow_downward_rounded;
      iconColor = const Color(0xFFE79A08);
      tooltipMsg = 'Below stable range (Warning)';
    } else {
      icon = Icons.arrow_forward_rounded;
      iconColor = const Color(0xFF16A34A); // Green for stable
      tooltipMsg = 'Within optimal bounds (Stable)';
    }

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
                range.unit == '°C' ? formatTempText(value) : value,
                style: AppTextStyles.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            Tooltip(
              message: tooltipMsg,
              child: Icon(icon, size: 17, color: iconColor),
            ),
          ],
        ),
        if (showRange) ...[
          const SizedBox(height: 2),
          Text(
            'Ideal: ${historyRangeLabel(range)}',
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

/// Interactive "See legend" dialog popup.
class HistoryLogLegend {
  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const LegendDialog(
        title: 'Indicator Legend',
        entries: [
          LegendEntry(
            icon: Icons.arrow_upward_rounded,
            color: Color(0xFFDC2626),
            title: 'High Critical Breach',
            subtitle: 'Reading is above maximum ideal threshold',
          ),
          LegendEntry(
            icon: Icons.arrow_downward_rounded,
            color: Color(0xFFDC2626),
            title: 'Low Critical Breach',
            subtitle: 'Reading is below minimum ideal threshold',
          ),
          LegendEntry(
            icon: Icons.arrow_forward_rounded,
            color: Color(0xFF16A34A),
            title: 'Stable / In Range',
            subtitle: 'Parameter is within optimal operating bounds',
          ),
        ],
      ),
    );
  }
}
