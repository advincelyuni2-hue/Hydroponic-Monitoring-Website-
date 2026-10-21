import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../utils/manila_time.dart';

class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key, this.label = 'Paused'});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFFFF0D4), borderRadius: BorderRadius.circular(20)),
    child: Text('? $label', style: AppTextStyles.cardMeta.copyWith(
      color: const Color(0xFF985300), fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class OfflineHeader extends StatelessWidget {
  const OfflineHeader({super.key, required this.child, this.label});
  final Widget child;
  final String? label;
  @override
  Widget build(BuildContext context) => label == null
      ? child
      : Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: child), const SizedBox(width: 8), OfflineBadge(label: label!)]);
}

class SensorOfflineBody extends StatelessWidget {
  const SensorOfflineBody({super.key, required this.title, required this.message,
    this.detail, this.icon = Icons.sensors_off, this.compact = false});
  const SensorOfflineBody.insight({super.key})
      : title = 'No new insight', message = 'Resumes after the next sensor reading.',
        detail = null, icon = Icons.pause_circle_outline, compact = false;
  const SensorOfflineBody.forecast({super.key})
      : title = 'Forecast paused', message = 'Needs a sensor reading from the last five minutes.',
        detail = 'Updates automatically on reconnect.', icon = Icons.cloud_off_outlined, compact = false;
  final String title;
  final String message;
  final String? detail;
  final IconData icon;
  final bool compact;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: EdgeInsets.all(compact ? 4 : 16),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: EdgeInsets.all(compact ? 7 : 11),
        decoration: const BoxDecoration(color: Color(0xFFF0EFE1), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF777B65), size: compact ? 20 : 25)),
      SizedBox(height: compact ? 6 : 10),
      Text(title, textAlign: TextAlign.center,
        style: AppTextStyles.bodyBold.copyWith(fontSize: compact ? 13 : 15)),
      const SizedBox(height: 4),
      Text(message, textAlign: TextAlign.center,
        style: AppTextStyles.cardMeta.copyWith(fontSize: compact ? 11 : 12)),
      if (detail != null) ...[
        const SizedBox(height: 3),
        Text(detail!, textAlign: TextAlign.center,
          style: AppTextStyles.cardMeta.copyWith(fontSize: compact ? 11 : 12)),
      ],
    ])));
}

/// Presentation only: the parent supplies its existing offline state/timestamp.
/// Elapsed time updates only when the parent rebuilds; no retry timer is added.
class SensorOfflineBanner extends StatelessWidget {
  const SensorOfflineBanner({super.key, required this.lastReceived});
  final DateTime? lastReceived;
  @override
  Widget build(BuildContext context) {
    final minutes = lastReceived == null ? null
        : DateTime.now().difference(lastReceived!).inMinutes.clamp(0, 99999999);
    final age = minutes == null ? '' : minutes < 1 ? 'less than a minute ago'
        : minutes < 60 ? '$minutes min ago'
        : '${minutes ~/ 60}h ${minutes % 60}m ago';
    final description = lastReceived == null ? 'No sensor reading received. Forecasts are paused.'
        : 'Last reading ${formatManilaDateTime(toManilaTime(lastReceived!))} ($age). Forecasts are paused.';
    return Container(width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFF1D4),
        border: Border.all(color: const Color(0xFFFFD59A)), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const CircleAvatar(backgroundColor: Colors.white,
          child: Icon(Icons.sensors_off, color: Color(0xFF985300), size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sensor offline', style: AppTextStyles.bodyBold.copyWith(color: const Color(0xFF804800))),
          const SizedBox(height: 3),
          Text(description, style: AppTextStyles.cardMeta.copyWith(color: const Color(0xFF804800))),
        ])),
      ]));
  }
}
