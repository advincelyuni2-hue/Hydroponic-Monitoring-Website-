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

/// Small green circle shown at the top right while the details panel is
/// minimized. The dot uses the alert's severity color. Tap to reopen.
class NotificationMinimizedButton extends StatelessWidget {
  final AppNotificationItem item;
  final VoidCallback onPressed;
  const NotificationMinimizedButton(
      {super.key, required this.item, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final appearance = NotificationAppearance(item);
    return Tooltip(
      message: 'Show details',
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            child: Material(
              elevation: 6,
              shadowColor: Colors.black54,
              color: AppColors.primaryButton,
              shape: const CircleBorder(),
              child: InkWell(
                key: const ValueKey('notification-restore'),
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: const Center(
                    child: Icon(Icons.notifications_none,
                        color: Colors.white, size: 20)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: appearance.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class NotificationDetailsPanel extends StatefulWidget {
  final AppNotificationItem item;
  final VoidCallback? onClose;

  /// When set, a minimize button is shown next to the close button.
  final VoidCallback? onMinimize;
  final VoidCallback? onRecord;
  final VoidCallback? onResolve;

  /// Optional. When set, a "View in history logs" button is pinned at the
  /// bottom of the panel.
  final VoidCallback? onViewHistory;
  final bool busy;

  /// true  -> fill the height given by the parent (desktop split view); the
  ///          body scrolls inside the panel and the buttons stay pinned.
  /// false -> size to content (used on the mobile details page).
  final bool expand;

  const NotificationDetailsPanel(
      {super.key,
      required this.item,
      this.onClose,
      this.onMinimize,
      this.onRecord,
      this.onResolve,
      this.onViewHistory,
      this.busy = false,
      this.expand = false});

  @override
  State<NotificationDetailsPanel> createState() =>
      _NotificationDetailsPanelState();
}

class _NotificationDetailsPanelState extends State<NotificationDetailsPanel> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant NotificationDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id && _scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final appearance = NotificationAppearance(item);

    final header = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
                child: Text(item.title,
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 18))),
            if (widget.onMinimize != null)
              IconButton(
                  key: const ValueKey('notification-minimize'),
                  tooltip: 'Minimize',
                  onPressed: widget.onMinimize,
                  icon: const Icon(Icons.close_fullscreen, size: 20)),
            if (widget.onClose != null)
              IconButton(
                  tooltip: 'Close details',
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 20))
          ]),
          Align(alignment: Alignment.centerLeft, child: appearance.badge()),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.cardBorder),
        ]);

    final body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Created ${item.alertCreatedAt ?? 'Date unavailable'}',
              style: AppTextStyles.cardMeta),
          Text('Latest update ${item.latestActivityAt ?? 'Date unavailable'}',
              style: AppTextStyles.cardMeta),
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
          if (!item.isResolved && item.isSensorAlert) ...[
            const SizedBox(height: 10),
            Text(
                item.isMonitoring
                    ? 'Intervention recorded. Waiting for three consecutive stable readings before automatic resolution.'
                    : 'Resolves automatically after three stable readings.',
                style: AppTextStyles.cardMeta),
          ],
          const SizedBox(height: 18),
          Text('Timeline', style: AppTextStyles.bodyBold),
          const SizedBox(height: 10),
          ..._timeline(item, appearance),
        ]);

    final footer = _footer();

    final content = widget.expand
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            header,
            const SizedBox(height: 14),
            Expanded(
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.only(right: 12),
                  child: body,
                ),
              ),
            ),
            if (footer != null) ...[const SizedBox(height: 12), footer],
          ])
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
                header,
                const SizedBox(height: 14),
                body,
                if (footer != null) ...[const SizedBox(height: 12), footer],
              ]);

    return Container(
      key: const ValueKey('notification-details'),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: content,
    );
  }

  /// Buttons pinned at the bottom of the panel. Returns null when there is
  /// nothing to show.
  Widget? _footer() {
    final item = widget.item;
    final showActions = !item.isResolved &&
        (widget.onRecord != null || widget.onResolve != null);
    if (!showActions && widget.onViewHistory == null) return null;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showActions)
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (widget.onRecord != null)
                CustomButton(
                    text: 'Record action',
                    backgroundColor: AppColors.primaryButton,
                    textStyle: AppTextStyles.button
                        .copyWith(color: Colors.white, fontSize: 13),
                    onPressed: widget.busy ? null : widget.onRecord,
                    isLoading: widget.busy,
                    height: 40,
                    width: 156),
              if (widget.onResolve != null)
                OutlinedButton(
                    onPressed: widget.busy ? null : widget.onResolve,
                    child: const Text('Mark resolved')),
            ]),
          if (showActions && widget.onViewHistory != null)
            const SizedBox(height: 10),
          if (widget.onViewHistory != null)
            OutlinedButton(
              key: const ValueKey('notification-view-history'),
              onPressed: widget.onViewHistory,
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: BorderSide(color: AppColors.primaryButton),
                foregroundColor: AppColors.primaryButton,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('View in history logs'),
            ),
        ]);
  }

  /// Built only from fields that already exist on AppNotificationItem.
  List<Widget> _timeline(
      AppNotificationItem item, NotificationAppearance appearance) {
    final entries = <({String title, String time, Color color})>[
      (
        title: 'Alert created',
        time: item.alertCreatedAt ?? 'Date unavailable',
        color: appearance.color
      ),
      if (item.actionTakenAt != null)
        (
          title: 'Intervention recorded',
          time: item.actionTakenAt!,
          color: AppColors.primaryButton
        ),
      if (item.recoveryStartedAt != null)
        (
          title: 'Recovery started',
          time: item.recoveryStartedAt!,
          color: AppColors.accentTeal
        ),
      if (item.isResolved)
        (
          title:
              'Resolved${item.resolvedByName == null ? '' : ' by ${item.resolvedByName}'}',
          time: item.resolvedAt ?? '',
          color: AppColors.accentGreen
        ),
    ];
    return [
      for (var i = 0; i < entries.length; i++)
        _timelineEntry(entries[i].title, entries[i].time, entries[i].color,
            last: i == entries.length - 1),
    ];
  }

  Widget _timelineEntry(String title, String time, Color color,
          {required bool last}) =>
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 14,
            child: Column(children: [
              const SizedBox(height: 4),
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              if (!last)
                Expanded(
                    child: Container(width: 2, color: AppColors.cardBorder)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                    if (time.isNotEmpty)
                      Text(time, style: AppTextStyles.cardMeta),
                  ]),
            ),
          ),
        ]),
      );

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
