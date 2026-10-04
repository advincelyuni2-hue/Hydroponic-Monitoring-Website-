import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
<<<<<<< HEAD
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
=======
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

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
<<<<<<< HEAD
=======
      width: double.infinity,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          Text('Parameter configuration', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 16),

          // pH Range Box (Light Green Background)
          _rangeBox(
            label: 'pH range',
            rangeValues: phRange,
            minLimit: 4.0,
            maxLimit: 8.0,
            backgroundColor: AppColors.statusCardGreen,
            activeColor: AppColors.primaryButton,
            onChanged: onPhChanged,
          ),
          const SizedBox(height: 12),

          // EC Range Box (Light Green Background)
          _rangeBox(
            label: 'EC range',
            rangeValues: ecRange,
            minLimit: 3.0,
            maxLimit: 8.0,
            backgroundColor: AppColors.statusCardGreen,
=======
          Text('pH / EC Parameter Configuration',
              style: AppTextStyles.sectionTitle),
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
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
            activeColor: AppColors.primaryButton,
            onChanged: onEcChanged,
          ),
          const SizedBox(height: 20),
<<<<<<< HEAD

          // Side-by-Side Pill Buttons
          Row(
            children: [
              // Filled Green Pill "Save changes"
              Expanded(
                child: SizedBox(
                  height: 44,
=======
          // Action Pill Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
<<<<<<< HEAD
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Save changes',
                      style: AppTextStyles.button.copyWith(fontSize: 14),
=======
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Save configuration',
                      style: AppTextStyles.button.copyWith(fontSize: 13),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
<<<<<<< HEAD

              // Outlined Green Pill "Revert"
              Expanded(
                child: SizedBox(
                  height: 44,
=======
              Expanded(
                child: SizedBox(
                  height: 42,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
                  child: OutlinedButton(
                    onPressed: onRevert,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryButton,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
<<<<<<< HEAD
                        borderRadius: BorderRadius.circular(30),
=======
                        borderRadius: BorderRadius.circular(20),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
                      ),
                    ),
                    child: Text(
                      'Revert',
                      style: AppTextStyles.button.copyWith(
<<<<<<< HEAD
                        fontSize: 14,
=======
                        fontSize: 13,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
<<<<<<< HEAD
=======
    required String unit,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    required RangeValues rangeValues,
    required double minLimit,
    required double maxLimit,
    required Color backgroundColor,
    required Color activeColor,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Container(
<<<<<<< HEAD
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
=======
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor, // Thin dark green line
                  inactiveTrackColor: activeColor.withValues(alpha: 0.3), // Muted track
              thumbColor: activeColor, // Dark green circular thumb
              trackHeight: 2, // Thin line height
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 6, // Neat circular thumbs
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
=======
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
              Text(
                'Ideal: ${rangeValues.start.toStringAsFixed(1)} - ${rangeValues.end.toStringAsFixed(1)} $unit',
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
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
            ),
            child: RangeSlider(
              values: rangeValues,
              min: minLimit,
              max: maxLimit,
<<<<<<< HEAD
=======
              divisions: ((maxLimit - minLimit) * 10).round(),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
<<<<<<< HEAD
                'Min ${rangeValues.start.toStringAsFixed(1)}',
                style: AppTextStyles.cardMeta.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                'Max ${rangeValues.end.toStringAsFixed(1)}',
                style: AppTextStyles.cardMeta.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
=======
                'Min Limit: ${minLimit.toStringAsFixed(1)} $unit',
                style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
              ),
              Text(
                'Max Limit: ${maxLimit.toStringAsFixed(1)} $unit',
                style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
              ),
            ],
          ),
        ],
      ),
    );
  }
}