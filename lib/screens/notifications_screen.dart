import '../widgets/hydro_loading_screen.dart';
import '../widgets/app_footer.dart';
import 'package:flutter/material.dart';
import '../widgets/mobile_page_header.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_mode_controller.dart';
import '../utils/manila_time.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/notification_inbox_widgets.dart';
import 'add_log_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String? initialSelectedId;
  final String initialTab;
  final NotificationController? controller;
  const NotificationsScreen(
      {super.key,
      this.initialSelectedId,
      this.initialTab = 'Active',
      this.controller});
  @override
  State<NotificationsScreen> createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationController _controller;
  late String selectedTab;
  String? highlightedNotificationId;
  NotificationType? _filter;
  bool _newestFirst = true;
  bool _dialogOpen = false;
  bool _mobileOpen = false;

  // NEW: desktop panel is collapsed into the small circle.
  bool _panelMinimized = false;
  // NEW: the list scrolls on its own beside the details panel.
  final ScrollController _listScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? NotificationController();
    selectedTab = widget.initialTab;
    highlightedNotificationId = widget.initialSelectedId;
    _controller.addListener(_syncSelection);
  }

  void _syncSelection() {
    if (!mounted) return;
    if (!_controller.isLoading &&
        !_visible.any((e) => e.id == highlightedNotificationId)) {
      highlightedNotificationId = null;
      _panelMinimized = false;
    }
  }

  List<AppNotificationItem> get _visible {
    final list = (selectedTab == 'Active'
            ? _controller.activeNotifications
            : _controller.resolvedNotifications)
        .where((item) => _filter == null || item.type == _filter)
        .toList();
    list.sort((a, b) {
      if (a.createdAt == null) {
        return b.createdAt == null ? a.id.compareTo(b.id) : 1;
      }
      if (b.createdAt == null) return -1;
      final order = a.createdAt!.compareTo(b.createdAt!);
      return order == 0
          ? a.id.compareTo(b.id)
          : _newestFirst
              ? -order
              : order;
    });
    return list;
  }

  @override
  void dispose() {
    _controller.removeListener(_syncSelection);
    _listScroll.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _showFixLog(AppNotificationItem item) async {
    if (item.isResolved || _dialogOpen || _controller.isBusy(item.id)) return;
    _dialogOpen = true;
    try {
      await showRecordFixDialog(
        context,
        notification: item,
        submissionError: () => _controller.errorMessage,
        onSubmit: (entry) async {
          final saved = await _controller.recordFixAndResolve(
            item,
            parameter: entry.parameter,
            currentValue: entry.currentValue,
            actionType: entry.actionType,
            amount: entry.amount,
            notes: entry.notes,
            reservoirVolumeL: entry.reservoirVolumeL,
          );
          if (!mounted) return saved;
          if (saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Intervention recorded. The alert will resolve after three stable readings.',
                ),
              ),
            );
          }
          return saved;
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _resolve(AppNotificationItem item) async {
    if (item.isResolved || item.isSensorAlert || _controller.isBusy(item.id)) {
      return;
    }
    final saved = await _controller.toggleResolve(item, true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(saved
            ? 'Notification marked resolved.'
            : _controller.errorMessage ?? 'Unable to resolve notification.')));
  }

  // CHANGED: `expand` is true only in the desktop split view.
  Widget _details(AppNotificationItem item,
      {bool mobile = false, bool expand = false}) {
    final parameterKnown =
        RegExp(r'\bp\s*h\b|\bec\b|temperature|\btemp\b', caseSensitive: false)
            .hasMatch('${item.title} ${item.subtitle}');
    return NotificationDetailsPanel(
        item: item,
        expand: expand,
        busy: _controller.isBusy(item.id),
        onClose: mobile
            ? null
            : () => setState(() {
                  highlightedNotificationId = null;
                  _panelMinimized = false;
                }),
        onMinimize:
            expand ? () => setState(() => _panelMinimized = true) : null,
        // TODO: connect to your History logs screen, e.g.
        // onViewHistory: () => Navigator.of(context).push(...),
        // Leave null to hide the "View in history logs" button.
        onViewHistory: null,
        onRecord:
            item.isResolved || !parameterKnown ? null : () => _showFixLog(item),
        onResolve: item.isResolved || item.isSensorAlert
            ? null
            : () => _resolve(item));
  }

  Future<void> _open(AppNotificationItem item, bool wide) async {
    // CHANGED: selecting a notification also reopens a minimized panel.
    setState(() {
      highlightedNotificationId = item.id;
      _panelMinimized = false;
    });
    if (wide || _mobileOpen) return;
    _mobileOpen = true;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(child: Column(children: [
                const MobilePageHeader(title: 'Notification Details'),
                Expanded(child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final matches =
                        _controller.notifications.where((n) => n.id == item.id);
                    return AppFooterScrollView(
                      showFooter: !_controller.isLoading,
                        padding: const EdgeInsets.all(16),
                        child: matches.isEmpty
                            ? const Text(
                                'This notification is no longer available.')
                            : _details(matches.first, mobile: true));
                  })),
              ])),
            )));
    _mobileOpen = false;
    if (mounted) setState(() => highlightedNotificationId = null);
  }

  String _dateGroup(AppNotificationItem item) {
    if (item.createdAt == null) return 'Date unavailable';
    final date = toManilaTime(item.createdAt!);
    final now = manilaNow();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _list(List<AppNotificationItem> items, bool wide) {
    final groups = <String, List<AppNotificationItem>>{};
    for (final item in items) {
      groups.putIfAbsent(_dateGroup(item), () => []).add(item);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final group in groups.entries)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        child: Text(group.key, style: AppTextStyles.cardMeta)),
                    for (final item in group.value) ...[
                      Divider(height: 1, color: AppColors.cardBorder),
                      NotificationInboxRow(
                          item: item,
                          selected: highlightedNotificationId == item.id,
                          onOpen: () => _open(item, wide)),
                    ],
                  ]),
            )),
    ]);
  }

  Widget _toolbar() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: LayoutBuilder(builder: (context, constraints) {
          final filter = PopupMenuButton<String>(
            tooltip: 'Filter notifications',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 4),
            color: AppColors.cardBackground,
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.cardBorder),
            ),
            onSelected: (value) {
              setState(() {
                _filter = value == 'all'
                    ? null
                    : NotificationType.values.firstWhere(
                        (type) => type.name == value,
                      );
                _syncSelection();
              });
            },
            itemBuilder: (context) => [
              for (final option in <(String, String)>[
                ('All', 'all'),
                ('Critical', 'critical'),
                ('Warning', 'warning'),
                ('Information', 'info'),
              ])
                PopupMenuItem<String>(
                  value: option.$2,
                  child: Row(children: [
                    Expanded(
                      child: Text(option.$1, style: AppTextStyles.bodySmall),
                    ),
                    if (_filter == option.$2)
                      Icon(Icons.check, size: 18, color: AppColors.primaryButton),
                  ]),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.filter_list, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 6),
                Text(
                  _filter == null
                      ? 'Filter'
                      : 'Filter: ${_filter == NotificationType.info ? 'Information' : _filter!.name}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
              ]),
            ),
          );
          final sort = TextButton.icon(
            onPressed: () => setState(() => _newestFirst = !_newestFirst),
            icon: Icon(_newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16),
            label: Text(_newestFirst ? 'By Date: newest' : 'By Date: oldest'),
          );
          if (constraints.maxWidth < 420) {
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [filter, sort],
            );
          }
          return Row(children: [filter, const Spacer(), sort]);
        }),
      );

  Widget _errorBanner() => _controller.errorMessage == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_controller.errorMessage!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.criticalRed)));

  /// NEW: desktop layout used while a notification is selected.
  /// Header, tabs and toolbar stay fixed; the list scrolls by itself on the
  /// left; the details panel fills the remaining height on the right (or is
  /// collapsed into a small circle at the top right).
  Widget _splitView(
      List<AppNotificationItem> items, AppNotificationItem selected, double pad) {
    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const AppHeader(title: 'Notifications'),
        const SizedBox(height: 24),
        Row(children: [
          _buildTab('Active'),
          const SizedBox(width: 20),
          _buildTab('Resolved')
        ]),
        Divider(height: 1, color: AppColors.cardBorder),
        _toolbar(),
        _errorBanner(),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // The list takes the full width when minimized; the circle
            // floats on top of it instead of reserving its own column.
            Expanded(
              flex: 7,
              child: Stack(children: [
                Positioned.fill(
                  child: Scrollbar(
                    controller: _listScroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _listScroll,
                      padding: const EdgeInsets.only(right: 12),
                      child: _list(items, true),
                    ),
                  ),
                ),
                if (_panelMinimized)
                  Positioned(
                    top: 0,
                    right: 18,
                    child: NotificationMinimizedButton(
                      item: selected,
                      onPressed: () => setState(() => _panelMinimized = false),
                    ),
                  ),
              ]),
            ),
            if (!_panelMinimized) ...[
              const SizedBox(width: 16),
              Expanded(flex: 5, child: _details(selected, expand: true)),
            ],
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(selectedIndex: -1),
        body: SafeArea(
            child: ListenableBuilder(
                listenable: Listenable.merge([_controller, appThemeMode]),
                builder: (context, _) {
                  if (_controller.isLoading) return const HydroLoadingScreen();
                  final items = _visible;
                  final selected = items
                      .where((item) => item.id == highlightedNotificationId)
                      .firstOrNull;
                  final pad = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 24.0;
                  return LayoutBuilder(builder: (context, box) {
                    final wideScreen = box.maxWidth - pad * 2 >= 850;

                    // Desktop + a notification selected: fixed-height layout.
                    if (wideScreen &&
                        !_controller.isLoading &&
                        selected != null) {
                      return _splitView(items, selected, pad);
                    }

                    // Everything else: the original page-scroll layout.
                    return AppFooterScrollView(
                      showFooter: !_controller.isLoading,
                      key: const PageStorageKey('notification-list-scroll'),
                      padding: EdgeInsets.all(pad),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AppHeader(title: 'Notifications'),
                            const SizedBox(height: 24),
                            Row(children: [
                              _buildTab('Active'),
                              const SizedBox(width: 20),
                              _buildTab('Resolved')
                            ]),
                            Divider(height: 1, color: AppColors.cardBorder),
                            _toolbar(),
                            _errorBanner(),
                            if (_controller.isLoading)
                              const Center(child: CircularProgressIndicator())
                            else if (items.isEmpty)
                              Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                      'No ${selectedTab.toLowerCase()} notifications found.',
                                      style: AppTextStyles.bodySmall))
                            else
                              LayoutBuilder(builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 850;
                                if (!wide && selected != null && !_mobileOpen) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted &&
                                        !_mobileOpen &&
                                        highlightedNotificationId ==
                                            selected.id) {
                                      _open(selected, false);
                                    }
                                  });
                                }
                                return _list(items, wide);
                              }),
                          ]),
                    );
                  });
                })),
      );

  Widget _buildTab(String title) {
    final isActive = selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() {
        selectedTab = title;
        highlightedNotificationId = null;
        _panelMinimized = false;
      }),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 16,
                color:
                    isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryButton : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}