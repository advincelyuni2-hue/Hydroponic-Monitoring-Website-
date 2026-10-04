import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/reports_models.dart';
=======
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

class SensorHealthCard extends StatelessWidget {
  final List<SensorHealthItem> sensors;

<<<<<<< HEAD
  const SensorHealthCard({super.key, required this.sensors});

  @override
  Widget build(BuildContext context) {
    return Container(
=======
  const SensorHealthCard({
    super.key,
    required this.sensors,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
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
=======
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sensor Calibration',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              Text(
                '3 Active Probes',
                style: AppTextStyles.cardMeta.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sensors.isEmpty)
            Text('No sensors reporting yet.', style: AppTextStyles.cardMeta)
          else if (isMobile)
            Column(
              children: sensors.map((item) => _buildSensorItem(item)).toList(),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sensors.map((item) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildSensorItem(item),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorItem(SensorHealthItem item) {
    return Padding(
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
          const SizedBox(height: 6),
          Text(
            item.daysSinceCalibration == 0
                ? 'Auto / Factory calibrated'
                : 'Last cal: ${item.daysSinceCalibration}d ago',
            style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
          ),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
        ],
      ),
    );
  }
}