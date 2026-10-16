import 'package:flutter/material.dart';
import '../models/reports_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class SensorHealthCard extends StatelessWidget {
  final List<SensorHealthItem> sensors;

  const SensorHealthCard({super.key, required this.sensors});

  ({Color panel, Color accent}) _colors(String status) => switch (status) {
        'Good' => (
            panel: AppColors.statusCardGreen,
            accent: AppColors.accentGreen
          ),
        'Due soon' || 'Awaiting device' => (
            panel: AppColors.statusCardYellow,
            accent: AppColors.warningYellow
          ),
        'Overdue' || 'Last cal failed' => (
            panel: AppColors.alertBackground,
            accent: AppColors.criticalRed
          ),
        _ => (
            panel: AppColors.calloutBackground,
            accent: AppColors.textSecondary
          ),
      };

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final sensor in sensors) {
      counts.update(sensor.statusLabel, (count) => count + 1,
          ifAbsent: () => 1);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Sensor Calibration',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              _badge('${sensors.length} sensors',
                  AppColors.surfaceMuted, AppColors.textPrimary),
            ],
          ),
          const SizedBox(height: 12),
          if (sensors.isEmpty)
            Text('No sensors reporting yet.', style: AppTextStyles.cardMeta),
          for (var i = 0; i < sensors.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildSensorItem(sensors[i]),
          ],
          if (counts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              counts.entries
                  .map((entry) => '${entry.value} ${entry.key}')
                  .join(' • '),
              style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
  Widget _badge(String label, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            style: AppTextStyles.cardMeta
                .copyWith(color: foreground, fontSize: 11)),
      );

  Widget _buildSensorItem(SensorHealthItem item) {
    final colors = _colors(item.statusLabel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: colors.panel, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(item.sensorName,
            style: AppTextStyles.bodyBold.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Status', style: AppTextStyles.cardMeta.copyWith(fontSize: 10)),
            _badge(item.statusLabel,
                colors.accent.withValues(alpha: 0.12), colors.accent),
            Text(
                item.statusLabel == 'Awaiting device'
                    ? 'Calibration saved; waiting for ESP32 confirmation'
                    : item.daysSinceCalibration < 0
                        ? 'No calibration recorded'
                        : item.daysSinceCalibration == 0
                            ? 'Calibrated today'
                            : 'Last cal: ${item.daysSinceCalibration}d ago',
                style: AppTextStyles.cardMeta.copyWith(fontSize: 11)),
          ],
        ),
      ]),
    );
  }
}
