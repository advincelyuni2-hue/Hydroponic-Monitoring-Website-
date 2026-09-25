import 'package:flutter/material.dart';
import '../controllers/forecasting_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/forecasting_chart_card.dart';
import '../widgets/prediction_insights_card.dart';
import '../widgets/report_issue_card.dart';

class ForecastingDashboardScreen extends StatefulWidget {
  const ForecastingDashboardScreen({super.key});

  @override
  State<ForecastingDashboardScreen> createState() =>
      _ForecastingDashboardScreenState();
}

class _ForecastingDashboardScreenState
    extends State<ForecastingDashboardScreen> {
  final ForecastingController _controller = ForecastingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(selectedIndex: 1),
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

            final isDesktop = Responsive.isDesktop(context);
            final isMobile = Responsive.isMobile(context);

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(
                    title: 'Forecasting dashboard',
                    profile: _controller.profile,
                  ),
                  const SizedBox(height: 24),
                  if (!isDesktop) ...[
                    ForecastingChartCard(
                      activeTab: _controller.selectedTab,
                      onTabChanged: _controller.selectTab,
                      selectedHours: _controller.selectedHours,
                      onHoursChanged: _controller.selectHours,
                      points: _controller.chartPoints,
                    ),
                    const SizedBox(height: 16),
                    if (_controller.insightDetail != null)
                      PredictionInsightsCard(
                        detail: _controller.insightDetail!,
                        onApplyFix: _controller.applyFix,
                        onDismiss: _controller.dismissFix,
                      ),
                    const SizedBox(height: 16),
                    ReportIssueCard(onAlertAdmin: () {}),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              if (_controller.insightDetail != null)
                                PredictionInsightsCard(
                                  detail: _controller.insightDetail!,
                                  onApplyFix: _controller.applyFix,
                                  onDismiss: _controller.dismissFix,
                                ),
                              const SizedBox(height: 16),
                              ReportIssueCard(onAlertAdmin: () {}),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 6,
                          child: ForecastingChartCard(
                            activeTab: _controller.selectedTab,
                            onTabChanged: _controller.selectTab,
                            selectedHours: _controller.selectedHours,
                            onHoursChanged: _controller.selectHours,
                            points: _controller.chartPoints,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}