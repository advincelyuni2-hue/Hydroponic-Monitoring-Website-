import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../controllers/reports_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_header.dart';

class GenerateReportScreen extends StatefulWidget {
  final ReportsController controller;

  const GenerateReportScreen({super.key, required this.controller});

  @override
  State<GenerateReportScreen> createState() => GenerateReportScreenState();
}

class GenerateReportScreenState extends State<GenerateReportScreen> {
  bool isGenerating = false;

  ReportsController get _c => widget.controller;

  /// Changes whenever a checkbox changes, which rebuilds the preview.
  String get _previewKey => [
        _c.includeSensorLogs,
        _c.includeCalibrationLogs,
        _c.includePhOptimization,
        _c.includeEcOptimization,
        _c.includeAllAnalytics,
      ].join('-');

  Future<Uint8List> _buildPreview(PdfPageFormat format) => _c.buildPdfBytes();

  Future<void> onGeneratePdf() async {
    setState(() => isGenerating = true);
    try {
      await _c.generatePdfReport();
      if (!mounted) return;
      _snack('PDF report generated successfully!');
    } catch (error) {
      if (!mounted) return;
      _snack('Unable to generate the PDF: $error');
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeader(title: 'Generate report', profile: null),
                  const SizedBox(height: 24),
                  if (isMobile)
                    Column(
                      children: [
                        SizedBox(height: 480, child: _buildPdfPreviewArea()),
                        const SizedBox(height: 20),
                        _buildConfigSidebar(isMobile),
                      ],
                    )
                  else
                    SizedBox(
                      height: 640,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: _buildPdfPreviewArea()),
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
            );
          },
        ),
      ),
    );
  }

  /// Live preview of the real PDF, like a print preview.
  Widget _buildPdfPreviewArea() {
    return Container(
      width: double.infinity,
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
                  'Letter • PDF',
                  style: AppTextStyles.cardMeta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: PdfPreview(
                key: ValueKey(_previewKey),
                build: _buildPreview,
                useActions: false,
                allowPrinting: false,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                maxPageWidth: 560,
                scrollViewDecoration:
                    BoxDecoration(color: AppColors.calloutBackground),
                pdfPreviewPageDecoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                loadingWidget: const CircularProgressIndicator(),
                onError: (context, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Unable to build the preview.\n$error',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
              ),
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
          _checkboxTile(
            title: 'Sensor history logs',
            value: _c.includeSensorLogs,
            onChanged: _c.toggleSensorLogs,
          ),
          _checkboxTile(
            title: 'Calibration history logs',
            value: _c.includeCalibrationLogs,
            onChanged: _c.toggleCalibrationLogs,
          ),
          _checkboxTile(
            title: 'pH optimization results',
            value: _c.includePhOptimization,
            onChanged: _c.togglePhOptimization,
          ),
          _checkboxTile(
            title: 'EC optimization results',
            value: _c.includeEcOptimization,
            onChanged: _c.toggleEcOptimization,
          ),
          _checkboxTile(
            title: 'All analytics and graphs',
            value: _c.includeAllAnalytics,
            onChanged: _c.toggleAllAnalytics,
          ),
          if (isMobile) const SizedBox(height: 24) else const Spacer(),
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
                      side: BorderSide(
                        color: AppColors.accentGreen,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.accentGreen,
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