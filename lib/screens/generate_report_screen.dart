import 'package:flutter/material.dart';
import '../controllers/reports_controller.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/report_generation_card.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  final ReportsController _controller = ReportsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(selectedIndex: 3),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(title: 'Generate report'),
                const SizedBox(height: 24),
                ReportGenerationCard(
                  includeSensorLogs: _controller.includeSensorLogs,
                  includeCalibrationLogs: _controller.includeCalibrationLogs,
                  includePhOptimization: _controller.includePhOptimization,
                  includeEcOptimization: _controller.includeEcOptimization,
                  includeAllAnalytics: _controller.includeAllAnalytics,
                  onToggleSensorLogs: _controller.toggleSensorLogs,
                  onToggleCalibrationLogs: _controller.toggleCalibrationLogs,
                  onTogglePhOptimization: _controller.togglePhOptimization,
                  onToggleEcOptimization: _controller.toggleEcOptimization,
                  onToggleAllAnalytics: _controller.toggleAllAnalytics,
                  onDismiss: () => Navigator.of(context).pop(),
                  onGenerate: () async {
                    await _controller.generatePdfReport();
                    if (!context.mounted) return;
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF report ready.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}