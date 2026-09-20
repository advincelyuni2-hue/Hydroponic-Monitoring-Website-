import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../controllers/reports_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_analytics_card.dart';
import '../widgets/report_prediction_card.dart';
import '../widgets/ph_range_card.dart';
import '../widgets/ec_range_card.dart';
import '../widgets/target_distribution_card.dart';
import '../widgets/alerts_frequency_card.dart';
import '../widgets/sensor_health_card.dart';
import '../utils/responsive.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  late final ReportsController controller;

  @override
  void initState() {
    super.initState();
    controller = ReportsController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleGenerate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating Report...')),
    );
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(selectedIndex: 3),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleGenerate,
        backgroundColor: AppColors.primaryButton,
        icon: const Icon(Icons.description, color: Colors.white, size: 20),
        label: Text(
          'Generate report',
          style: AppTextStyles.button.copyWith(fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.errorMessage!,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: controller.loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final isMobile = Responsive.isMobile(context);
            final isDesktop = Responsive.isDesktop(context);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                isMobile ? 96 : 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(title: 'Reports', profile: controller.profile),
                  const SizedBox(height: 24),
                  _buildTopSummaryRow(isDesktop),
                  const SizedBox(height: 24),
                  _buildDistributionAndAlertsSection(isMobile),
                  const SizedBox(height: 24),
                  _buildVisualAnalyticsSection(isMobile),
                  const SizedBox(height: 24),
                  _buildRangeConfigSection(isMobile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopSummaryRow(bool isDesktop) {
    final summary = controller.summary;

    final phCard = ReportSummaryCard(
      label: 'Avg pH (30d)',
      value: summary.avgPh.toStringAsFixed(1),
      badgeText: summary.phStatus,
      badgeColor: AppColors.statusCardGreen,
    );

    final ecCard = ReportSummaryCard(
      label: 'Avg EC (30d)',
      value: summary.avgEc.toStringAsFixed(1),
      unit: 'mS/cm',
      badgeText: summary.ecStatus,
      badgeColor: AppColors.statusCardGreen,
    );

    final alertsCard = ReportSummaryCard(
      label: 'Critical alerts',
      value: summary.criticalAlertsCount.toString(),
      badgeText: summary.alertsPeriod,
      badgeColor: AppColors.alertBackground,
      badgeTextColor: AppColors.alertText,
    );

    final sensorCard = SensorHealthCard(sensors: controller.sensorHealthList);

    if (!isDesktop) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: phCard),
              const SizedBox(width: 12),
              Expanded(child: ecCard),
            ],
          ),
          const SizedBox(height: 12),
          alertsCard,
          const SizedBox(height: 12),
          sensorCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: phCard),
        const SizedBox(width: 12),
        Expanded(flex: 1, child: ecCard),
        const SizedBox(width: 12),
        Expanded(flex: 1, child: alertsCard),
        const SizedBox(width: 12),
        Expanded(flex: 3, child: sensorCard),
      ],
    );
  }

  Widget _buildDistributionAndAlertsSection(bool isMobile) {
  final card1 = TargetDistributionCard(
    data: controller.targetDistribution,
    selectedParam: controller.selectedDistributionParam,
    onParamChanged: controller.setDistributionParam,
  );

  final card2 = AlertFrequencyCard(
    alerts: controller.alertFrequency,
    fixedCount: controller.fixedAlertsCount,
    activeCount: controller.activeAlertsCount,
  );

  if (isMobile) {
    return Column(
      children: [card1, const SizedBox(height: 16), card2],
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

  Widget _buildVisualAnalyticsSection(bool isMobile) {
    final card1 = ReportAnalyticsCard(
      selectedParameter: controller.selectedParameter,
      selectedTimeframe: controller.selectedTimeframe,
      points: controller.trendPoints,
      minThreshold: controller.selectedParameter == 'pH'
          ? controller.phRange.start
          : controller.ecRange.start,
      maxThreshold: controller.selectedParameter == 'pH'
          ? controller.phRange.end
          : controller.ecRange.end,
      onParameterChanged: controller.setParameter,
      onTimeframeChanged: controller.setTimeframe,
    );

    final card2 = ReportPredictionCard(
      points: controller.predictionPoints,
      selectedParameter: controller.selectedParameter,
    );

    if (isMobile) {
      return Column(
        children: [card1, const SizedBox(height: 16), card2],
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

  Widget _buildRangeConfigSection(bool isMobile) {
    final phCard = PhRangeCard(
      phRange: controller.phRange,
      onChanged: controller.updatePhRange,
      onSave: _handleSave,
      onRevert: controller.revertRanges,
    );

    final ecCard = EcRangeCard(
      ecRange: controller.ecRange,
      onChanged: controller.updateEcRange,
      onSave: _handleSave,
      onRevert: controller.revertRanges,
    );

    if (isMobile) {
      return Column(
        children: [phCard, const SizedBox(height: 16), ecCard],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: phCard),
        const SizedBox(width: 20),
        Expanded(child: ecCard),
      ],
    );
  }
}