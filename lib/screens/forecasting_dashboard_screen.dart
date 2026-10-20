import '../widgets/hydro_loading_screen.dart';
import '../widgets/sensor_offline_state.dart';
import '../widgets/app_footer.dart';
import '../widgets/mobile_graph_card.dart';
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
  const ForecastingDashboardScreen({super.key, this.graphOnly = false});
  final bool graphOnly;

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

  Widget _buildForecastingGraph() => ForecastingChartCard(
              isLoading: _controller.isChartLoading,
              activeTab: _controller.selectedTab,
              onTabChanged: _controller.selectTab,
              selectedHours: _controller.selectedHours,
              onHoursChanged: _controller.selectHours,
              points: _mapToForecastPoint(_controller.phPoints),
              ecPoints: _mapToForecastPoint(_controller.ecPoints),
              isOffline: _controller.isSensorOffline,
              isCalibrating: _controller.isCalibrating,
              forecastIssue: _controller.forecastIssue,
              latestSensorRecordedAt: _controller.latestSensorRecordedAt,
            );

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
    if (widget.graphOnly && Responsive.isMobile(context)) {
      return MobileGraphPage(title: 'Forecasting', backgroundColor: Colors.white,
        listenable: _controller, builder: (context) {
          if (_controller.isLoading) return const HydroLoadingScreen();
          if (_controller.errorMessage != null) {
            return Column(children: [
              const Align(alignment: Alignment.centerLeft, child: BackButton()),
              Expanded(child: Center(child: Text(_controller.errorMessage!))),
            ]);
          }
          return _buildForecastingGraph();
        });
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ListenableBuilder(listenable: _controller,
        builder: (context, _) => AppDrawer(selectedIndex: 1,
          isOffline: _controller.isLoading ? null : _controller.isSensorOffline,
          isCalibrating: _controller.isCalibrating,
          lastReceived: _controller.latestSensorRecordedAt)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const HydroLoadingScreen();
            }

            if (_controller.errorMessage != null) {
              return AppFooterScrollView(
                centerContent: true,
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


            final insight = _controller.activeInsightDetail;
            final isBothTab = _controller.selectedTab == 'Both';

            final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final fitDesktop = isDesktop && textScale <= 1.2;
            Widget buildInsights({bool fillHeight = false}) {
              if (_controller.isSensorOffline && !_controller.isCalibrating) {
                return PausedPredictionInsightsCard(showParamSelector: isBothTab,
                  selectedParameter: _controller.selectedBothInsightParam,
                  onParameterChanged: _controller.setBothInsightParam);
              }
              return IndexedStack(
                index: _controller.isPhInsight ? 0 : 1,
                sizing: fillHeight ? StackFit.expand : StackFit.loose,
                alignment: Alignment.topLeft,
                children: [
                  for (final isPh in [true, false])
                    if ((isPh ? _controller.phInsightDetail : _controller.ecInsightDetail) != null)
                      PredictionInsightsCard(
                        detail: (isPh ? _controller.phInsightDetail : _controller.ecInsightDetail)!,
                        forecastPoints: isPh ? _controller.phInsightPoints : _controller.ecInsightPoints,
                        currentPh: _controller.currentPh,
                        currentEc: _controller.currentEc,
                        showParamSelector: isBothTab,
                        selectedInsightParam: _controller.selectedBothInsightParam,
                        onInsightParamChanged: _controller.setBothInsightParam,
                        fitHeight: fillHeight,
                      )
                    else
                      const SizedBox.shrink(),
                ],
              );
            }
            final chart = MobileGraphCard(
              title: 'Forecasting',
              pageBackground: Colors.white,
              description: 'Shows recent readings and model forecasts for pH, EC, or both over the selected horizon.',
              actionLabel: 'View Forecasting Graph',
              listenable: _controller,
              builder: (_) => _buildForecastingGraph(),
            );
            final report = ReportIssueCard(
              onAlertAdmin: () => showAlertAdminDialog(
                context, source: 'Forecasting screen',
              ),
            );
            return Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                children: [
                  AppHeader(title: 'Forecasting dashboard', profile: _controller.profile),
                  if (_controller.isSensorOffline && !_controller.isCalibrating) ...[
                    const SizedBox(height: 12),
                    SensorOfflineBanner(lastReceived: _controller.latestSensorRecordedAt),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(builder: (context, available) {
                      if (!fitDesktop) {
                        return AppFooterScrollView(
                          child: Column(children: [
                            chart,
                            const SizedBox(height: 12),
                            if (insight != null || (_controller.isSensorOffline && !_controller.isCalibrating)) buildInsights(),
                            const SizedBox(height: 12),
                            report,
                          ]),
                        );
                      }
                      return AppFooterScrollView(
                        child: SizedBox(
                          height: (available.maxHeight -
                                  AppFooter.heightFor(context, available.maxWidth))
                              .clamp(640.0 * textScale, double.infinity),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(children: [
                                  if (insight != null || (_controller.isSensorOffline && !_controller.isCalibrating))
                                    Expanded(child: buildInsights(fillHeight: true))
                                  else
                                    const Spacer(),
                                  const SizedBox(height: 12),
                                  report,
                                ]),
                              ),
                              const SizedBox(width: 20),
                              Expanded(flex: 6, child: chart),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
