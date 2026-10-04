import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_models.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../services/supabase_client.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'notification_overlay_widget.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final UserProfile? profile;
  final VoidCallback? onBellTap;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    required this.title,
    this.profile,
    this.onBellTap,
    this.onProfileTap,
  });

  void showNotificationOverlay(BuildContext context, GlobalKey bellKey) {
    final renderBox =
        bellKey.currentContext?.findRenderObject() as RenderBox?;
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
      builder: (context) => Stack(
        children: [
          // Dismiss overlay when clicking outside
          GestureDetector(
            onTap: () => overlayEntry.remove(),
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: offset.dy + size.height + 8,
            right: MediaQuery.of(context).size.width - offset.dx - size.width,
            child: StreamBuilder<List<AppNotificationItem>>(
              stream: NotificationService().streamNotificationItems(),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                return NotificationOverlayWidget(
                  notifications: notifications,
                  onNotificationTap: (item) {
                    overlayEntry.remove();
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
        ],
      ),
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
    final isMobile = Responsive.isMobile(context);
    final iconSize = isMobile ? 35.0 : 40.0;
    final GlobalKey bellKey = GlobalKey();

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

        // Page Title with automatic font scaling for longer text
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: AppTextStyles.pageHeading.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isMobile ? 18 : 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isMobile)
          SizedBox(
            width: 340,
            child: titleSection,
          )
        else
          Expanded(child: titleSection),

        const Spacer(),

        // Search Control
        if (!isMobile) ...[
          Expanded(
            flex: 2,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppDecorations.card(radius: 24),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: AppTextStyles.cardMeta,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ] else ...[
          _iconCircle(
            Icons.search,
            () => _openMobileSearch(context),
            size: iconSize,
          ),
          const SizedBox(width: 8),
        ],

        // Bell Notification Button
        Container(
          key: bellKey,
          child: onBellTap != null
              ? _iconCircle(Icons.notifications_none, onBellTap!,
                  size: iconSize)
              : AdminAlertBell(
                  size: iconSize,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.iconCircle,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile?.name ?? '',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      profile?.roleLabel ?? '',
                      style: AppTextStyles.cardMeta.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfileTap ?? () => _openSettings(context),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.iconCircle,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ),
        ],
      ],
    );
  }

  void _openMobileSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: AppTextStyles.cardMeta,
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _iconCircle(IconData icon, VoidCallback onTap, {double size = 40}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.iconCircle,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}

class AdminAlertBell extends StatefulWidget {
  final double size;
  final VoidCallback fallback;

  const AdminAlertBell({
    super.key,
    required this.size,
    required this.fallback,
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
            decoration: const BoxDecoration(
              color: AppColors.iconCircle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              color: Colors.white,
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