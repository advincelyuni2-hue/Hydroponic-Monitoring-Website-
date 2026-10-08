import 'package:flutter/material.dart';
import '../controllers/forecasting_controller.dart';
import '../models/monitoring_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/forecasting_chart_card.dart';
import '../widgets/prediction_insights_card.dart';
import '../widgets/report_issue_card.dart';
import '../widgets/alert_admin_dialog.dart';

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

  List<ForecastPoint> _mapToForecastPoint(List<dynamic> points) {
    return points.map((p) {
      if (p is ForecastPoint) return p;
      return ForecastPoint(
        hour: (p.hour as num).toDouble(),
        value: (p.value as num).toDouble(),
        isPredicted: p.isPredicted as bool,
        isFallback: p.isFallback as bool,
      );
    }).toList();
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

            final phPointsMapped = _mapToForecastPoint(_controller.phPoints);
            final ecPointsMapped = _mapToForecastPoint(_controller.ecPoints);

            final insight = _controller.activeInsightDetail;
            final isBothTab = _controller.selectedTab == 'Both';

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
                      points: phPointsMapped,
                      ecPoints: ecPointsMapped,
                      isOffline: _controller.isSensorOffline,
                      latestSensorRecordedAt:
                          _controller.latestSensorRecordedAt,
                    ),
                    const SizedBox(height: 16),
                    if (insight != null)
                      PredictionInsightsCard(
                        detail: insight,
                        onApplyFix: () => _controller.applyFix(insight),
                        onDismiss: () => _controller.dismissFix(insight),
                        showParamSelector: isBothTab,
                        selectedInsightParam:
                            _controller.selectedBothInsightParam,
                        onInsightParamChanged: _controller.setBothInsightParam,
                      ),
                    const SizedBox(height: 16),
                    ReportIssueCard(
                      onAlertAdmin: () => showAlertAdminDialog(
                        context,
                        source: 'Forecasting screen',
                      ),
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT SIDEBAR: SINGLE CLEAN INSIGHT CARD WITH OPTIONAL INNER PILL
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              if (insight != null)
                                PredictionInsightsCard(
                                  detail: insight,
                                  onApplyFix: () =>
                                      _controller.applyFix(insight),
                                  onDismiss: () =>
                                      _controller.dismissFix(insight),
                                  showParamSelector: isBothTab,
                                  selectedInsightParam:
                                      _controller.selectedBothInsightParam,
                                  onInsightParamChanged:
                                      _controller.setBothInsightParam,
                                ),
                              const SizedBox(height: 16),
                              ReportIssueCard(
                                onAlertAdmin: () => showAlertAdminDialog(
                                  context,
                                  source: 'Forecasting screen',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // RIGHT MAIN CHART
                        Expanded(
                          flex: 6,
                          child: ForecastingChartCard(
                            activeTab: _controller.selectedTab,
                            onTabChanged: _controller.selectTab,
                            selectedHours: _controller.selectedHours,
                            onHoursChanged: _controller.selectHours,
                            points: phPointsMapped,
                            ecPoints: ecPointsMapped,
                            isOffline: _controller.isSensorOffline,
                            latestSensorRecordedAt:
                                _controller.latestSensorRecordedAt,
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
