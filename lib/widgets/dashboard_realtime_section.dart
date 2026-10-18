import 'card_info_tooltip.dart';
import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import 'dashboard_parameter_gauge.dart';

/// The existing horizontal sensor strip, shared by narrow Dashboard layouts.
class DashboardRealtimeSection extends StatelessWidget {
  const DashboardRealtimeSection(
      {super.key,
      required this.statuses,
      this.isOffline = false,
      this.isCalibrating = false});
  final List<ParameterStatus> statuses;
  final bool isOffline;
  final bool isCalibrating;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1150 ||
        MediaQuery.textScalerOf(context).scale(14) > 16.8;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CardInfoTitle('Realtime Parameter Status', description: 'Displays the latest monitored pH, EC, and temperature readings and their current conditions.',
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: compact ? 17 : 19,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOffline
                      ? AppColors.textSecondary
                      : AppColors.primaryButton,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isCalibrating
                    ? 'Calibrating'
                    : (isOffline ? 'Offline' : 'Live'),
                style: AppTextStyles.cardMeta,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (compact)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < statuses.length; i++) ...[
                      DashboardParameterGauge(data: statuses[i], compact: true),
                      if (i != statuses.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < statuses.length; i++) ...[
                    Expanded(
                        child: DashboardParameterGauge(
                            data: statuses[i], dense: true)),
                    if (i != statuses.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
