import 'package:flutter/material.dart';
import '../controllers/reports_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_header.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  State<GenerateReportScreen> createState() => GenerateReportScreenState();
}

class GenerateReportScreenState extends State<GenerateReportScreen> {
  final ReportsController _controller = ReportsController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      await _controller.generatePdfReport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF report downloaded.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate report: $error')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isMobile = Responsive.isMobile(context);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeader(
                    title: 'Generate report',
                    profile: null,
                  ),
                  const SizedBox(height: 24),
                  if (isMobile)
                    Column(
                      children: [
                        _buildPdfPreviewArea(isMobile),
                        const SizedBox(height: 20),
                        _buildConfigSidebar(isMobile),
                      ],
                    )
                  else
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildPdfPreviewArea(isMobile),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 380,
                            child: _buildConfigSidebar(isMobile),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// PDF Document Live Preview Card
  Widget _buildPdfPreviewArea(bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 380 : 580,
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.card(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Document Preview',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusCardGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PDF report',
                  style: AppTextStyles.cardMeta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryButton,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Simulated Page Thumbnail Frame
          Expanded(
            child: Center(
              child: Container(
                width: isMobile ? 220 : 340,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Page Header Mockup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primaryButton,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.inputBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Content Lines / Blocks
                    if (_controller.includeSensorLogs)
                      _previewBlock(
                          'Sensor History Logs', AppColors.primaryButton),
                    if (_controller.includeCalibrationLogs)
                      _previewBlock(
                          'Calibration Logs', AppColors.textSecondary),
                    if (_controller.includePhOptimization)
                      _previewBlock(
                          'pH Optimization Results', const Color(0xFF1599A8)),
                    if (_controller.includeEcOptimization)
                      _previewBlock(
                          'EC Optimization Results', const Color(0xFFF39C12)),
                    if (_controller.includeAllAnalytics)
                      _previewBlock(
                          'Visual Analytics Charts', AppColors.primaryButton),
                    const Spacer(),
                    // Page Footer
                    Center(
                      child: Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.inputBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewBlock(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  /// Right Config Panel
  Widget _buildConfigSidebar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Configuration',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Select items to include in your generated PDF report.',
            style: AppTextStyles.cardMeta,
          ),
          const SizedBox(height: 20),
          // Checklist items
          _checkboxTile(
            title: 'Sensor history logs',
            value: _controller.includeSensorLogs,
            onChanged: _controller.toggleSensorLogs,
          ),
          _checkboxTile(
            title: 'Calibration history logs',
            value: _controller.includeCalibrationLogs,
            onChanged: _controller.toggleCalibrationLogs,
          ),
          _checkboxTile(
            title: 'pH optimization results',
            value: _controller.includePhOptimization,
            onChanged: _controller.togglePhOptimization,
          ),
          _checkboxTile(
            title: 'EC optimization results',
            value: _controller.includeEcOptimization,
            onChanged: _controller.toggleEcOptimization,
          ),
          _checkboxTile(
            title: 'All analytics and graphs',
            value: _controller.includeAllAnalytics,
            onChanged: _controller.toggleAllAnalytics,
          ),
          if (isMobile) ...[
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: _buildExportButton()),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: _buildCancelButton()),
          ] else ...[
            const Spacer(),
            Row(
              children: [
                Expanded(flex: 2, child: _buildExportButton()),
                const SizedBox(width: 12),
                Expanded(child: _buildCancelButton()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generatePdf,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryButton,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        icon: _isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf, size: 20),
        label: Text(
          _isGenerating ? 'Generating...' : 'Export PDF',
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: AppColors.primaryButton,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          'Cancel',
          style: AppTextStyles.button.copyWith(
            color: AppColors.primaryButton,
          ),
        ),
      ),
    );
  }

  Widget _checkboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CheckboxListTile(
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(fontSize: 14),
        ),
        value: value,
        activeColor: AppColors.primaryButton,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        onChanged: onChanged,
      ),
    );
  }
}
