import 'package:flutter/material.dart';
import '../config/public_page_content.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/manila_time.dart';

class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

const List<NavItem> kNavItems = [
  NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'), // Index 0
  NavItem(icon: Icons.show_chart, label: 'Forecasts'), // Index 1
  NavItem(icon: Icons.receipt_long_outlined, label: 'History logs'), // Index 2
  NavItem(icon: Icons.description_outlined, label: 'Reports'), // Index 3
];

const List<NavItem> kNavFooterItems = [
  NavItem(icon: Icons.settings_outlined, label: 'Settings'), // Index 4
  NavItem(icon: Icons.help_outline, label: 'Help'), // Index 5
];

const NavItem kAdminNavItem = NavItem(
  icon: Icons.admin_panel_settings_outlined,
  label: 'Admin settings', // Index 6
);

class SideNav extends StatelessWidget {
  const SideNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.onClose,
    this.onLogout,
    this.isOffline,
    this.isCalibrating = false,
    this.lastReceived,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onClose;
  final VoidCallback? onLogout;
  final bool? isOffline;
  final bool isCalibrating;
  final DateTime? lastReceived;

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: AppDecorations.card(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log out?',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                'You will need to sign in again to access the monitoring app.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryButton),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'No',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primaryButton,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alertText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Log out',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && onLogout != null) {
      onLogout!();
    }
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF173E0A), Color(0xFF285812)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: ValueListenableBuilder(
              valueListenable: appProfile,
              builder: (context, profile, _) => LayoutBuilder(
                builder: (context, space) {
                  final name = profile?.name.trim();
                  final displayName =
                      name == null || name.isEmpty ? 'Account' : name;

                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: space.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: PublicPageContent.brandLogoAsset == null
                                      ? const Icon(
                                          Icons.eco_outlined,
                                          color: Color(0xFF2D6A0D),
                                        )
                                      : Image.asset(
                                          PublicPageContent.brandLogoAsset!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.eco_outlined,
                                            color: Color(0xFF2D6A0D),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    PublicPageContent.brandName,
                                    style: AppTextStyles.bodyBold.copyWith(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                if (onClose != null)
                                  IconButton(
                                    onPressed: onClose,
                                    tooltip: 'Close menu',
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: .10),
                                    ),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.only(left: 6, bottom: 10),
                              child: Text(
                                'MENU',
                                style: AppTextStyles.cardMeta.copyWith(
                                  color: const Color(0xFFB9E477),
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            for (var i = 0; i < kNavItems.length; i++)
                              NavTile(
                                item: kNavItems[i],
                                selected: selectedIndex == i,
                                onTap: () => onSelect(i),
                              ),
                            const SizedBox(height: 28),
                            const Spacer(),
                            if (isOffline != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isOffline!
                                            ? const Color(0xFFFFC34D)
                                            : const Color(0xFFB9E477),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isCalibrating
                                                ? 'Sensor calibrating'
                                                : isOffline!
                                                    ? 'Sensor offline'
                                                    : 'Sensor online',
                                            style: AppTextStyles.cardMeta.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            lastReceived == null
                                                ? 'No reading received'
                                                : 'Last reading ${formatManilaClockTime(toManilaTime(lastReceived!))}',
                                            style: AppTextStyles.cardMeta.copyWith(
                                              color: const Color(0xFFDCE9CC),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const Divider(color: Colors.white24, height: 16),
                            for (var i = 0; i < kNavFooterItems.length; i++)
                              NavTile(
                                item: kNavFooterItems[i],
                                selected: selectedIndex == i + 4,
                                onTap: () => onSelect(i + 4),
                              ),
                            if (profile?.isAdmin == true)
                              NavTile(
                                item: kAdminNavItem,
                                selected: selectedIndex == 6,
                                onTap: () => onSelect(6),
                              ),
                            const Divider(color: Colors.white24, height: 24),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 17,
                                  backgroundColor: const Color(0xFFB9E477),
                                  child: Text(
                                    displayName.characters.first.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF173E0A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.cardMeta.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (profile != null)
                                        Text(
                                          profile.roleLabel,
                                          style: AppTextStyles.cardMeta.copyWith(
                                            color: const Color(0xFFDCE9CC),
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _confirmLogout(context),
                                  tooltip: 'Log out',
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    size: 20,
                                    color: Color(0xFFDCE9CC),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
}

class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: selected
                        ? const Color(0xFF285812)
                        : const Color(0xFFDCE9CC),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? const Color(0xFF285812)
                            : const Color(0xFFDCE9CC),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}