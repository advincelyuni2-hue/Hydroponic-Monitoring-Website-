import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class ParameterConfigCard extends StatelessWidget {
  final RangeValues phRange;
  final RangeValues ecRange;
  final ValueChanged<RangeValues> onPhChanged;
  final ValueChanged<RangeValues> onEcChanged;
  final VoidCallback onSave;
  final VoidCallback onRevert;

  const ParameterConfigCard({
    super.key,
    required this.phRange,
    required this.ecRange,
    required this.onPhChanged,
    required this.onEcChanged,
    required this.onSave,
    required this.onRevert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('pH / EC Parameter Configuration',
              style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(
            'Selected values are stable. Up to 0.5 outside either limit is a warning; beyond that is critical.',
            style: AppTextStyles.cardMeta,
          ),
          const SizedBox(height: 16),
          // pH Range Box
          _rangeBox(
            label: 'pH Setpoint Range',
            unit: 'pH',
            rangeValues: phRange,
            minLimit: 4.0,
            maxLimit: 9.0,
            backgroundColor: AppColors.calloutBackground,
            activeColor: AppColors.primaryButton,
            onChanged: onPhChanged,
          ),
          const SizedBox(height: 16),
          // EC Range Box
          _rangeBox(
            label: 'EC Setpoint Range',
            unit: 'mS/cm',
            rangeValues: ecRange,
            minLimit: 0.0,
            maxLimit: 3.0,
            backgroundColor: AppColors.calloutBackground,
            activeColor: AppColors.primaryButton,
            onChanged: onEcChanged,
          ),
          const SizedBox(height: 20),
          // Action Pill Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Save configuration',
                      style: AppTextStyles.button.copyWith(fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: onRevert,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryButton,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Revert',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 13,
                        color: AppColors.primaryButton,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeBox({
    required String label,
    required String unit,
    required RangeValues rangeValues,
    required double minLimit,
    required double maxLimit,
    required Color backgroundColor,
    required Color activeColor,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
              Text(
                'Ideal: ${rangeValues.start.toStringAsFixed(6)} - ${rangeValues.end.toStringAsFixed(6)} $unit',
                style: AppTextStyles.cardMeta.copyWith(
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: activeColor.withValues(alpha: 0.25),
              thumbColor: activeColor,
              trackHeight: 3,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 7,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: RangeSlider(
              values: rangeValues,
              min: minLimit,
              max: maxLimit,
              divisions: ((maxLimit - minLimit) * 10).round(),
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min Limit: ${minLimit.toStringAsFixed(6)} $unit',
                style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
              ),
              Text(
                'Max Limit: ${maxLimit.toStringAsFixed(6)} $unit',
                style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
