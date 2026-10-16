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
import '../widgets/custom_calendar_popup.dart';
import '../services/monitoring_service.dart';
import 'dart:async';

class GenerateReportScreen extends StatefulWidget {
  final ReportsController controller;
  const GenerateReportScreen({super.key, required this.controller});

  @override
  State<GenerateReportScreen> createState() => GenerateReportScreenState();
}

class GenerateReportScreenState extends State<GenerateReportScreen> {
  bool isGenerating = false;
  DateTime selectedDate = DateTime.now();
  CalendarMode selectedMode = CalendarMode.daily;
  Timer? _previewRefreshTimer;
  int _previewRevision = 0;
  late String _lastPreviewKey;

  DateTimeRange get _selectedReportRange {
    final start =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    switch (selectedMode) {
      case CalendarMode.daily:
        return DateTimeRange(
            start: start, end: start.add(const Duration(days: 1)));
      case CalendarMode.weekly:
        return DateTimeRange(
            start: start, end: start.add(const Duration(days: 7)));
      case CalendarMode.monthly:
        return DateTimeRange(
          start: DateTime(start.year, start.month),
          end: DateTime(start.year, start.month + 1),
        );
    }
  }

  HistoryAggregation get _reportAggregation => switch (selectedMode) {
        CalendarMode.daily => HistoryAggregation.daily,
        CalendarMode.weekly => HistoryAggregation.eightHours,
        CalendarMode.monthly => HistoryAggregation.daily,
      };

  ReportsController get _c => widget.controller;

  bool get isAllSelected =>
      _c.includeSensorLogs &&
      _c.includeCalibrationLogs &&
      _c.includePhOptimization &&
      _c.includeEcOptimization &&
      _c.includeAllAnalytics &&
      _c.includeInterventionLogs &&
      _c.includeInsightsAndDecisionSupport;

  String get _previewKey => [
        selectedMode,
        _c.includeInterventionLogs,
        _c.includeSensorLogs,
        _c.includeCalibrationLogs,
        _c.includePhOptimization,
        _c.includeEcOptimization,
        _c.includeAllAnalytics,
        _c.includeInsightsAndDecisionSupport,
        selectedDate.toIso8601String(),
      ].join('-');

  @override
  void initState() {
    super.initState();
    _lastPreviewKey = _previewKey;
    _c.addListener(_onReportOptionsChanged);
  }

  @override
  void didUpdateWidget(covariant GenerateReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onReportOptionsChanged);
      _lastPreviewKey = _previewKey;
      _c.addListener(_onReportOptionsChanged);
    }
  }

  void _onReportOptionsChanged() {
    final currentKey = _previewKey;
    if (currentKey == _lastPreviewKey) return;

    _lastPreviewKey = currentKey;
    _queuePreviewRefresh();
  }

  void _queuePreviewRefresh() {
    _previewRefreshTimer?.cancel();
    _previewRefreshTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _previewRevision++);
      }
    });
  }

  @override
  void dispose() {
    _previewRefreshTimer?.cancel();
    _c.removeListener(_onReportOptionsChanged);
    super.dispose();
  }

  Future<Uint8List> buildPreview(PdfPageFormat format) {
    return _c.buildPdfBytes(
      dateRange: _selectedReportRange,
      aggregation: _reportAggregation,
    );
  }

  void _toggleSelectAll() {
    final newValue = !isAllSelected;
    setState(() {
      if (_c.includeSensorLogs != newValue) _c.toggleSensorLogs(newValue);
      if (_c.includeCalibrationLogs != newValue) {
        _c.toggleCalibrationLogs(newValue);
      }
      if (_c.includeInterventionLogs != newValue) {
        _c.toggleInterventionLogs(newValue);
      }
      if (_c.includePhOptimization != newValue) {
        _c.togglePhOptimization(newValue);
      }
      if (_c.includeEcOptimization != newValue) {
        _c.toggleEcOptimization(newValue);
      }
      if (_c.includeAllAnalytics != newValue) _c.toggleAllAnalytics(newValue);
      if (_c.includeInsightsAndDecisionSupport != newValue) {
        _c.toggleInsightsAndDecisionSupport(newValue);
      }
    });
  }

  void _openCalendarPopup() {
    showDialog(
      context: context,
      builder: (context) => CustomCalendarPopup(
        mode: selectedMode,
        initialDate: selectedDate,
        onDateSelected: (date, _) {
          setState(() {
            selectedDate = date;
            _lastPreviewKey = _previewKey;
            _queuePreviewRefresh();
          });
        },
      ),
    );
  }

  String _formatDateLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatSelectedPeriodLabel() {
    final range = _selectedReportRange;
    final lastDay = range.end.subtract(const Duration(days: 1));

    switch (selectedMode) {
      case CalendarMode.daily:
        return _formatDateLabel(range.start);
      case CalendarMode.weekly:
      case CalendarMode.monthly:
        return '${_formatDateLabel(range.start)} – ${_formatDateLabel(lastDay)}';
    }
  }

  Future<void> onGeneratePdf() async {
    setState(() => isGenerating = true);
    try {
      await _c.generatePdfReport(
        dateRange: _selectedReportRange,
        aggregation: _reportAggregation,
      );
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
                key: ValueKey(_previewRevision),
                build: buildPreview,
                useActions: false,
                allowPrinting: false,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                maxPageWidth: 560,
                dpi: 60,
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
          const SizedBox(height: 16),

          // Date timeframe section with History Logs style date button pill
          Text(
            'Date timeframe',
            style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButton<CalendarMode>(
            value: selectedMode,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: CalendarMode.daily,
                child: Text('Daily'),
              ),
              DropdownMenuItem(
                value: CalendarMode.weekly,
                child: Text('Weekly'),
              ),
              DropdownMenuItem(
                value: CalendarMode.monthly,
                child: Text('Monthly'),
              ),
            ],
            onChanged: (mode) {
              if (mode == null || mode == selectedMode) return;

              setState(() => selectedMode = mode);
              _lastPreviewKey = _previewKey;
              _queuePreviewRefresh();
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: _openCalendarPopup,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.calloutBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppColors.primaryButton,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatSelectedPeriodLabel(),
                      style: AppTextStyles.cardMeta.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 14),

          // Report Sections Header with Select All / Deselect All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Report Sections',
                style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
              ),
              InkWell(
                onTap: _toggleSelectAll,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    isAllSelected ? 'Deselect all' : 'Select all',
                    style: AppTextStyles.cardMeta.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Checklist items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _checkboxTile(
                    title: 'Sensor history logs',
                    value: _c.includeSensorLogs,
                    onChanged: (v) => _c.toggleSensorLogs(v ?? false),
                  ),
                  _checkboxTile(
                    title: 'Calibration history logs',
                    value: _c.includeCalibrationLogs,
                    onChanged: (v) => _c.toggleCalibrationLogs(v ?? false),
                  ),
                  _checkboxTile(
                    title: 'Intervention history logs',
                    value: _c.includeInterventionLogs,
                    onChanged: (v) => _c.toggleInterventionLogs(v),
                  ),
                  _checkboxTile(
                    title: 'pH optimization results',
                    value: _c.includePhOptimization,
                    onChanged: (v) => _c.togglePhOptimization(v ?? false),
                  ),
                  _checkboxTile(
                    title: 'EC optimization results',
                    value: _c.includeEcOptimization,
                    onChanged: (v) => _c.toggleEcOptimization(v ?? false),
                  ),
                  _checkboxTile(
                    title: 'All analytics and graphs',
                    value: _c.includeAllAnalytics,
                    onChanged: (v) => _c.toggleAllAnalytics(v ?? false),
                  ),
                  _checkboxTile(
                    title: 'Insights and Decision Support',
                    value: _c.includeInsightsAndDecisionSupport,
                    onChanged: (v) =>
                        _c.toggleInsightsAndDecisionSupport(v ?? false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Buttons
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
      padding: const EdgeInsets.symmetric(vertical: 2),
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
