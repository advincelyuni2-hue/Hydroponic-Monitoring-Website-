import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/app_state.dart';

<<<<<<< HEAD

=======
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

<<<<<<< HEAD

=======
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
const List<NavItem> kNavItems = [
  NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
  NavItem(icon: Icons.show_chart, label: 'Forecasts'),
  NavItem(icon: Icons.receipt_long_outlined, label: 'History logs'),
  NavItem(icon: Icons.description_outlined, label: 'Reports'),
];

<<<<<<< HEAD

=======
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
const List<NavItem> kNavFooterItems = [
  NavItem(icon: Icons.settings_outlined, label: 'Settings'),
  NavItem(icon: Icons.help_outline, label: 'Help'),
];

const NavItem kAdminNavItem =
    NavItem(icon: Icons.admin_panel_settings_outlined, label: 'Admin settings');

class SideNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

<<<<<<< HEAD
  const SideNav({super.key, required this.selectedIndex, required this.onSelect});
=======
  const SideNav(
      {super.key, required this.selectedIndex, required this.onSelect});
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBackground,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < kNavItems.length; i++)
            _NavTile(
              item: kNavItems[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          const Divider(color: Colors.white30, height: 32),
          for (final item in kNavFooterItems)
            _NavTile(
              item: item,
              selected: false,
<<<<<<< HEAD
              onTap: () => onSelect(kNavItems.length + kNavFooterItems.indexOf(item)),
=======
              onTap: () =>
                  onSelect(kNavItems.length + kNavFooterItems.indexOf(item)),
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
            ),
          if (appProfile.value?.isAdmin == true)
            _NavTile(
              item: kAdminNavItem,
<<<<<<< HEAD
              selected: selectedIndex == kNavItems.length + kNavFooterItems.length,
=======
              selected:
                  selectedIndex == kNavItems.length + kNavFooterItems.length,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
              onTap: () => onSelect(kNavItems.length + kNavFooterItems.length),
            ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

<<<<<<< HEAD
  const _NavTile({required this.item, required this.selected, required this.onTap});
=======
  const _NavTile(
      {required this.item, required this.selected, required this.onTap});
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
<<<<<<< HEAD
        color: selected ? AppColors.sidebarSelectedBackground : Colors.transparent,
=======
        color:
            selected ? AppColors.sidebarSelectedBackground : Colors.transparent,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
<<<<<<< HEAD
                  color: selected ? AppColors.primaryButton : AppColors.sidebarText,
=======
                  color: selected
                      ? AppColors.primaryButton
                      : AppColors.sidebarText,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: AppTextStyles.body.copyWith(
<<<<<<< HEAD
                    color: selected ? const Color(0xFF1A1A1A) : AppColors.sidebarText,
=======
                    color: selected
                        ? const Color(0xFF1A1A1A)
                        : AppColors.sidebarText,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
