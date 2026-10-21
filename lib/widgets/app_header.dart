import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_models.dart';
import '../screens/notifications_screen.dart';
import '../screens/add_log_screen.dart';
import '../screens/settings_screen.dart';
import '../services/notification_service.dart';
import '../services/supabase_client.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'notification_overlay_widget.dart';
import 'header_search.dart';
import '../services/app_state.dart';
import '../services/global_search_service.dart';

/// UI-only additions (no backend changes):
///  - search bar capped at a fixed max width and anchored beside the bell,
///    so the right-hand cluster stays put while the left side changes per page
///  - soft green bell circle (all sizes)
///  - avatar shows the user's initial instead of the generic person icon
///    (all sizes)
///  - on mobile the title scales down to fit so it is always shown in full
const double _kSearchMaxWidth = 400;
const Color _kBellTint = Color(0xFFE3EDD0);

class AppHeader extends StatelessWidget {
  final String title;
  final String? mobileTitle;
  final UserProfile? profile;
  final VoidCallback? onBellTap;
  final VoidCallback? onProfileTap;
  final HistoryDateSelection? onHistoryDateSelected;

  /// Optional widget shown right next to the page title (desktop/tablet only).
  /// On mobile it is ignored; the screen is expected to place it elsewhere.
  final Widget? titleAction;

  /// Opt-in compact header for Reports at narrow viewport widths.
  final bool compactLayout;

  const AppHeader({
    super.key,
    required this.title,
    this.mobileTitle,
    this.profile,
    this.onBellTap,
    this.onProfileTap,
    this.onHistoryDateSelected,
    this.titleAction,
    this.compactLayout = false,
  });

  void showNotificationOverlay(BuildContext context, GlobalKey bellKey) {
    final renderBox = bellKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
      return;
    }

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        final media = MediaQuery.of(context);
        final viewport = media.size;
        final width = (viewport.width - media.padding.horizontal - 16)
            .clamp(0.0, 380.0);
        final availableHeight = (viewport.height - media.padding.vertical -
                media.viewInsets.bottom - 16).clamp(0.0, 480.0);
        final top = (offset.dy + size.height + 8).clamp(
          media.padding.top + 8,
          (viewport.height - media.padding.bottom - media.viewInsets.bottom -
                  availableHeight - 8).clamp(media.padding.top + 8, double.infinity),
        );
        final left = (offset.dx + size.width - width).clamp(
          media.padding.left + 8,
          (viewport.width - media.padding.right - width - 8)
              .clamp(media.padding.left + 8, double.infinity),
        );
        return Stack(
        children: [
          // Dismiss overlay when clicking outside
          GestureDetector(
            onTap: () => overlayEntry.remove(),
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: top,
            left: left,
            width: width,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: availableHeight),
              child: StreamBuilder<List<AppNotificationItem>>(
              stream: NotificationService().streamNotificationItems(),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                return NotificationOverlayWidget(
                  notifications: notifications,
                  onNotificationTap: (item) {
                    overlayEntry.remove();
                    final interventionService = NotificationService();
                    showRecordFixDialog(
                      context,
                      notification: item,
                      submissionError: () =>
                          interventionService.lastInterventionError,
                      onSubmit: (entry) async {
                        final saved =
                            await interventionService.recordFixAndResolve(
                          notificationId: item.id,
                          parameter: entry.parameter,
                          currentValue: entry.currentValue,
                          currentStatus: item.currentStatus,
                          actionType: entry.actionType,
                          amount: entry.amount,
                          notes: entry.notes,
                          reservoirVolumeL: entry.reservoirVolumeL,
                        );
                        if (!context.mounted) return saved;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              saved
                                  ? 'Intervention recorded. Waiting for three stable readings.'
                                  : interventionService.lastInterventionError ??
                                      'Unable to save the intervention. The alert remains active.',
                            ),
                          ),
                        );
                        return saved;
                      },
                    );
                  },
                  onViewAllTap: () {
                    overlayEntry.remove();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            ),
          ),
        ],
      );
      },
    );

    Overlay.of(context).insert(overlayEntry);
  }

  /// Opens the Settings screen from the profile avatar.
  void _openSettings(BuildContext context) {
    if (title == 'Settings') return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = compactLayout || Responsive.isMobile(context);
    final iconSize = isMobile ? 35.0 : 40.0;
    final GlobalKey bellKey = GlobalKey();

    // On mobile there's no room next to the title, so the action is ignored
    // here (the screen shows it under the header instead).
    final Widget? action = isMobile ? null : titleAction;

    // Room for the title + action. A wider action (e.g. button + timestamp)
    // needs more space on desktop than on tablet.
    final double titleSectionWidth = action == null
        ? 340
        : (Responsive.isDesktop(context) ? 600 : 480);

    final Widget titleText = Text(
      isMobile ? mobileTitle ?? title : title,
      maxLines: isMobile && mobileTitle != null ? 2 : 1,
      // On mobile the title is scaled to fit (below) rather than cut off.
      overflow: isMobile ? TextOverflow.visible : TextOverflow.ellipsis,
      softWrap: false,
      style: AppTextStyles.pageHeading.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: isMobile ? 18 : 24,
      ),
    );

    // Mobile: shrink the title just enough to show it in full.
    final Widget titleLabel = isMobile
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: titleText,
          )
        : titleText;

    final Widget titleSection = Row(
      children: [
        // Hamburger Menu Button
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: isMobile ? 36 : 44,
            height: isMobile ? 36 : 44,
            decoration: const BoxDecoration(
              color: AppColors.iconCircle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu,
              color: Colors.white,
              size: isMobile ? 18 : 22,
            ),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),

        // Page title, with the optional action right next to it
        if (action == null)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: titleLabel,
            ),
          )
        else ...[
          Flexible(child: titleLabel),
          const SizedBox(width: 16),
          action,
        ],
      ],
    );

    final Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isMobile)
          SizedBox(
            width: titleSectionWidth,
            child: titleSection,
          )
        else
          Expanded(child: titleSection),

        // Search Control
        if (!isMobile) ...[
          // Takes the leftover space, but the search itself is capped and
          // right-aligned so it always sits beside the bell.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kSearchMaxWidth),
                child: HeaderSearchField(
                  onHistoryDateSelected: onHistoryDateSelected,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ] else ...[
          // No Spacer here: the title takes all the leftover width, so it
          // only shrinks when it truly doesn't fit.
          _iconCircle(
            Icons.search,
            () => showMobileSearchSheet(
              context,
              onHistoryDateSelected: onHistoryDateSelected,
            ),
            size: iconSize,
          ),
          const SizedBox(width: 8),
        ],

        // Bell Notification Button
        Container(
          key: bellKey,
          child: onBellTap != null
              ? _iconCircle(Icons.notifications_none, onBellTap!,
                  size: iconSize, tinted: true)
              : AdminAlertBell(
                  size: iconSize,
                  tinted: true,
                  fallback: () {
                    if (isMobile) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    } else {
                      showNotificationOverlay(context, bellKey);
                    }
                  },
                ),
        ),

        // User Profile Info
        if (!isMobile) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onProfileTap ?? () => _openSettings(context),
            child: ValueListenableBuilder<UserProfile?>(
              valueListenable: appProfile,
              builder: (context, liveProfile, _) {
                final shownProfile = liveProfile ?? profile;
                final name = (shownProfile?.name ?? '').trim();
                final initial =
                    name.isEmpty ? '' : name.substring(0, 1).toUpperCase();

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.iconCircle,
                      child: initial.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shownProfile?.name ?? '',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          shownProfile?.roleLabel ?? '',
                          style: AppTextStyles.cardMeta.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ] else ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfileTap ?? () => _openSettings(context),
            child: ValueListenableBuilder<UserProfile?>(
              valueListenable: appProfile,
              builder: (context, liveProfile, _) {
                final name = ((liveProfile ?? profile)?.name ?? '').trim();
                final initial =
                    name.isEmpty ? '' : name.substring(0, 1).toUpperCase();

                return CircleAvatar(
                  radius: iconSize / 2,
                  backgroundColor: AppColors.iconCircle,
                  child: initial.isEmpty
                      ? Icon(Icons.person,
                          color: Colors.white, size: iconSize * 0.5)
                      : Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ],
    );

    return row;
  }

  Widget _iconCircle(
    IconData icon,
    VoidCallback onTap, {
    double size = 40,
    bool tinted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tinted ? _kBellTint : AppColors.iconCircle,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: tinted ? AppColors.iconCircle : Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

class AdminAlertBell extends StatefulWidget {
  final double size;
  final VoidCallback fallback;

  /// Soft green circle with a dark green icon (desktop/tablet header).
  final bool tinted;

  const AdminAlertBell({
    super.key,
    required this.size,
    required this.fallback,
    this.tinted = false,
  });

  @override
  State<AdminAlertBell> createState() => AdminAlertBellState();
}

class AdminAlertBellState extends State<AdminAlertBell> {
  final NotificationService service = NotificationService();
  RealtimeChannel? channel;
  int unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    channel = service.subscribeToAdminAlerts(onAlert: handleAlert);
  }

  Future<void> handleAlert() async {
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      final count = await service.unreadAdminAlertCount();
      if (mounted) setState(() => unread = count);
    } catch (_) {}
  }

  @override
  void dispose() {
    final ch = channel;
    if (ch != null && supabaseClient != null) {
      supabaseClient!.removeChannel(ch);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: widget.fallback,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.tinted ? _kBellTint : AppColors.iconCircle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              color: widget.tinted ? AppColors.iconCircle : Colors.white,
              size: widget.size * 0.5,
            ),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: -2,
            top: -4,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: Colors.red,
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
      ],
    );
  }
}
