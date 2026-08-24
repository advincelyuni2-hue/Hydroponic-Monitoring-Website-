import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../models/monitoring_models.dart';
import 'live_pulse_dot.dart';

class ParameterStatusCard extends StatelessWidget {
  final ParameterStatus data;
  final Color backgroundColor;

  const ParameterStatusCard({
    super.key,
    required this.data,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SizedBox(width: double.infinity) so spaceBetween actually has
          // room to spread the label and value apart, and Wrap so long
          // text drops to a second line on narrow phones instead of
          // clipping.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(data.label, style: AppTextStyles.cardLabel),
                Text(
                  'Current value: ${data.currentValue}${data.unit.isNotEmpty ? ' ${data.unit}' : ''} →',
                  style: AppTextStyles.cardValue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Ideal range: ${data.idealRange}', style: AppTextStyles.cardMeta),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LivePulseDot(size: 6),
                    const SizedBox(width: 6),
                    Text('Last updated: ${data.lastUpdated}', style: AppTextStyles.cardMeta),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
