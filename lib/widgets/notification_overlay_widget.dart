import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/manila_time.dart';

class NotificationOverlayWidget extends StatefulWidget {
  final List<AppNotificationItem> notifications;
  final ValueChanged<AppNotificationItem> onNotificationTap;
  final VoidCallback onViewAllTap;

  const NotificationOverlayWidget({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onViewAllTap,
  });

  @override
  State<NotificationOverlayWidget> createState() => _NotificationOverlayWidgetState();
}

class _NotificationOverlayWidgetState extends State<NotificationOverlayWidget> {
  NotificationType? _filter;
  final Set<String> _expandedIds = <String>{};
  final Set<String> _markedReadIds = <String>{};
  bool _markingAllRead = false;
  String? _readError;

  bool _isRead(AppNotificationItem item) =>
      item.isRead || _markedReadIds.contains(item.id);

  Future<void> _markAllRead() async {
    if (_markingAllRead) return;
    final unread = widget.notifications
        .where((item) => !item.isResolved && !_isRead(item))
        .toList();
    if (unread.isEmpty) return;
    setState(() {
      _markingAllRead = true;
      _readError = null;
    });
    final service = NotificationService();
    var failures = 0;
    for (final item in unread) {
      try {
        final saved = await service.markAsRead(item.id);
        if (saved) {
          if (mounted) setState(() => _markedReadIds.add(item.id));
        } else {
          failures++;
        }
      } catch (_) {
        failures++;
      }
    }
    if (!mounted) return;
    setState(() {
      _markingAllRead = false;
      _readError = failures == 0
          ? null
          : 'Some notifications could not be marked as read. Please try again.';
    });
  }

  bool _isToday(AppNotificationItem item) {
    if (item.createdAt == null) return false;
    final date = toManilaTime(item.createdAt!);
    final now = manilaNow();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.notifications.where((n) => !n.isResolved).toList();
    final unread = active.where((n) => !_isRead(n)).length;
    final visible = active.where((n) => _filter == null || n.type == _filter).toList();
    final today = visible.where(_isToday).toList();
    final earlier = visible.where((n) => !_isToday(n)).toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: AppDecorations.card(radius: 16),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Row(children: [
              Flexible(child: Text('Notifications',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.alertBackground,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$unread new', style: AppTextStyles.cardMeta.copyWith(
                    fontSize: 10, color: AppColors.criticalRed, fontWeight: FontWeight.w700)),
              ),
              ])),
              const SizedBox(width: 8),
              Tooltip(
                message: _markingAllRead
                    ? 'Marking notifications as read…'
                    : 'Mark all notifications in this popup as read',
                child: TextButton(
                  onPressed: _markingAllRead || unread == 0 ? null : _markAllRead,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentGreen,
                    disabledForegroundColor: AppColors.textSecondary,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: AppTextStyles.cardMeta.copyWith(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Mark all read', softWrap: false,
                      textAlign: TextAlign.right),
                ),
              ),
            ]),
            if (_readError != null) ...[
              const SizedBox(height: 6),
              Text(_readError!, style: AppTextStyles.cardMeta.copyWith(
                  color: AppColors.criticalRed)),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10)),
              child: Wrap(spacing: 2, runSpacing: 4, children: [
                for (final filter in <NotificationType?>[
                  null, NotificationType.critical, NotificationType.warning,
                ])
                  TextButton(
                    onPressed: () => setState(() => _filter = filter),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: _filter == filter ? AppColors.primaryButton : Colors.transparent,
                      foregroundColor: _filter == filter ? Colors.white : AppColors.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: AppTextStyles.cardMeta.copyWith(fontWeight: FontWeight.w600),
                    ),
                    child: Text('${filter == null ? 'All' : filter == NotificationType.critical ? 'Critical' : 'Warning'} '
                        '${active.where((n) => filter == null || n.type == filter).length}'),
                  ),
              ]),
            ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView(
                  primary: false,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('No active notifications', textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall),
                      ),
                    if (today.isNotEmpty) ...[
                      _groupLabel('TODAY'),
                      for (final item in today) _notification(item),
                    ],
                    if (earlier.isNotEmpty) ...[
                      _groupLabel('EARLIER'),
                      for (final item in earlier) _notification(item),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: widget.onViewAllTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.cardBackground,
                foregroundColor: AppColors.accentGreen,
                side: BorderSide(color: AppColors.accentGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              child: const Text('View all notifications', textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 6),
    child: Text(text, style: AppTextStyles.cardMeta.copyWith(
        fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w600)),
  );

  Widget _notification(AppNotificationItem item) {
    final expanded = _expandedIds.contains(item.id);
    final critical = item.type == NotificationType.critical;
    final warning = item.type == NotificationType.warning;
    final color = critical ? AppColors.criticalRed
        : warning ? AppColors.warningYellow : AppColors.textSecondary;
    final background = !_isToday(item) ? AppColors.cardBackground
        : critical ? AppColors.alertBackground
        : warning ? AppColors.statusCardYellow : AppColors.surfaceMuted;
    final canRecordFix = !item.isResolved &&
        RegExp(r'\bp\s*h\b|\bec\b|temperature|\btemp\b', caseSensitive: false)
            .hasMatch('${item.title} ${item.subtitle}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _isToday(item) ? background : AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            if (expanded) {
              _expandedIds.remove(item.id);
            } else {
              _expandedIds.add(item.id);
            }
          }),
          child: Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 3))),
            padding: const EdgeInsets.all(9),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: color.withValues(alpha: .12), shape: BoxShape.circle),
                child: Icon(critical ? Icons.error_outline : warning
                    ? Icons.warning_amber_rounded : Icons.info_outline, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(item.title, style: AppTextStyles.bodyBold.copyWith(fontSize: 12))),
                  if (!_isRead(item)) ...[
                    const SizedBox(width: 6),
                    Semantics(label: 'Unread', child: Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    )),
                  ],
                ]),
                if (expanded && item.subtitle != item.title) ...[
                  const SizedBox(height: 3),
                  Text(item.subtitle, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                ],
                const SizedBox(height: 5),
                SizedBox(width: double.infinity, child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8, runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Wrap(spacing: 6, runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(item.timestamp, style: AppTextStyles.cardMeta.copyWith(fontSize: 10)),
                  if (expanded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: _isToday(item)
                        ? AppColors.cardBackground : color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(critical ? 'Critical' : warning ? 'Warning' : 'Information',
                        style: AppTextStyles.cardMeta.copyWith(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                  ),
                  ]),
                  if (expanded && canRecordFix)
                    TextButton(
                      onPressed: () => widget.onNotificationTap(item),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        foregroundColor: AppColors.accentGreen,
                        textStyle: AppTextStyles.cardMeta.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Record fix ›'),
                    ),
                ])),
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}
