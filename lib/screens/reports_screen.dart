import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../controllers/reports_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_analytics_card.dart';
import '../widgets/report_prediction_card.dart';
import '../widgets/parameter_config_card.dart';
import '../widgets/report_generation_card.dart';
import '../widgets/target_distribution_card.dart';
import '../widgets/alerts_frequency_card.dart';
import '../widgets/sensor_health_card.dart';
import '../utils/responsive.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsController _controller = ReportsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(selectedIndex: 3),
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
                      onPressed: _controller.loadData,
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
                  AppHeader(
                    title: 'Reports',
                    profile: _controller.profile,
                  ),
                  const SizedBox(height: 24),

  
                  _buildSummarySection(isMobile),
                  const SizedBox(height: 24),

                 
                  _buildVisualAnalyticsSection(isMobile),
                  const SizedBox(height: 24),

                  
                  _buildConfigAndGenerationSection(isMobile),
                  const SizedBox(height: 24),

               
                  _buildDeepInsightsSection(isMobile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummarySection(bool isMobile) {
    final summary = _controller.summary;

    final cards = [
      ReportSummaryCard(
        label: 'Avg pH (30d)',
        value: summary.avgPh.toStringAsFixed(1),
        badgeText: summary.phStatus,
        badgeColor: AppColors.statusCardGreen,
      ),
      ReportSummaryCard(
        label: 'Avg EC (30d)',
        value: summary.avgEc.toStringAsFixed(1),
        unit: 'mS/cm',
        badgeText: summary.ecStatus,
        badgeColor: AppColors.statusCardGreen,
      ),
      ReportSummaryCard(
        label: 'Critical alerts',
        value: summary.criticalAlertsCount.toString(),
        badgeText: summary.alertsPeriod,
        badgeColor: AppColors.alertBackground,
        badgeTextColor: AppColors.alertText,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ))
            .toList(),
      );
    }

    return Row(
      children: cards
          .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildVisualAnalyticsSection(bool isMobile) {
    final card1 = ReportsAnalyticsCard(
      selectedParameter: _controller.selectedParameter,
      selectedTimeframe: _controller.selectedTimeframe,
      points: _controller.trendPoints,
      minThreshold: _controller.selectedParameter == 'pH'
          ? _controller.phRange.start
          : _controller.ecRange.start,
      maxThreshold: _controller.selectedParameter == 'pH'
          ? _controller.phRange.end
          : _controller.ecRange.end,
      onParameterChanged: _controller.setParameter,
      onTimeframeChanged: _controller.setTimeframe,
    );

    final card2 = ReportPredictionCard(
      points: _controller.predictionPoints,
      selectedParameter: _controller.selectedParameter,
    );

    if (isMobile) {
      return Column(
        children: [
          card1,
          const SizedBox(height: 16),
          card2,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: card1),
        const SizedBox(width: 20),
        Expanded(child: card2),
      ],
    );
  }

  Widget _buildConfigAndGenerationSection(bool isMobile) {
    final configCard = ParameterConfigCard(
      phRange: _controller.phRange,
      ecRange: _controller.ecRange,
      onPhChanged: _controller.updatePhRange,
      onEcChanged: _controller.updateEcRange,
      onSave: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved!')),
        );
      },
      onRevert: _controller.revertRanges,
    );

    final generationCard = ReportGenerationCard(
      includeSensorLogs: _controller.includeSensorLogs,
      includeCalibrationLogs: _controller.includeCalibrationLogs,
      includePhOptimization: _controller.includePhOptimization,
      includeEcOptimization: _controller.includeEcOptimization,
      onToggleSensorLogs: _controller.toggleSensorLogs,
      onToggleCalibrationLogs: _controller.toggleCalibrationLogs,
      onTogglePhOptimization: _controller.togglePhOptimization,
      onToggleEcOptimization: _controller.toggleEcOptimization,
      onGenerate: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating Report...')),
        );
      },
    );

    if (isMobile) {
      return Column(
        children: [
          configCard,
          const SizedBox(height: 16),
          generationCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: configCard),
        const SizedBox(width: 20),
        Expanded(child: generationCard),
      ],
    );
  }

  Widget _buildDeepInsightsSection(bool isMobile) {
    final card1 = TargetDistributionCard(
      data: _controller.targetDistribution,
      selectedParam: _controller.selectedDistributionParam,
      onParamChanged: _controller.setDistributionParam,
    );

    final card2 = AlertFrequencyCard(
      alerts: _controller.alertFrequency,
      fixedCount: _controller.fixedAlertsCount,
      activeCount: _controller.activeAlertsCount,
    );

    final card3 = SensorHealthCard(
      sensors: _controller.sensorHealthList,
    );

    if (isMobile) {
      return Column(
        children: [
          card1,
          const SizedBox(height: 16),
          card2,
          const SizedBox(height: 16),
          card3,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: card1),
        const SizedBox(width: 16),
        Expanded(child: card2),
        const SizedBox(width: 16),
        Expanded(child: card3),
      ],
    );
  }
}