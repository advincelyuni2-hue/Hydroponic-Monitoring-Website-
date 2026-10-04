import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
<<<<<<< HEAD
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../services/user_service.dart';
import '../utils/responsive.dart';
import '../widgets/live_pulse_dot.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../services/notification_service.dart';
import '../services/supabase_client.dart';
=======
import '../models/notification_models.dart';
import '../screens/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_client.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'notification_overlay_widget.dart';
import '../screens/add_log_screen.dart';
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

class AppHeader extends StatelessWidget {
  final String title;
  final UserProfile? profile;
  final VoidCallback? onAddTap;
  final VoidCallback? onBellTap;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    required this.title,
    this.profile,
    this.onAddTap,
    this.onBellTap,
    this.onProfileTap,
  });

<<<<<<< HEAD
=======
  void _showNotificationOverlay(BuildContext context, GlobalKey bellKey) {
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
            child: NotificationOverlayWidget(
              notifications: const [],
              onNotificationTap: (item) {
                overlayEntry.remove();
              },
              onViewAllTap: () {
                overlayEntry.remove();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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
    // Already on Settings, so don't stack another copy
    if (title == 'Settings') return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openAddLog(BuildContext context) {
  // Already on the Add a log page, so don't stack another copy
  if (title == 'Add a log') return;

  if (Responsive.isMobile(context)) {
    showRecordFixDialog(context, onSubmit: (entry) {
      // TODO: save entry
    });
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddLogScreen()),
    );
  }
}

>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final iconSize = isMobile ? 35.0 : 40.0;
    final iconGap = isMobile ? 6.0 : 12.0;
<<<<<<< HEAD

    return Row(
      children: [
        // Hamburger — the only way the side nav ever opens.
=======
    final GlobalKey bellKey = GlobalKey();

    return Row(
      children: [
        // Hamburger Menu Button
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: isMobile ? 36 : 44,
            height: isMobile ? 36 : 44,
            decoration: const BoxDecoration(
              color: AppColors.iconCircle,
              shape: BoxShape.circle,
            ),
<<<<<<< HEAD
            child:
                Icon(Icons.menu, color: Colors.white, size: isMobile ? 18 : 22),
=======
            child: Icon(
              Icons.menu,
              color: Colors.white,
              size: isMobile ? 18 : 22,
            ),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),

<<<<<<< HEAD
        // Title
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.pageHeading.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: isMobile ? 18 : 24,
=======
        // Page Title
        Flexible(
          child: Text(
            title,
            style: AppTextStyles.pageHeading.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: isMobile ? 18 : 24,
              overflow: TextOverflow.ellipsis,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
            ),
          ),
        ),

<<<<<<< HEAD
        SizedBox(width: isMobile ? 8 : 10),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 10, vertical: isMobile ? 4 : 5),
          decoration: BoxDecoration(
            color: AppColors.statusCardGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LivePulseDot(size: isMobile ? 5 : 6),
              const SizedBox(width: 6),
              Text(
                'Live',
                style: AppTextStyles.cardMeta.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Search Bar (Desktop) or Search Icon (Mobile)
=======
        const Spacer(),

        // Search Control
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
        if (!isMobile) ...[
          Expanded(
            flex: 2,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppDecorations.card(radius: 24),
              child: Row(
                children: [
<<<<<<< HEAD
                  Icon(Icons.search, color: AppColors.textSecondary, size: 20),
=======
                  // Fixed: Removed const here because AppColors.textSecondary is a dynamic getter
                  Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
          const SizedBox(width: 24),
        ] else ...[
<<<<<<< HEAD
          _iconCircle(Icons.search, () => _openMobileSearch(context),
              size: iconSize),
          SizedBox(width: iconGap),
        ],

        // Actions & Profile
        _iconCircle(Icons.add, onAddTap ?? () {}, size: iconSize),
        SizedBox(width: iconGap),
        onBellTap != null
            ? _iconCircle(Icons.notifications_none, onBellTap!, size: iconSize)
            : AdminAlertBell(
                size: iconSize,
                fallback: () => _showNotifications(context),
              ),
        if (!isMobile) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onProfileTap ?? () => _showProfileMenu(context),
=======
          _iconCircle(
            Icons.search,
            () => _openMobileSearch(context),
            size: iconSize,
          ),
          SizedBox(width: iconGap),
        ],

        // Action Buttons
        _iconCircle(Icons.add, onAddTap ?? () => _openAddLog(context),
    size: iconSize),
        SizedBox(width: iconGap),

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
                      _showNotificationOverlay(context, bellKey);
                    }
                  },
                ),
        ),

        if (!isMobile) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onProfileTap ?? () => _openSettings(context),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.iconCircle,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.name ?? '',
                style: AppTextStyles.bodyBold.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                profile?.roleLabel ?? '',
                style: AppTextStyles.cardMeta.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ] else ...[
          SizedBox(width: iconGap),
          GestureDetector(
<<<<<<< HEAD
            onTap: onProfileTap ?? () => _showProfileMenu(context),
=======
            onTap: onProfileTap ?? () => _openSettings(context),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
                Text('Search',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 12),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: AppTextStyles.cardMeta,
<<<<<<< HEAD
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textSecondary),
=======
                    // Fixed: Removed const here because AppColors.textSecondary is a dynamic getter
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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

<<<<<<< HEAD
  void _showNotifications(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('You have 2 recent notifications to review.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
=======
  // No longer used by default (the avatar now opens Settings), but kept in
  // case something else still calls it.
  void showProfileMenu(BuildContext context) {
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    final profile = appProfile.value;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(profile?.name ?? 'User'),
              subtitle: Text(profile?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () async {
                await AuthService().logout();
                if (!context.mounted) return;
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconCircle(IconData icon, VoidCallback onTap, {double size = 40}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
<<<<<<< HEAD
            color: AppColors.iconCircle, shape: BoxShape.circle),
=======
          color: AppColors.iconCircle,
          shape: BoxShape.circle,
        ),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
<<<<<<< HEAD
  State<AdminAlertBell> createState() => _AdminAlertBellState();
}

class _AdminAlertBellState extends State<AdminAlertBell> {
  final NotificationService _service = NotificationService();
  RealtimeChannel? _channel;
  int _unread = 0;
=======
  State<AdminAlertBell> createState() => AdminAlertBellState();
}

class AdminAlertBellState extends State<AdminAlertBell> {
  final NotificationService service = NotificationService();
  RealtimeChannel? channel;
  int unread = 0;
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

  @override
  void initState() {
    super.initState();
    _refresh();
<<<<<<< HEAD
    if (appProfile.value?.isAdmin == true) {
      _channel = _service.subscribeToAdminAlerts(onAlert: _handleAlert);
    }
  }

  Future<void> _handleAlert() async {
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new employee alert was received.')),
    );
=======
    channel = service.subscribeToAdminAlerts(onAlert: handleAlert);
  }

  Future<void> handleAlert() async {
    await _refresh();
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  }

  Future<void> _refresh() async {
    try {
<<<<<<< HEAD
      final count = await _service.unreadAdminAlertCount();
      if (mounted) setState(() => _unread = count);
=======
      final count = await service.unreadAdminAlertCount();
      if (mounted) setState(() => unread = count);
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    } catch (_) {}
  }

  @override
  void dispose() {
<<<<<<< HEAD
    final channel = _channel;
    if (channel != null && supabaseClient != null) {
      supabaseClient!.removeChannel(channel);
=======
    final ch = channel;
    if (ch != null && supabaseClient != null) {
      supabaseClient!.removeChannel(ch);
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
<<<<<<< HEAD
            child: Icon(Icons.notifications_none,
                color: Colors.white, size: widget.size * 0.5),
          ),
        ),
        if (_unread > 0)
=======
            child: Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: widget.size * 0.5,
            ),
          ),
        ),
        if (unread > 0)
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
          Positioned(
            right: -2,
            top: -4,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: Colors.red,
              child: Text(
<<<<<<< HEAD
                _unread > 9 ? '9+' : '$_unread',
=======
                unread > 9 ? '9+' : '$unread',
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
      ],
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
