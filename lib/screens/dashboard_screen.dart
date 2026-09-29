import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../controllers/dashboard_controller.dart';
import '../models/forecasting_models.dart';
import '../widgets/parameter_status_card.dart';
import '../widgets/forecast_chart_card.dart';
import '../widgets/notification_tile.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../utils/responsive.dart';
import 'forecasting_dashboard_screen.dart';
import 'notifications_screen.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../utils/manila_time.dart';

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
                        backgroundColor: _statusColor(statuses[i].status),
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
                          backgroundColor: _statusColor(statuses[i].status),
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return AppColors.alertBackground;
      case 'warning':
        return AppColors.statusCardYellow;
      default:
        return AppColors.statusCardGreen;
    }
  }

  Widget _buildInsightAndNotificationsSection(bool isMobile) {
    final insightCard = _buildLatestInsightCard();
    final notificationsCard =
        _buildNotificationsCard(pushFooterToBottom: !isMobile);

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
    final insightColor = insight?.statusBadge == 'Critical'
        ? AppColors.alertText
        : insight?.statusBadge == 'Warning'
            ? const Color(0xFFD97706)
            : AppColors.primaryButton;
    final insightIcon = insight?.statusBadge == 'Normal'
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;
    final useTwoColumns = MediaQuery.sizeOf(context).width >= 1200;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest Insight', style: AppTextStyles.sectionTitle),
          const Divider(height: 24),
          if (insight != null) ...[
            _buildLatestInsightContent(
              insight: insight,
              insightIcon: insightIcon,
              insightColor: insightColor,
              useTwoColumns: useTwoColumns,
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

  Widget _buildLatestInsightContent({
    required PredictionInsightDetail insight,
    required IconData insightIcon,
    required Color insightColor,
    required bool useTwoColumns,
  }) {
    final warningPanel = _buildInsightWarningPanel(
      insight: insight,
      insightIcon: insightIcon,
      insightColor: insightColor,
    );
    final predictionsPanel = _buildPredictionSummariesPanel();

    if (!useTwoColumns) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          warningPanel,
          if (_controller.forecastSummaries.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: AppColors.cardBorder),
            const SizedBox(height: 12),
            predictionsPanel,
          ],
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: warningPanel),
          if (_controller.forecastSummaries.isNotEmpty) ...[
            const SizedBox(width: 16),
            VerticalDivider(
              color: AppColors.cardBorder,
              thickness: 1,
              width: 1,
            ),
            const SizedBox(width: 16),
            Expanded(child: predictionsPanel),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightWarningPanel({
    required PredictionInsightDetail insight,
    required IconData insightIcon,
    required Color insightColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Warning & status', style: AppTextStyles.bodyBold),
            Text('12-hour outlook', style: AppTextStyles.cardMeta),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(insightIcon, color: insightColor, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${insight.statusLabel}: ${insight.statusBadge}',
                style: AppTextStyles.alert.copyWith(color: insightColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(insight.warningText, style: AppTextStyles.body),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temperature: ${insight.temperature}',
                style: AppTextStyles.bodyBold,
              ),
              const SizedBox(height: 6),
              Text(
                'Related reading: ${insight.ecLevel}',
                style: AppTextStyles.bodyBold,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(insight.calloutText, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildPredictionSummariesPanel() {
    if (_controller.forecastSummaries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prediction summaries', style: AppTextStyles.bodyBold),
        if (_controller.forecastGeneratedAt != null) ...[
          const SizedBox(height: 3),
          Text(
            'Generated ${formatManilaDateTime(_controller.forecastGeneratedAt!)}',
            style: AppTextStyles.cardMeta,
          ),
        ],
        const SizedBox(height: 10),
        for (final summary in _controller.forecastSummaries) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.calloutBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusCardGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${summary.hoursAhead}h',
                        style: AppTextStyles.cardMeta.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'pH ${summary.phValue.toStringAsFixed(2)}  •  '
                        'EC ${summary.ecValue.toStringAsFixed(2)} mS/cm',
                        style: AppTextStyles.bodyBold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Predicted for ${formatManilaDateTime(summary.predictedFor)}',
                  style: AppTextStyles.cardMeta,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
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
              onDelete: !(_controller.profile?.isAdmin ?? false) || n.id.isEmpty
                  ? null
                  : () async {
                      try {
                        await NotificationService().deleteNotification(n.id);
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Unable to delete notification.')),
                          );
                        }
                      }
                    },
            ),
          if (pushFooterToBottom)
            const Spacer()
          else
            const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showNotifications,
              child:
                  Text('View all notifications', style: AppTextStyles.cardMeta),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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
