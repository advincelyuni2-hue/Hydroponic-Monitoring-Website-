import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/reports_models.dart';

class SensorHealthCard extends StatelessWidget {
  final List<SensorHealthItem> sensors;

  const SensorHealthCard({super.key, required this.sensors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sensor Health & Cal', style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          if (sensors.isEmpty)
            Text('No sensors reporting yet.', style: AppTextStyles.cardMeta)
          else
            for (final item in sensors)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item.sensorName,
                            style: AppTextStyles.cardLabel.copyWith(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          item.statusLabel,
                          style: AppTextStyles.cardMeta.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        // Clamp so a bad value (e.g. >100 or negative) from
                        // the mock/future backend can't crash the indicator.
                        value: (item.healthPercentage / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E2E2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.healthPercentage > 70
                              ? AppColors.primaryButton
                              : item.healthPercentage > 40
                                  ? const Color(0xFFF39C12)
                                  : AppColors.alertBorder,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.daysSinceCalibration == 0
                          ? 'Auto / Factory calibrated'
                          : 'Last cal: ${item.daysSinceCalibration}d ago',
                      style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}