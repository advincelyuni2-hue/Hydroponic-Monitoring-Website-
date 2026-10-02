import 'package:flutter/material.dart';
import '../controllers/reports_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/alerts_frequency_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/generate_report_card.dart';
import '../widgets/report_analytics_card.dart';
import '../widgets/report_prediction_card.dart';
import '../widgets/sensor_health_card.dart';
import '../widgets/target_distribution_card.dart';
import 'generate_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  final ReportsController _controller = ReportsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToGenerateReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GenerateReportScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(selectedIndex: 4),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(title: 'Reports', profile: _controller.profile),
                  const SizedBox(height: 24),
                  if (isMobile)
                    _buildMobileLayout()
                  else
                    _buildDesktopLayout(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Desktop Layout:
  /// Left Sidebar Column (320px): Metrics -> Sensor Health -> Target Distribution -> Alert Frequency
  /// Right Main Column: Trend Analytics -> Forecast Chart -> Generate Report Card
  Widget _buildDesktopLayout() {
    final summary = _controller.summary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDEBAR (320px)
        SizedBox(
          width: 320,
          child: Column(
            children: [
              _buildMetricCard(
                title: 'AVG PH',
                value: summary.avgPh.toStringAsFixed(1),
                status: summary.phStatus,
                isWarning: summary.phStatus.toLowerCase() != 'in range',
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: 'AVG EC',
                value: '${summary.avgEc.toStringAsFixed(1)} mS/cm',
                status: summary.ecStatus,
                isWarning: summary.ecStatus.toLowerCase() != 'stable',
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: 'CRITICAL ALERTS',
                value: '${summary.criticalAlertsCount}',
                status: summary.alertsPeriod,
                isWarning: summary.criticalAlertsCount > 0,
              ),
              const SizedBox(height: 20),
              SensorHealthCard(sensors: _controller.sensorHealthList),
              const SizedBox(height: 20),
              TargetDistributionCard(
                data: _controller.targetDistribution,
                selectedParam: _controller.selectedDistributionParam,
                onParamChanged: _controller.setDistributionParam,
              ),
              const SizedBox(height: 20),
              AlertFrequencyCard(
                alerts: _controller.alertFrequency,
                fixedCount: _controller.fixedAlertsCount,
                activeCount: _controller.activeAlertsCount,
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // RIGHT MAIN COLUMN
        Expanded(
          child: Column(
            children: [
              ReportsAnalyticsCard(
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
              ),
              const SizedBox(height: 20),
              ReportPredictionCard(
                points: _controller.predictionPoints,
                selectedParameter: _controller.selectedParameter,
                accuracyText: '95.8% Accuracy',
              ),
              const SizedBox(height: 20),
              GenerateReportCard(
                onGenerateReport: _navigateToGenerateReport,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mobile Layout: Vertical stacked sequence
  Widget _buildMobileLayout() {
    final summary = _controller.summary;

    return Column(
      children: [
        _buildMetricCard(
          title: 'AVG PH',
          value: summary.avgPh.toStringAsFixed(1),
          status: summary.phStatus,
          isWarning: summary.phStatus.toLowerCase() != 'in range',
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: 'AVG EC',
          value: '${summary.avgEc.toStringAsFixed(1)} mS/cm',
          status: summary.ecStatus,
          isWarning: summary.ecStatus.toLowerCase() != 'stable',
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: 'CRITICAL ALERTS',
          value: '${summary.criticalAlertsCount}',
          status: summary.alertsPeriod,
          isWarning: summary.criticalAlertsCount > 0,
        ),
        const SizedBox(height: 16),
        ReportsAnalyticsCard(
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
        ),
        const SizedBox(height: 16),
        ReportPredictionCard(
          points: _controller.predictionPoints,
          selectedParameter: _controller.selectedParameter,
          accuracyText: '95.8% Accuracy',
        ),
        const SizedBox(height: 16),
        GenerateReportCard(
          onGenerateReport: _navigateToGenerateReport,
        ),
        const SizedBox(height: 16),
        SensorHealthCard(sensors: _controller.sensorHealthList),
        const SizedBox(height: 16),
        TargetDistributionCard(
          data: _controller.targetDistribution,
          selectedParam: _controller.selectedDistributionParam,
          onParamChanged: _controller.setDistributionParam,
        ),
        const SizedBox(height: 16),
        AlertFrequencyCard(
          alerts: _controller.alertFrequency,
          fixedCount: _controller.fixedAlertsCount,
          activeCount: _controller.activeAlertsCount,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String status,
    required bool isWarning,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.cardMeta.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.pageHeading.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isWarning
                      ? AppColors.alertBackground
                      : AppColors.statusCardGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.cardMeta.copyWith(
                    color: isWarning ? AppColors.alertText : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}