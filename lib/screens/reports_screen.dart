import '../widgets/mobile_graph_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../controllers/reports_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/alerts_frequency_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/report_analytics_card.dart';
import '../widgets/report_prediction_card.dart';
import '../widgets/sensor_health_card.dart';
import '../widgets/target_distribution_card.dart';
import 'generate_report_screen.dart';
import 'forecast_evaluation_table_screen.dart';
import '../services/app_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  final ReportsController _controller = ReportsController();

  bool get _isAdmin => _controller.profile?.role.toLowerCase() == 'admin';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToGenerateReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GenerateReportScreen(controller: _controller),
      ),
    );
  }

  void _navigateToForecastTable() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ForecastEvaluationTableScreen(controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(selectedIndex: 3), // Index 3 is Reports
      floatingActionButton: isMobile
          ? ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _controller.isLoading
                  ? const SizedBox.shrink()
                  : FloatingActionButton.extended(
                      onPressed: _navigateToGenerateReport,
                      backgroundColor: AppColors.primaryButton,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      icon: const Icon(Icons.file_download_outlined, size: 20),
                      label: Text('Export PDF',
                          style: AppTextStyles.bodyBold
                              .copyWith(fontSize: 13, color: Colors.white)),
                    ),
            )
          : null,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24,
                  isMobile ? 16 : 24, isMobile ? 16 : 24, isMobile ? 96 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(
                    title: 'Reports',
                    profile: _controller.profile,
                    compactLayout: isMobile,
                    titleAction: isMobile ? null : _buildHeaderAction(context),
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text('Telemetry last updated',
                            style:
                                AppTextStyles.cardMeta.copyWith(fontSize: 11)),
                        Text(_controller.lastUpdatedTimestamp,
                            style:
                                AppTextStyles.bodyBold.copyWith(fontSize: 12)),
                      ],
                    ),
                  ],
                  SizedBox(height: isMobile ? 16 : 24),
                  if (Responsive.isDesktop(context))
                    _buildDesktopLayout()
                  else
                    _buildMobileLayout(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LAYOUTS
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout() {
    if (_isAdmin) {
      return _BottomAlignedReportColumns(
        sideBySide: true,
        naturalHeightSidebar: true,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._buildMetricCards(),
              const SizedBox(height: 12),
              SensorHealthCard(sensors: _controller.sensorHealthList),
              const SizedBox(height: 10),
              Text(
                '© 2026 Hydroponic Monitoring System',
                textAlign: TextAlign.center,
                style: AppTextStyles.cardMeta.copyWith(fontSize: 12),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTrendsCard(),
              const SizedBox(height: 12),
              _buildPredictionCard(),
            ],
          ),
          _buildAlertFrequencyCard(),
          _buildDistributionCard(),
        ],
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return _BottomAlignedReportColumns(
        sideBySide: constraints.maxWidth - 340 >= 620,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final calibration =
                  SensorHealthCard(sensors: _controller.sensorHealthList);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._buildMetricCards(),
                  const SizedBox(height: 16),
                  if (constraints.hasBoundedHeight)
                    Expanded(child: calibration)
                  else
                    calibration,
                ],
              );
            },
          ),
          _buildTrendsCard(),
          _buildAlertFrequencyCard(),
          _buildDistributionCard(),
        ],
      );
    });
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._buildMetricCards(),
        const SizedBox(height: 16),
        SensorHealthCard(sensors: _controller.sensorHealthList),
        if (_isAdmin) ...[
          const SizedBox(height: 10),
          Text(
            '© 2026 Hydroponic Monitoring System',
            textAlign: TextAlign.center,
            style: AppTextStyles.cardMeta.copyWith(fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        _buildTrendsCard(),
        const SizedBox(height: 16),
        if (_isAdmin) ...[
          _buildPredictionCard(),
          const SizedBox(height: 16),
        ],
        _buildAlertFrequencyCard(),
        const SizedBox(height: 16),
        _buildDistributionCard(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED PIECES
  // ---------------------------------------------------------------------------

  /// [expand] = true wraps each card in an Expanded so the four cards share
  /// whatever fixed height the parent gives them. Only use it when the parent
  /// column has a bounded height (see the LayoutBuilder in the desktop layout).
  List<Widget> _buildMetricCards({bool expand = false}) {
    final summary = _controller.summary;

    Widget wrap(Widget card) => expand ? Expanded(child: card) : card;

    return [
      wrap(_buildMetricCard(
        title: 'AVG PH',
        value: summary.avgPh.toStringAsFixed(6),
        status: summary.phStatus,
        isWarning: summary.phStatus.toLowerCase() != 'in range',
        expand: expand,
      )),
      const SizedBox(height: 12),
      wrap(_buildMetricCard(
        title: 'AVG EC',
        value: '${summary.avgEc.toStringAsFixed(6)} mS/cm',
        status: summary.ecStatus,
        isWarning: summary.ecStatus.toLowerCase() != 'stable',
        expand: expand,
      )),
      const SizedBox(height: 12),
      wrap(_buildMetricCard(
        title: 'AVG TEMP',
        value: formatTemperature(summary.avgTemp),
        status: summary.tempStatus,
        isWarning: summary.tempStatus.toLowerCase() != 'in range',
        expand: expand,
      )),
      const SizedBox(height: 12),
      wrap(_buildMetricCard(
        title: 'CRITICAL ALERTS',
        value: '${summary.criticalAlertsCount}',
        status: summary.alertsPeriod,
        isWarning: summary.criticalAlertsCount > 0,
        detail: _controller.alertsDateRange,
        expand: expand,
      )),
    ];
  }

  Widget _buildTrendsCard() => MobileGraphCard(
        title: 'Historical Telemetry Trends',
        actionLabel: 'View Historical Telemetry Trends',
        listenable: _controller,
        builder: (_) => _buildTrendsGraph(),
      );

  Widget _buildTrendsGraph() {
    final isPh = _controller.selectedParameter == 'pH';
    return ReportsAnalyticsCard(
      compact: false,
      selectedParameter: _controller.selectedParameter,
      selectedTimeframe: _controller.selectedTimeframe,
      points: _controller.trendPoints,
      minThreshold:
          isPh ? _controller.phRange.start : _controller.ecRange.start,
      maxThreshold: isPh ? _controller.phRange.end : _controller.ecRange.end,
      onParameterChanged: _controller.setParameter,
      onTimeframeChanged: _controller.setTimeframe,
    );
  }

  Widget _buildPredictionCard() => MobileGraphCard(
        title: 'Forecast Model Evaluation',
        actionLabel: 'View Forecast Model Evaluation',
        listenable: _controller,
        builder: (_) => _buildPredictionGraph(),
      );

  Widget _buildPredictionGraph() {
    return ReportPredictionCard(
      evaluation: _controller.modelEvaluation,
      selectedParameter: _controller.selectedPredictionParameter,
      selectedHorizon: _controller.selectedPredictionHorizon,
      onHorizonChanged: _controller.setPredictionHorizon,
      isLoading: _controller.isEvaluationLoading,
      errorMessage: _controller.evaluationError,
      onParameterChanged: _controller.setPredictionParameter,
      onViewTable: _navigateToForecastTable,
    );
  }

  Widget _buildAlertFrequencyCard() {
    return AlertFrequencyCard(
      horizontal: _isAdmin && !Responsive.isDesktop(context),
      alerts: _controller.alertFrequency,
      dateRangeLabel: _controller.alertsDateRange,
    );
  }

  Widget _buildDistributionCard() {
    return TargetDistributionCard(
      legendBelow: _isAdmin && !Responsive.isDesktop(context),
      data: _controller.targetDistribution,
      selectedParam: _controller.selectedDistributionParam,
      isLoading: _controller.isDistributionLoading,
      errorMessage: _controller.distributionError,
      dateRangeLabel: _controller.alertsDateRange,
      onParamChanged: _controller.setDistributionParam,
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER ACTION (Export PDF + telemetry timestamp)
  // ---------------------------------------------------------------------------

  Widget _buildExportPdfButton() {
    return OutlinedButton.icon(
      onPressed: _navigateToGenerateReport,
      icon: const Icon(Icons.file_download_outlined, size: 16),
      label: const Text('Export PDF'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.iconCircle,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.iconCircle, width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: AppTextStyles.bodyBold.copyWith(fontSize: 13),
      ),
    );
  }

  Widget _buildHeaderAction(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildExportPdfButton(),
        const SizedBox(width: 14),
        Container(width: 1, height: 30, color: Colors.black12),
        const SizedBox(width: 14),
        _buildTelemetryStatus(_controller.lastUpdatedTimestamp),
      ],
    );
  }

  Widget _buildTelemetryStatus(String timestamp) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: Color(0xFF1E6B13),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Telemetry last updated',
              style: AppTextStyles.cardMeta.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timestamp,
              style: AppTextStyles.bodyBold.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // METRIC CARD
  // ---------------------------------------------------------------------------

  Widget _buildMetricValueRow(List<Widget> children) {
    if (_isAdmin || !Responsive.isDesktop(context)) {
      return Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: children,
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String status,
    required bool isWarning,
    String? detail,
    bool expand = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: AppDecorations.card(),
      child: Column(
        // When the card is stretched, keep its content centered.
        mainAxisAlignment:
            expand ? MainAxisAlignment.center : MainAxisAlignment.start,
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
          _buildMetricValueRow(
            [
              Text(
                value,
                style: AppTextStyles.pageHeading.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isWarning
                      ? AppColors.alertBackground
                      : AppColors.statusCardGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.cardMeta.copyWith(
                    color:
                        isWarning ? AppColors.alertText : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              style: AppTextStyles.cardMeta.copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

// Measure content at its existing width, then line up the bottom cards.
// This avoids intrinsic sizing, which the charts' LayoutBuilders do not support.
//
// Children: natural-height left column, right graph(s), alert frequency,
// and distribution. Admin keeps the sidebar at its natural height.
class _BottomAlignedReportColumns extends MultiChildRenderObjectWidget {
  final bool sideBySide;
  final bool naturalHeightSidebar;

  const _BottomAlignedReportColumns({
    required this.sideBySide,
    this.naturalHeightSidebar = false,
    required super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBottomAlignedReportColumns(sideBySide, naturalHeightSidebar);

  @override
  void updateRenderObject(
      BuildContext context, _RenderBottomAlignedReportColumns renderObject) {
    if (renderObject.sideBySide != sideBySide ||
        renderObject.naturalHeightSidebar != naturalHeightSidebar) {
      renderObject.naturalHeightSidebar = naturalHeightSidebar;
      renderObject.sideBySide = sideBySide;
      renderObject.markNeedsLayout();
    }
  }
}

class _RenderBottomAlignedReportColumns extends RenderStack {
  _RenderBottomAlignedReportColumns(this.sideBySide, this.naturalHeightSidebar);

  bool sideBySide;
  bool naturalHeightSidebar;

  @override
  void performLayout() {
    final children = getChildrenAsList();
    if (naturalHeightSidebar) {
      final cardWidth = (constraints.maxWidth - 340 - 16) / 2;
      final widths = [320.0, constraints.maxWidth - 340, cardWidth, cardWidth];
      for (var i = 0; i < children.length; i++) {
        children[i].layout(BoxConstraints.tightFor(width: widths[i]),
            parentUsesSize: true);
      }
      final topHeight = children[1].size.height;
      final bottomHeight = children[2].size.height > children[3].size.height
          ? children[2].size.height
          : children[3].size.height;
      for (var i = 2; i < children.length; i++) {
        children[i].layout(
            BoxConstraints.tightFor(width: cardWidth, height: bottomHeight),
            parentUsesSize: true);
      }
      final offsets = [
        Offset.zero,
        const Offset(340, 0),
        Offset(340, topHeight + 12),
        Offset(340 + cardWidth + 16, topHeight + 12),
      ];
      for (var i = 0; i < children.length; i++) {
        (children[i].parentData as StackParentData).offset = offsets[i];
      }
      final rightBottom = topHeight + 12 + bottomHeight;
      size = constraints.constrain(Size(
          constraints.maxWidth,
          children[0].size.height > rightBottom
              ? children[0].size.height
              : rightBottom));
      return;
    }
    final rightWidth = constraints.maxWidth - 340;
    final cardWidth = sideBySide ? (rightWidth - 16) / 2 : rightWidth;
    final widths = [320.0, rightWidth, cardWidth, cardWidth];
    for (var i = 0; i < children.length; i++) {
      children[i].layout(BoxConstraints.tightFor(width: widths[i]),
          parentUsesSize: true);
    }
    final bottomTop = children[1].size.height + 20;
    double rightBottom;
    if (sideBySide) {
      final naturalHeight = children[2].size.height > children[3].size.height
          ? children[2].size.height
          : children[3].size.height;
      final leftRemainder = children[0].size.height - bottomTop;
      final height =
          naturalHeight > leftRemainder ? naturalHeight : leftRemainder;
      for (var i = 2; i < children.length; i++) {
        children[i].layout(
            BoxConstraints.tightFor(width: cardWidth, height: height),
            parentUsesSize: true);
      }
      rightBottom = bottomTop + height;
      children[0].layout(
          BoxConstraints.tightFor(width: widths[0], height: rightBottom),
          parentUsesSize: true);
    } else {
      rightBottom =
          bottomTop + children[2].size.height + 16 + children[3].size.height;
    }
    final offsets = [
      Offset.zero,
      const Offset(340, 0),
      Offset(340, bottomTop),
      sideBySide
          ? Offset(340 + cardWidth + 16, bottomTop)
          : Offset(340, bottomTop + children[2].size.height + 16),
    ];
    for (var i = 0; i < children.length; i++) {
      (children[i].parentData as StackParentData).offset = offsets[i];
    }
    size = constraints.constrain(Size(
        constraints.maxWidth,
        children[0].size.height > rightBottom
            ? children[0].size.height
            : rightBottom));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
