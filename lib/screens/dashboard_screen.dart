import '../widgets/app_footer.dart';
import '../widgets/mobile_graph_card.dart';
import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../models/forecasting_models.dart';
import '../models/monitoring_models.dart' show ParameterStatus;
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/parameter_severity.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/dashboard_forecast_overview.dart';
import '../widgets/dashboard_realtime_section.dart';
import '../widgets/dashboard_layout.dart';
import 'forecasting_dashboard_screen.dart';
import '../widgets/dashboard_insight_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _controller = DashboardController();
  final PageStorageBucket _graphStorage = PageStorageBucket();

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
              return AppFooterScrollView(
                centerContent: true,
                child: _buildErrorState(),
              );
            }

            return DashboardLayout(
              header:
                  AppHeader(title: 'Dashboard', profile: _controller.profile),
              realtime: DashboardRealtimeSection(
                statuses: _controller.parameterStatuses,
                isOffline: _controller.isSensorOffline,
                isCalibrating: _controller.isCalibrating,
              ),
              insight: _buildLatestInsightCard(false),
              overview: MobileGraphCard(
                title: 'Forecast Overview',
                description: 'Shows recent readings and available model predictions for pH and EC over the selected horizon.',
                actionLabel: 'View Forecast Overview Graph',
                listenable: _controller,
                storageBucket: _graphStorage,
                builder: (_) => _buildForecastOverview(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForecastOverview() => DashboardForecastOverview(
                phPoints: _controller.phForecast,
                ecPoints: _controller.ecForecast,
                summaries: _controller.forecastSummaries,
                generatedAt: _controller.forecastGeneratedAt,
                isOffline: _controller.isSensorOffline,
                isCalibrating: _controller.isCalibrating,
                forecastIssue: _controller.forecastIssue,
                latestSensorRecordedAt: _controller.latestSensorRecordedAt,
                onViewDetails: _openForecastingScreen,
              );

  Widget _buildErrorState() {
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

  Widget _buildLatestInsightCard(bool isMobile) {
    return DashboardInsightCard(
      phForecast: _controller.phForecast,
      ecForecast: _controller.ecForecast,
      summaries: _controller.forecastSummaries,
      parameterStatuses: _controller.parameterStatuses,
      phInsight: _controller.phPredictionInsight,
      ecInsight: _controller.ecPredictionInsight,
      isOffline: _controller.isSensorOffline,
      isCalibrating: _controller.isCalibrating,
      forecastIssue: _controller.forecastIssue,
      onViewDetails: _openForecastingScreen,
    );
  }

  Widget _buildInsightContent(
    PredictionInsightDetail insight,
    PredictionInsightDetail phInsight,
    PredictionInsightDetail ecInsight,
    String displayStatus,
    Color statusColor,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 650;
          final narrativePanel = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: stack
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInsightFactors(insight),
                      const SizedBox(height: 6),
                      _buildInsightDescription(insight),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 4, child: _buildInsightFactors(insight)),
                      const SizedBox(width: 4),
                      Container(
                        width: 1,
                        height: 58,
                        color: AppColors.cardBorder,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 6,
                        child: _buildInsightDescription(insight),
                      ),
                    ],
                  ),
          );
          final predictionsPanel = Container(
            width: stack ? double.infinity : constraints.maxWidth * 0.32,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: statusColor.withValues(alpha: 0.13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Status', style: AppTextStyles.cardMeta),
                      const SizedBox(height: 3),
                      Text(
                        displayStatus,
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: statusColor,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 58,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: AppColors.cardBorder,
                ),
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '12h prediction',
                        style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      _buildPredictedValue(
                        'pH',
                        _predictedInsightValue(phInsight),
                      ),
                      const SizedBox(height: 4),
                      _buildPredictedValue(
                        'EC',
                        '${_predictedInsightValue(ecInsight)} mS/cm',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          return stack
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [predictionsPanel, narrativePanel],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      predictionsPanel,
                      Expanded(child: narrativePanel),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildPredictedValue(String parameter, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          child: Text(parameter, style: AppTextStyles.cardMeta),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyBold,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightFactors(PredictionInsightDetail insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Contributing factors', style: AppTextStyles.bodyBold),
        const SizedBox(height: 4),
        _factorRow('Temperature', formatTempText(insight.temperature)),
        const SizedBox(height: 2),
        _factorRow('EC', insight.ecLevel),
      ],
    );
  }

  Widget _buildInsightDescription(PredictionInsightDetail insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(insight.warningText, style: AppTextStyles.bodySmall),
        const SizedBox(height: 4),
        Text(
          insight.calloutText,
          style: AppTextStyles.cardMeta,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _factorRow(String label, String value) {
    return Wrap(
      spacing: 8,
      runSpacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$label:', style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.bodyBold),
      ],
    );
  }

  String _predictedInsightValue(PredictionInsightDetail insight) {
    if (_controller.forecastSummaries.isEmpty) {
      return insight.currentPh.toStringAsFixed(6);
    }
    final summary = _controller.forecastSummaries.last;
    if (insight.statusLabel.toLowerCase().contains('ec')) {
      return summary.ecValue.toStringAsFixed(6);
    }
    return summary.phValue.toStringAsFixed(6);
  }

  Color _insightColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return AppColors.alertText;
      case 'warning':
        return const Color(0xFFE79A08);
      default:
        return AppColors.primaryButton;
    }
  }

  String _combinedPredictionStatus(
    PredictionInsightDetail phInsight,
    PredictionInsightDetail ecInsight,
  ) {
    if (_controller.forecastSummaries.isNotEmpty) {
      final forecast = _controller.forecastSummaries.last;
      final severities = [
        _predictedSeverity('pH', forecast.phValue),
        _predictedSeverity('EC', forecast.ecValue),
      ];
      if (severities.contains('Critical')) return 'Critical';
      if (severities.contains('Warning')) return 'Warning';
      return 'Stable';
    }

    String normalize(String status) =>
        status.toLowerCase() == 'normal' ? 'Stable' : status;
    final phStatus = normalize(phInsight.statusBadge);
    final ecStatus = normalize(ecInsight.statusBadge);
    return phStatus.toLowerCase() == ecStatus.toLowerCase()
        ? phStatus
        : 'Warning';
  }

  String _predictedSeverity(String parameter, double value) {
    ParameterStatus? configured;
    for (final status in _controller.parameterStatuses) {
      if (status.label.toLowerCase().contains(parameter.toLowerCase())) {
        configured = status;
        break;
      }
    }

    final matches = RegExp(r'\d+(?:\.\d+)?')
        .allMatches(configured?.idealRange ?? '')
        .map((match) => double.tryParse(match.group(0)!))
        .whereType<double>()
        .toList();
    final fallback =
        parameter.toLowerCase() == 'ph' ? const [5.5, 6.5] : const [1.2, 1.8];
    final minimum = matches.length >= 2 ? matches[0] : fallback[0];
    final maximum = matches.length >= 2 ? matches[1] : fallback[1];
    return parameterSeverityLabel(
      classifyParameterValue(
        value: value,
        stableMin: minimum,
        stableMax: maximum,
        warningMargin: 0.5,
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
}
