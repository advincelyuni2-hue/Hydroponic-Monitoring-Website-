import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/manila_time.dart';
import 'custom_button.dart';

class NotificationAppearance {
  final AppNotificationItem item;
  const NotificationAppearance(this.item);
  bool get critical =>
      item.type == NotificationType.critical ||
      item.currentStatus.toLowerCase().contains('critical');
  bool get warning =>
      item.type == NotificationType.warning ||
      ['warning', 'drift', 'high', 'low']
          .any(item.currentStatus.toLowerCase().contains);
  Color get color => critical
      ? AppColors.criticalRed
      : warning
          ? AppColors.warningYellow
          : AppColors.accentGreen;
  Color get background => critical
      ? AppColors.alertBackground
      : warning
          ? AppColors.statusCardYellow
          : AppColors.statusCardGreen;
  String get label => item.type == NotificationType.info
      ? 'Information'
      : critical
          ? 'Critical Alert'
          : 'Warning Alert';
  Widget badge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: AppTextStyles.cardMeta.copyWith(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class NotificationInboxRow extends StatelessWidget {
  final AppNotificationItem item;
  final bool selected;
  final VoidCallback onOpen;
  const NotificationInboxRow(
      {super.key,
      required this.item,
      required this.selected,
      required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final appearance = NotificationAppearance(item);
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.statusCardGreen : AppColors.cardBackground,
        border: Border(left: BorderSide(color: appearance.color, width: 4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: InkWell(
          key: ValueKey('open-${item.id}'),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(item.title,
                              style: AppTextStyles.bodyBold
                                  .copyWith(fontSize: 13)),
                          appearance.badge()
                        ]),
                    const SizedBox(height: 3),
                    Text(item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall),
                  ])),
              const SizedBox(width: 8),
              Text(
                  item.createdAt == null
                      ? 'Unknown time'
                      : formatManilaClockTime(toManilaTime(item.createdAt!)),
                  style: AppTextStyles.cardMeta.copyWith(fontSize: 10)),
            ]),
          ),
        )),
      ]),
    );
  }
}

class NotificationDetailsPanel extends StatelessWidget {
  final AppNotificationItem item;
  final VoidCallback? onClose;
  final VoidCallback? onRecord;
  final VoidCallback? onResolve;
  final bool busy;
  const NotificationDetailsPanel(
      {super.key,
      required this.item,
      this.onClose,
      this.onRecord,
      this.onResolve,
      this.busy = false});

  @override
  Widget build(BuildContext context) {
    final appearance = NotificationAppearance(item);
    return Container(
      key: const ValueKey('notification-details'),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                  child: Text(item.title,
                      style:
                          AppTextStyles.sectionTitle.copyWith(fontSize: 18))),
              if (onClose != null)
                IconButton(
                    tooltip: 'Close details',
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 20))
            ]),
            Align(alignment: Alignment.centerLeft, child: appearance.badge()),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 14),
            Text('Created ${item.timestamp}', style: AppTextStyles.cardMeta),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth < 300
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                _field('Current status', item.currentStatus, width,
                    color: appearance.color),
                _field('Current reading', item.currentValue, width),
                _field('Ideal range', item.idealRange, width),
                _field('Status', item.lifecycleLabel, width,
                    color: AppColors.accentGreen),
              ]);
            }),
            const SizedBox(height: 14),
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.calloutBackground,
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recommendation', style: AppTextStyles.cardMeta),
                      const SizedBox(height: 4),
                      Text(item.recommendation,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textPrimary)),
                    ])),
            if (item.isResolved) ...[
              const SizedBox(height: 12),
              Text(
                  'Resolved${item.resolvedByName == null ? '' : ' by ${item.resolvedByName}'}${item.resolvedAt == null ? '' : ' ? ${item.resolvedAt}'}',
                  style: AppTextStyles.bodySmall),
            ] else ...[
              if (item.isSensorAlert) ...[
                const SizedBox(height: 10),
                Text('Resolves automatically after three stable readings.',
                    style: AppTextStyles.cardMeta),
              ],
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (onRecord != null)
                  CustomButton(
                      text: 'Record action',
                      backgroundColor: AppColors.primaryButton,
                      textStyle: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13),
                      onPressed: busy ? null : onRecord,
                      isLoading: busy,
                      height: 40,
                      width: 156),
                if (onResolve != null)
                  OutlinedButton(
                      onPressed: busy ? null : onResolve,
                      child: const Text('Mark resolved')),
              ]),
            ],
          ]),
    );
  }

  Widget _field(String label, String value, double width, {Color? color}) =>
      SizedBox(
          width: width,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTextStyles.cardMeta),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.bodySmall
                    .copyWith(color: color ?? AppColors.textPrimary)),
          ]));
}
