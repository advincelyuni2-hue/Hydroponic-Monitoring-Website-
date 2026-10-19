import '../widgets/app_footer.dart';
import 'package:flutter/material.dart';

import '../controllers/reports_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/forecast_evaluation_table.dart';

class ForecastEvaluationTableScreen extends StatefulWidget {
  final ReportsController controller;

  const ForecastEvaluationTableScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ForecastEvaluationTableScreen> createState() =>
      _ForecastEvaluationTableScreenState();
}

class _ForecastEvaluationTableScreenState
    extends State<ForecastEvaluationTableScreen> {
  DateTimeRange? _dateFilter;

  void _selectHistoryDate(DateTime date, bool wholeMonth) {
    final start = wholeMonth
        ? DateTime(date.year, date.month)
        : DateTime(date.year, date.month, date.day);
    final end = wholeMonth
        ? DateTime(date.year, date.month + 1)
        : start.add(const Duration(days: 1));
    setState(() => _dateFilter = DateTimeRange(start: start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isMobile = Responsive.isMobile(context);
    final compactHeader = !Responsive.isDesktop(context) ||
        MediaQuery.textScalerOf(context).scale(13) > 18;
    final backButton = OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.iconCircle,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.iconCircle, width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: AppTextStyles.bodyBold.copyWith(fontSize: 13),
      ),
      child: const Text('Back to reports'),
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(selectedIndex: 3),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: AppColors.primaryButton,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              icon: const Icon(Icons.arrow_back, size: 20),
              label: Text('Back to reports',
                  style: AppTextStyles.bodyBold
                      .copyWith(fontSize: 13, color: Colors.white)),
            )
          : null,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => AppFooterScrollView(
            showFooter: !controller.isEvaluationLoading,
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 16 : 24,
              isMobile ? 16 : 24,
              isMobile ? 96 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeader(
                  title: 'Prediction records',
                  profile: controller.profile,
                  onHistoryDateSelected: _selectHistoryDate,
                  compactLayout: compactHeader,
                  titleAction: compactHeader ? null : backButton,
                ),
                if (compactHeader && !isMobile) ...[
                  const SizedBox(height: 12),
                  backButton,
                ],
                const SizedBox(height: 14),
                ForecastEvaluationTable(
                  evaluation: controller.modelEvaluation,
                  selectedParameter: controller.selectedPredictionParameter,
                  selectedHorizon: controller.selectedPredictionHorizon,
                  isLoading: controller.isEvaluationLoading,
                  errorMessage: controller.evaluationError,
                  onParameterChanged: controller.setPredictionParameter,
                  onHorizonChanged: controller.setPredictionHorizon,
                  dateFilter: _dateFilter,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
