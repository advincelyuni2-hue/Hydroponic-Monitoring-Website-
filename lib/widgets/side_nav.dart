import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/app_state.dart';

class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

const List<NavItem> kNavItems = [
  NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),       // Index 0
  NavItem(icon: Icons.show_chart, label: 'Forecasts'),               // Index 1
  NavItem(icon: Icons.receipt_long_outlined, label: 'History logs'), // Index 2
  NavItem(icon: Icons.description_outlined, label: 'Reports'),        // Index 3
];

const List<NavItem> kNavFooterItems = [
  NavItem(icon: Icons.settings_outlined, label: 'Settings'),         // Index 4
  NavItem(icon: Icons.help_outline, label: 'Help'),                   // Index 5
];

const NavItem kAdminNavItem = NavItem(
  icon: Icons.admin_panel_settings_outlined,
  label: 'Admin settings',                                           // Index 6
);

class SideNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const SideNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBackground,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < kNavItems.length; i++)
            NavTile(
              item: kNavItems[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          const Divider(color: Colors.white30, height: 32),
          for (int j = 0; j < kNavFooterItems.length; j++) ...[
            NavTile(
              item: kNavFooterItems[j],
              selected: (kNavItems.length + j) == selectedIndex,
              onTap: () => onSelect(kNavItems.length + j),
            ),
          ],
          if (appProfile.value?.isAdmin == true)
            NavTile(
              item: kAdminNavItem,
              selected: selectedIndex ==
                  (kNavItems.length + kNavFooterItems.length),
              onTap: () => onSelect(
                  kNavItems.length + kNavFooterItems.length),
            ),
        ],
      ),
    );
  }
}

class NavTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const NavTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selected
            ? AppColors.sidebarSelectedBackground
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected
                      ? AppColors.primaryButton
                      : AppColors.sidebarText,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: AppTextStyles.body.copyWith(
                    color: selected
                        ? const Color(0xFF1A1A1A)
                        : AppColors.sidebarText,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}