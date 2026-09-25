import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/parameter_status_card.dart';
import '../widgets/forecast_chart_card.dart';
import '../widgets/notification_tile.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../utils/responsive.dart';
import 'forecasting_dashboard_screen.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _controller = DashboardController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openForecastingScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForecastingDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(selectedIndex: 0),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_controller.errorMessage!, style: AppTextStyles.body),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _controller.loadDashboard,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final isMobile = Responsive.isMobile(context);

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(title: 'Dashboard', profile: _controller.profile),
                  const SizedBox(height: 24),
                  _buildParameterStatusSection(isMobile),
                  const SizedBox(height: 24),
                  _buildInsightAndNotificationsSection(isMobile),
                  const SizedBox(height: 24),
                  _buildForecastSection(isMobile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildParameterStatusSection(bool isMobile) {
    final statuses = _controller.parameterStatuses;
    final cardColors = [
      AppColors.statusCardGreen,
      AppColors.statusCardYellow,
      AppColors.statusCardGreen,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parameter Status', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 16),
          isMobile
              ? Column(
                  children: [
                    for (int i = 0; i < statuses.length; i++) ...[
                      ParameterStatusCard(
                        data: statuses[i],
                        backgroundColor: cardColors[i % cardColors.length],
                      ),
                      if (i != statuses.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < statuses.length; i++) ...[
                      Expanded(
                        child: ParameterStatusCard(
                          data: statuses[i],
                          backgroundColor: cardColors[i % cardColors.length],
                        ),
                      ),
                      if (i != statuses.length - 1) const SizedBox(width: 16),
                    ],
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildInsightAndNotificationsSection(bool isMobile) {
    final insightCard = _buildLatestInsightCard();
    final notificationsCard = _buildNotificationsCard(pushFooterToBottom: !isMobile);

    if (isMobile) {
      return Column(
        children: [
          insightCard,
          const SizedBox(height: 16),
          notificationsCard,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: insightCard),
          const SizedBox(width: 16),
          Expanded(child: notificationsCard),
        ],
      ),
    );
  }

  Widget _buildLatestInsightCard() {
    final insight = _controller.latestInsight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest Insight', style: AppTextStyles.sectionTitle),
          const Divider(height: 24),
          if (insight != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.alertText, size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(insight.warningTitle, style: AppTextStyles.alert),
                      ),
                    ],
                  ),
                ),
                Text(insight.expectedIn, style: AppTextStyles.cardMeta),
              ],
            ),
            const SizedBox(height: 4),
            Text(insight.warningDetail, style: AppTextStyles.body),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                children: [
                  Text('Humidity: ${insight.humidity}', style: AppTextStyles.bodyBold),
                  Text('EC Level: ${insight.ecStatus}', style: AppTextStyles.bodyBold),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (appProfile.value?.isAdmin != true) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _showAlertAdminDialog,
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Alert Admin'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _openForecastingScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text('View details', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlertAdminDialog() async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert Admin'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe the issue for the administrator',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send alert'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.isEmpty || !mounted) return;
    try {
      await NotificationService().sendAdminAlert(message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert sent to an administrator.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to send the alert right now.')),
        );
      }
    }
  }

  Widget _buildNotificationsCard({required bool pushFooterToBottom}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Notifications', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 16),
          for (final n in _controller.notifications)
            NotificationTile(
              notification: n,
              onTap: () => _showNotifications(),
            ),
          if (pushFooterToBottom) const Spacer() else const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showNotifications,
              child: Text('View all notifications', style: AppTextStyles.cardMeta),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All notifications'),
        content: Text('${_controller.notifications.length} recent notifications available.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildForecastSection(bool isMobile) {
    final phCard = ForecastChartCard(
      title: 'pH Forecast Overview',
      points: _controller.phForecast,
      onExpand: _openForecastingScreen,
    );
    final ecCard = ForecastChartCard(
      title: 'EC Forecast Overview',
      points: _controller.ecForecast,
      onExpand: _openForecastingScreen,
    );

    if (isMobile) {
      return Column(
        children: [
          phCard,
          const SizedBox(height: 16),
          ecCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: phCard),
        const SizedBox(width: 16),
        Expanded(child: ecCard),
      ],
    );
  }
}
