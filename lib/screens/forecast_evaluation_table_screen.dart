import 'package:flutter/material.dart';

import '../controllers/reports_controller.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/forecast_evaluation_table.dart';

class ForecastEvaluationTableScreen extends StatelessWidget {
  final ReportsController controller;

  const ForecastEvaluationTableScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(selectedIndex: 3),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeader(
                    title: 'Prediction records', profile: controller.profile),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to reports'),
                ),
                const SizedBox(height: 14),
                ForecastEvaluationTable(
                  evaluation: controller.modelEvaluation,
                  selectedParameter: controller.selectedPredictionParameter,
                  selectedHorizon: controller.selectedPredictionHorizon,
                  isLoading: controller.isEvaluationLoading,
                  errorMessage: controller.evaluationError,
                  onParameterChanged: controller.setPredictionParameter,
                  onHorizonChanged: controller.setPredictionHorizon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
