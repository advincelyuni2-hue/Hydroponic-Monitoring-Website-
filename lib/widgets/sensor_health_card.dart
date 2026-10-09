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
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Text('Sensor Calibration',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 18))),
            const SizedBox(width: 8),
            _badge(
                '${sensors.length} ${sensors.length == 1 ? 'sensor' : 'sensors'}',
                AppColors.surfaceMuted,
                AppColors.textPrimary),
          ]),
          const SizedBox(height: 16),
          if (sensors.isEmpty)
            Text('No sensors reporting yet.', style: AppTextStyles.cardMeta),
          for (var i = 0; i < sensors.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildSensorItem(sensors[i]),
          ],
          if (counts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 8, children: [
              for (final entry in counts.entries)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          color: _colors(entry.key).accent,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: '${entry.key} ', style: AppTextStyles.cardMeta),
                    TextSpan(
                        text: '${entry.value}',
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 12)),
                  ])),
                ]),
            ]),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: colors.panel, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, constraints) {
          final name = Text(item.sensorName,
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13));
          final badge = _badge(item.statusLabel,
              colors.accent.withValues(alpha: 0.12), colors.accent);
          if (constraints.maxWidth < 230 ||
              MediaQuery.textScalerOf(context).scale(13) > 18) {
            return Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: [name, badge]);
          }
          return Row(children: [
            Expanded(child: name),
            const SizedBox(width: 8),
            badge
          ]);
        }),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (item.healthPercentage / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.pillBackground,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
            item.statusLabel == 'Awaiting device'
                ? 'Calibration saved; waiting for ESP32 confirmation'
                : item.daysSinceCalibration < 0
                    ? 'No calibration recorded'
                    : item.daysSinceCalibration == 0
                        ? 'Calibrated today'
                        : 'Last cal: ${item.daysSinceCalibration}d ago',
            style: AppTextStyles.cardMeta.copyWith(fontSize: 11)),
      ]),
    );
  }
}
