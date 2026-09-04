import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';

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
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            activeColor: AppColors.primaryButton,
            onChanged: onEcChanged,
          ),
          const SizedBox(height: 20),

          // Side-by-Side Pill Buttons
          Row(
            children: [
              // Filled Green Pill "Save changes"
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Save changes',
                      style: AppTextStyles.button.copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Outlined Green Pill "Revert"
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onRevert,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryButton,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Revert',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 14,
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
    required RangeValues rangeValues,
    required double minLimit,
    required double maxLimit,
    required Color backgroundColor,
    required Color activeColor,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            ),
            child: RangeSlider(
              values: rangeValues,
              min: minLimit,
              max: maxLimit,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}