import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
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
    IconData icon;
    Color iconColor;
    String tooltipMsg;

    if (range.isHigh) {
      icon = Icons.arrow_upward_rounded;
      iconColor = const Color(0xFFDC2626); // Red for critical high
      tooltipMsg = 'Above ideal range (Critical)';
    } else if (range.isLow) {
      icon = Icons.arrow_downward_rounded;
      iconColor = const Color(0xFFDC2626); // Red for critical low
      tooltipMsg = 'Below ideal range (Critical)';
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
                value,
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

/// Interactive "See legend" dialog popup
class HistoryLogLegend {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: AppDecorations.card(radius: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Indicator Legend', style: AppTextStyles.sectionTitle),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 16),
              _buildLegendRow(
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFDC2626),
                title: 'High Critical Breach',
                subtitle: 'Reading is above maximum ideal threshold',
              ),
              const SizedBox(height: 12),
              _buildLegendRow(
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFFDC2626),
                title: 'Low Critical Breach',
                subtitle: 'Reading is below minimum ideal threshold',
              ),
              const SizedBox(height: 12),
              _buildLegendRow(
                icon: Icons.arrow_forward_rounded,
                color: const Color(0xFF16A34A),
                title: 'Stable / In Range',
                subtitle: 'Parameter is within optimal operating bounds',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildLegendRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
              ),
              Text(
                subtitle,
                style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}