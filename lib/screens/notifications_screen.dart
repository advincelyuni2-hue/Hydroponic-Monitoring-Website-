import 'package:flutter/material.dart';
import '../controllers/notification_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/notification_card_widget.dart';

class NotificationsScreen extends StatefulWidget {
  final String? initialSelectedId;

  const NotificationsScreen({
    super.key,
    this.initialSelectedId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController _controller = NotificationController();
  String selectedTab = 'Active';
  String? highlightedNotificationId;

  @override
  void initState() {
    super.initState();
    highlightedNotificationId = widget.initialSelectedId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCardTap(String id) {
    setState(() {
      if (highlightedNotificationId == id) {
        highlightedNotificationId = null;
      } else {
        highlightedNotificationId = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(selectedIndex: 3),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final filteredList = selectedTab == 'Active'
                ? _controller.activeNotifications
                : _controller.resolvedNotifications;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeader(title: 'Notifications'),
                  const SizedBox(height: 24),

                  // Active / Resolved Tabs
                  Row(
                    children: [
                      _buildTab('Active'),
                      const SizedBox(width: 16),
                      _buildTab('Resolved'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  const SizedBox(height: 20),

                  if (_controller.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filteredList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 64),
                      child: Center(
                        child: Text(
                          'No ${selectedTab.toLowerCase()} notifications found.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = isDesktop ? 3 : (isMobile ? 1 : 2);

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredList.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            mainAxisExtent: 310,
                          ),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return NotificationCardWidget(
                              item: item,
                              isHighlighted:
                                  item.id == highlightedNotificationId,
                              onTap: () => _handleCardTap(item.id),
                              onResolveChanged: (val) =>
                                  _controller.toggleResolve(item, val),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTab(String title) {
    final isActive = selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = title),
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