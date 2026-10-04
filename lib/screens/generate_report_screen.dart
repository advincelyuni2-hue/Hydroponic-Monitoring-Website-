import 'package:flutter/material.dart';
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
  // Checklist Options
  bool includeSensorLogs = true;
  bool includeCalibrationLogs = false;
  bool includePhOptimization = true;
  bool includeEcOptimization = false;
  bool includeAllAnalytics = false;

  bool isGenerating = false;

  void onGeneratePdf() async {
    setState(() => isGenerating = true);
    // Simulate PDF generation/download pipeline
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF Report generated successfully!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header without manual Back Arrow
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
                // IntrinsicHeight forces both cards to stretch to equal height
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT SIDE: PDF Document Preview Area
                      Expanded(
                        flex: 3,
                        child: _buildPdfPreviewArea(isMobile),
                      ),
                      const SizedBox(width: 24),
                      // RIGHT SIDE: Checklist Options & Action Buttons
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
                  '1 Page • PDF',
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
                    if (includeSensorLogs)
                      _previewBlock(
                          'Sensor History Logs', AppColors.primaryButton),
                    if (includeCalibrationLogs)
                      _previewBlock(
                          'Calibration Logs', AppColors.textSecondary),
                    if (includePhOptimization)
                      _previewBlock('pH Optimization Results',
                          const Color(0xFF1599A8)),
                    if (includeEcOptimization)
                      _previewBlock('EC Optimization Results',
                          const Color(0xFFF39C12)),
                    if (includeAllAnalytics)
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
            value: includeSensorLogs,
            onChanged: (val) => setState(() => includeSensorLogs = val ?? false),
          ),
          _checkboxTile(
            title: 'Calibration history logs',
            value: includeCalibrationLogs,
            onChanged: (val) =>
                setState(() => includeCalibrationLogs = val ?? false),
          ),
          _checkboxTile(
            title: 'pH optimization results',
            value: includePhOptimization,
            onChanged: (val) =>
                setState(() => includePhOptimization = val ?? false),
          ),
          _checkboxTile(
            title: 'EC optimization results',
            value: includeEcOptimization,
            onChanged: (val) =>
                setState(() => includeEcOptimization = val ?? false),
          ),
          _checkboxTile(
            title: 'All analytics and graphs',
            value: includeAllAnalytics,
            onChanged: (val) =>
                setState(() => includeAllAnalytics = val ?? false),
          ),

          const Spacer(),

          // Action Buttons: Export PDF on Left, Cancel on Right
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isGenerating ? null : onGeneratePdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    icon: isGenerating
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
                      isGenerating ? 'Generating...' : 'Export PDF',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                ),
              ),
            ],
          ),
        ],
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