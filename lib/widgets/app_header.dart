import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../screens/notifications_screen.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'live_pulse_dot.dart';
import 'notification_overlay_widget.dart';

class AppHeader extends StatefulWidget {
  final String title;
  final UserProfile? profile;
  final VoidCallback? onAddTap;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    required this.title,
    this.profile,
    this.onAddTap,
    this.onProfileTap,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  OverlayEntry? _overlayEntry;
  final NotificationService _notificationService = NotificationService();

  void _toggleNotificationOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      // Clear red dot on tap
      _notificationService.markAllAsRead();
      _showOverlay(context);
    }
  }

  void _showOverlay(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _removeOverlay,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: offset.dy + 50,
            right: 24,
            child: StreamBuilder<List<AppNotificationItem>>(
              stream: _notificationService.streamNotifications(),
              builder: (context, snapshot) {
                final liveNotifications = snapshot.data ?? [];

                return NotificationOverlayWidget(
                  notifications: liveNotifications,
                  onNotificationTap: (item) {
                    _removeOverlay();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NotificationsScreen(
                          initialSelectedId: item.id,
                        ),
                      ),
                    );
                  },
                  onViewAllTap: () {
                    _removeOverlay();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
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

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final iconSize = isMobile ? 35.0 : 40.0;
    final iconGap = isMobile ? 6.0 : 12.0;

    return StreamBuilder<List<AppNotificationItem>>(
      stream: _notificationService.streamNotifications(),
      builder: (context, snapshot) {
        final liveNotifications = snapshot.data ?? [];
        // Only show red dot if there are unread active notifications
        final hasUnread =
            liveNotifications.any((n) => !n.isRead && !n.isResolved);

        return Row(
          children: [
            GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                width: isMobile ? 36 : 44,
                height: isMobile ? 36 : 44,
                decoration: const BoxDecoration(
                  color: AppColors.iconCircle,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu,
                    color: Colors.white, size: isMobile ? 18 : 22),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 16),
            Flexible(
              child: Text(
                widget.title,
                style: AppTextStyles.pageHeading
                    .copyWith(fontSize: isMobile ? 18 : 24),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            if (!isMobile) ...[
              Expanded(
                flex: 2,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: AppDecorations.card(radius: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: AppColors.textSecondary, size: 20),
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
              _iconCircle(
                  Icons.search, () => openMobileSearch(context), iconSize),
              SizedBox(width: iconGap),
            ],
            _iconCircle(Icons.add, widget.onAddTap ?? () {}, iconSize),
            SizedBox(width: iconGap),

            // Notification Bell with Red Dot Indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Builder(
                  builder: (bellContext) => _iconCircle(
                    Icons.notifications_none,
                    () => _toggleNotificationOverlay(bellContext),
                    iconSize,
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.alertBorder,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            if (!isMobile) ...[
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.iconCircle,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.profile?.name ?? 'Alveus',
                      style: AppTextStyles.bodyBold),
                  Text(widget.profile?.role ?? 'Employee',
                      style: AppTextStyles.cardMeta),
                ],
              ),
            ] else ...[
              SizedBox(width: iconGap),
              GestureDetector(
                onTap: widget.onProfileTap ?? () {},
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.iconCircle,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void openMobileSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary),
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
      ),
    );
  }

  Widget _iconCircle(IconData icon, VoidCallback onTap, double size) {
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