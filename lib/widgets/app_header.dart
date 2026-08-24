import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../services/user_service.dart';
import '../utils/responsive.dart';
import '../widgets/live_pulse_dot.dart';

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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final iconSize = isMobile ? 35.0 : 40.0;
    final iconGap = isMobile ? 6.0 : 12.0;

    return Row(
      children: [
        // Hamburger — the only way the side nav ever opens.
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: isMobile ? 36 : 44,
            height: isMobile ? 36 : 44,
            decoration: const BoxDecoration(
              color: AppColors.iconCircle,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu, color: Colors.white, size: isMobile ? 18 : 22),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),

        // Title
        Flexible(
          child: Text(
            title,
            style: AppTextStyles.pageHeading.copyWith(fontSize: isMobile ? 18 : 24),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        SizedBox(width: isMobile ? 8 : 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 4 : 5),
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
        if (!isMobile) ...[
          Expanded(
            flex: 2,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppDecorations.card(radius: 24),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
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
          _iconCircle(Icons.search, () => _openMobileSearch(context), size: iconSize),
          SizedBox(width: iconGap),
        ],

        // Actions & Profile
        _iconCircle(Icons.add, onAddTap ?? () {}, size: iconSize),
        SizedBox(width: iconGap),
        _iconCircle(Icons.notifications_none, onBellTap ?? () {}, size: iconSize),
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
              Text(profile?.name ?? '', style: AppTextStyles.bodyBold),
              Text(profile?.role ?? '', style: AppTextStyles.cardMeta),
            ],
          ),
        ] else ...[
          SizedBox(width: iconGap),
          GestureDetector(
            onTap: onProfileTap ?? () {},
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
                Text('Search', style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 12),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: AppTextStyles.cardMeta,
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
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
        decoration: const BoxDecoration(color: AppColors.iconCircle, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}