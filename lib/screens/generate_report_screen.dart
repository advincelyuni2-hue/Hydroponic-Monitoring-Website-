import '../widgets/app_footer.dart';
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

  bool isLandscape = false;

  PdfPageFormat get _selectedPdfFormat =>
      isLandscape ? PdfPageFormat.letter.landscape : PdfPageFormat.letter;

  /// Whether the section list has more content below the visible area.
  /// Drives the soft fade at the bottom edge of the list.
  bool _showBottomFade = false;

  Timer? _previewRefreshTimer;
  int _previewRefreshVersion = 0;
  late String _displayedPreviewKey;
  bool _isRouteTransitionComplete = false;

  @override
  void initState() {
    super.initState();
    _displayedPreviewKey = _previewKey;
    _c.addListener(_schedulePreviewRefresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null &&
          route.animation != null &&
          !route.animation!.isCompleted) {
        void onAnimationStatus(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            route.animation!.removeStatusListener(onAnimationStatus);
            if (mounted) setState(() => _isRouteTransitionComplete = true);
          }
        }

        route.animation!.addStatusListener(onAnimationStatus);
      } else {
        if (mounted) setState(() => _isRouteTransitionComplete = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant GenerateReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_schedulePreviewRefresh);
      _previewRefreshTimer?.cancel();
      _previewRefreshVersion++;
      _displayedPreviewKey = _previewKey;
      _c.addListener(_schedulePreviewRefresh);
    }
  }

  void _schedulePreviewRefresh() {
    final requestedKey = _previewKey;
    final version = ++_previewRefreshVersion;

    _previewRefreshTimer?.cancel();

    if (requestedKey == _displayedPreviewKey) return;

    _previewRefreshTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || version != _previewRefreshVersion) return;

      if (requestedKey != _previewKey) {
        _schedulePreviewRefresh();
        return;
      }

      setState(() {
        _displayedPreviewKey = requestedKey;
      });
    });
  }

  @override
  void dispose() {
    _previewRefreshTimer?.cancel();
    _c.removeListener(_schedulePreviewRefresh);
    super.dispose();
  }

  static const Map<CalendarMode, String> _modeLabels = {
    CalendarMode.daily: 'Daily',
    CalendarMode.weekly: 'Weekly',
    CalendarMode.monthly: 'Monthly',
  };

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

  /// Sections grouped for the checklist. Order here is the order on screen.
  List<_SectionGroup> get _sectionGroups => [
        _SectionGroup('Logs', [
          _SectionItem(
            'Sensor history logs',
            _c.includeSensorLogs,
            (v) => _c.toggleSensorLogs(v),
          ),
          _SectionItem(
            'Calibration history logs',
            _c.includeCalibrationLogs,
            (v) => _c.toggleCalibrationLogs(v),
          ),
          _SectionItem(
            'Intervention history logs',
            _c.includeInterventionLogs,
            (v) => _c.toggleInterventionLogs(v),
          ),
        ]),
        _SectionGroup('Optimization results', [
          _SectionItem(
            'pH optimization results',
            _c.includePhOptimization,
            (v) => _c.togglePhOptimization(v),
          ),
          _SectionItem(
            'EC optimization results',
            _c.includeEcOptimization,
            (v) => _c.toggleEcOptimization(v),
          ),
        ]),
        _SectionGroup('Analysis', [
          _SectionItem(
            'All analytics and graphs',
            _c.includeAllAnalytics,
            (v) => _c.toggleAllAnalytics(v),
          ),
          _SectionItem(
            'Insights and Decision Support',
            _c.includeInsightsAndDecisionSupport,
            (v) => _c.toggleInsightsAndDecisionSupport(v),
          ),
        ]),
      ];

  int get _totalCount =>
      _sectionGroups.fold(0, (sum, g) => sum + g.items.length);

  int get _selectedCount => _sectionGroups.fold(
        0,
        (sum, g) => sum + g.items.where((i) => i.value).length,
      );

  String get _previewKey => [
        selectedMode,
        _c.includeInterventionLogs,
        _c.includeSensorLogs,
        _c.includeCalibrationLogs,
        _c.includePhOptimization,
        _c.includeEcOptimization,
        _c.includeAllAnalytics,
        _c.includeInsightsAndDecisionSupport,
        isLandscape,
        selectedDate.toIso8601String(),
      ].join('-');

  Future<Uint8List> buildPreview(PdfPageFormat format) {
    return _c.buildPdfBytes(
      dateRange: _selectedReportRange,
      aggregation: _reportAggregation,
      pageFormat: _selectedPdfFormat,
    );
  }

  void _toggleSelectAll() {
    _c.setAllReportSections(!isAllSelected);
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
          });
          _schedulePreviewRefresh();
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

  /// Compact label for the date pill so it fits beside the timeframe toggle.
  /// The full range still appears in the footer summary.
  String _formatChipLabel() {
    const short = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final range = _selectedReportRange;
    final first = range.start;
    final last = range.end.subtract(const Duration(days: 1));

    switch (selectedMode) {
      case CalendarMode.daily:
        return '${short[first.month - 1]} ${first.day}, ${first.year}';
      case CalendarMode.weekly:
        final end = first.month == last.month
            ? '${last.day}'
            : '${short[last.month - 1]} ${last.day}';
        return '${short[first.month - 1]} ${first.day}–$end, ${last.year}';
      case CalendarMode.monthly:
        return '${short[first.month - 1]} ${first.year}';
    }
  }

  Future<void> onGeneratePdf() async {
    setState(() => isGenerating = true);
    try {
      await _c.generatePdfReport(
        dateRange: _selectedReportRange,
        aggregation: _reportAggregation,
        pageFormat: _selectedPdfFormat,
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
            return AppFooterScrollView(
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

  Widget _buildActionLayout(
      {required bool isMobile, required List<Widget> children}) {
    if (!isMobile) return Row(children: children);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        (children.first as Expanded).child,
        const SizedBox(height: 8),
        (children.last as Expanded).child,
      ],
    );
  }

  Widget _buildPreviewHeader({required List<Widget> children}) {
    if (Responsive.isMobile(context)) {
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children);
  }

  Widget _buildPdfPreviewArea() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
      decoration: AppDecorations.card(),
      child: Column(
        children: [
          _buildPreviewHeader(
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
            child: !_isRouteTransitionComplete
                ? _buildPreviewPlaceholder()
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: PdfPreview(
                      key: ValueKey(_displayedPreviewKey),
                      build: buildPreview,
                      useActions: false,
                      allowPrinting: false,
                      allowSharing: false,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      maxPageWidth: 560,
                      dpi: 50,
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
                      loadingWidget: _buildPreviewSpinner('Generating preview...'),
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

  Widget _buildPreviewSpinner([String message = 'Loading preview...']) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.accentGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.cardMeta.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.calloutBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: _buildPreviewSpinner('Preparing preview...'),
    );
  }

  // ---------------------------------------------------------------------------
  // Report Configuration card
  // ---------------------------------------------------------------------------

  Widget _buildConfigSidebar(bool isMobile) {
    final selectedCount = _selectedCount;
    final noneSelected = selectedCount == 0;

    // On desktop the card has a fixed height, so the checklist scrolls inside
    // it. On mobile the whole page already scrolls, so the list just grows.
    final Widget sections = isMobile
        ? Column(children: _buildSectionGroups())
        : Expanded(child: _buildScrollableSections());

    return Container(
      // Slightly tighter on phones so both timeframe pills fit in one row.
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
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
          SizedBox(height: isMobile ? 12 : 18),

          // Timeframe: pill segmented control + date pill.
          Text(
            'Date timeframe',
            style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          if (isMobile)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildDateChip(isMobile: true),
                _buildSegmentedModeFilter(isMobile: true),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Date pill shrinks (with ellipsis) before the toggle does.
                Flexible(child: _buildDateChip(isMobile: isMobile)),
                const SizedBox(width: 8),
                _buildSegmentedModeFilter(isMobile: isMobile),
              ],
            ),
          SizedBox(height: isMobile ? 12 : 18),
          Text(
            'Print Orientation',
            style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          _buildPrintOrientationSelector(isMobile: isMobile),
          SizedBox(height: isMobile ? 12 : 18),
          Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 14),

          // Sections header: title + live count on the left, select-all right.
          _buildSectionsHeader(
            isMobile: isMobile,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Sections',
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$selectedCount of $_totalCount selected',
                      style: AppTextStyles.cardMeta.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _toggleSelectAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentGreen,
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isAllSelected ? 'Deselect all' : 'Select all',
                  style: AppTextStyles.cardMeta.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          sections,

          // Footer: its own zone, separated by a divider.
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noneSelected
                      ? 'Select at least one section to export'
                      : '$selectedCount ${selectedCount == 1 ? 'section' : 'sections'}'
                          ' · ${_modeLabels[selectedMode]}'
                          ' · ${_formatSelectedPeriodLabel()}',
                  style: AppTextStyles.cardMeta.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),
                _buildActionLayout(
                  isMobile: isMobile,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 48,
                          maxHeight: isMobile ? double.infinity : 48,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: (isGenerating || noneSelected)
                              ? null
                              : onGeneratePdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryButton,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isGenerating
                                ? AppColors.primaryButton
                                : Colors.grey.shade300,
                            disabledForegroundColor: isGenerating
                                ? Colors.white
                                : Colors.grey.shade600,
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
                            style: AppTextStyles.button.copyWith(
                              color: isGenerating || !noneSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 48,
                          maxHeight: isMobile ? double.infinity : 48,
                        ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsHeader(
      {required bool isMobile, required List<Widget> children}) {
    if (!isMobile) {
      return Row(
          crossAxisAlignment: CrossAxisAlignment.center, children: children);
    }
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [(children.first as Expanded).child, children.last],
    );
  }

  /// Daily / Weekly / Monthly as a compact pill: grey track, green active
  /// segment, three equal thirds. Same look as the History Logs control.
  Widget _buildSegmentedModeFilter({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 3 : 4),
      decoration: BoxDecoration(
        color: isMobile ? const Color(0xFFE2E2E2) : AppColors.calloutBackground,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 999),
        border: isMobile ? null : Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in _modeLabels.entries)
            _buildModeSegment(entry.key, entry.value, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildModeSegment(CalendarMode mode, String label,
      {bool isMobile = false}) {
    final isSelected = selectedMode == mode;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selectedMode == mode) return;

          setState(() => selectedMode = mode);
          _schedulePreviewRefresh();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: isMobile ? null : 36,
          constraints: isMobile ? const BoxConstraints(minHeight: 40) : null,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryButton : Colors.transparent,
            borderRadius: BorderRadius.circular(isMobile ? 10 : 999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 12 : 12.5,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isMobile ? Colors.black87 : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrintOrientationSelector({required bool isMobile}) {
    return SizedBox(
      width: isMobile ? double.infinity : 240,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 3 : 4),
        decoration: BoxDecoration(
          color:
              isMobile ? const Color(0xFFE2E2E2) : AppColors.calloutBackground,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 999),
          border: isMobile ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildOrientationSegment(
                label: 'Portrait',
                selected: !isLandscape,
                isMobile: isMobile,
              ),
            ),
            Expanded(
              child: _buildOrientationSegment(
                label: 'Landscape',
                selected: isLandscape,
                isMobile: isMobile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrientationSegment({
    required String label,
    required bool selected,
    required bool isMobile,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final nextIsLandscape = label == 'Landscape';
          if (isLandscape == nextIsLandscape) return;

          setState(() => isLandscape = nextIsLandscape);
          _schedulePreviewRefresh();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: isMobile ? 40 : 36,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryButton : Colors.transparent,
            borderRadius: BorderRadius.circular(isMobile ? 10 : 999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 12 : 12.5,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (isMobile ? Colors.black87 : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  /// The date pill. Label follows the selected timeframe
  /// (single day, 7-day span or whole month).
  Widget _buildDateChip({bool isMobile = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: InkWell(
        onTap: _openCalendarPopup,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 999),
        child: Container(
          constraints: BoxConstraints(minHeight: isMobile ? 40 : 46),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.calloutBackground,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 999),
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
              Flexible(
                child: Text(
                  isMobile ? _formatSelectedPeriodLabel() : _formatChipLabel(),
                  maxLines: isMobile ? null : 1,
                  overflow:
                      isMobile ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: AppTextStyles.cardMeta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Scrolling checklist with a soft fade at the bottom edge while there is
  /// more to scroll to, so the list never looks like it simply ends mid-row.
  Widget _buildScrollableSections() {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        _updateBottomFade(n.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _updateBottomFade(n.metrics);
          return false;
        },
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.black,
              _showBottomFade ? Colors.transparent : Colors.black,
            ],
            stops: const [0.0, 0.88, 1.0],
          ).createShader(rect),
          child: SingleChildScrollView(
            child: Column(children: _buildSectionGroups()),
          ),
        ),
      ),
    );
  }

  void _updateBottomFade(ScrollMetrics metrics) {
    final show = metrics.extentAfter > 1;
    if (show == _showBottomFade) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showBottomFade != show) {
        setState(() => _showBottomFade = show);
      }
    });
  }

  List<Widget> _buildSectionGroups() {
    final isMobile = Responsive.isMobile(context);
    final widgets = <Widget>[];
    for (final group in _sectionGroups) {
      final onCount = group.items.where((i) => i.value).length;
      widgets.add(
        Padding(
          padding: EdgeInsets.fromLTRB(
              12, widgets.isEmpty ? 4 : (isMobile ? 8 : 14), 12, 4),
          child: _buildCategoryHeader(
            isMobile: isMobile,
            children: [
              Text(
                group.title.toUpperCase(),
                style: AppTextStyles.cardMeta.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '$onCount of ${group.items.length}',
                style: AppTextStyles.cardMeta.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
      widgets.addAll(group.items.map(_sectionTile));
    }
    return widgets;
  }

  Widget _buildCategoryHeader(
      {required bool isMobile, required List<Widget> children}) {
    if (!isMobile) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children);
    }
    return Row(
      children: [
        Expanded(child: children.first),
        const SizedBox(width: 8),
        children.last,
      ],
    );
  }

  /// One checklist row. The whole row toggles, and selected rows get a pale
  /// green background so state reads at a glance.
  Widget _sectionTile(_SectionItem item) {
    final selected = item.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AppColors.statusCardGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => item.onChanged(!selected),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (v) => item.onChanged(v ?? false),
                    activeColor: AppColors.primaryButton,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionItem {
  const _SectionItem(this.title, this.value, this.onChanged);
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
}

class _SectionGroup {
  const _SectionGroup(this.title, this.items);
  final String title;
  final List<_SectionItem> items;
}
