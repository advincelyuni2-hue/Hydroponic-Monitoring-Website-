import '../widgets/app_footer.dart';
import 'package:flutter/material.dart';
import '../controllers/history_logs_controller.dart';
import '../services/notification_service.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/custom_calendar_popup.dart';
import '../widgets/history_log_cards.dart';
import '../widgets/history_log_table.dart';
import 'add_log_screen.dart';
import 'calibration_screen.dart';
import '../widgets/history_log_value.dart';

class HistoryLogsScreen extends StatefulWidget {
  const HistoryLogsScreen({super.key});

  @override
  State<HistoryLogsScreen> createState() => HistoryLogsScreenState();
}

class HistoryLogsScreenState extends State<HistoryLogsScreen> {
  final HistoryLogsController _controller = HistoryLogsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openCalendarPopup(String range) {
    _controller.selectRange(range);
    CalendarMode mode = CalendarMode.daily;
    if (range == 'Weekly') mode = CalendarMode.weekly;
    if (range == 'Monthly') mode = CalendarMode.monthly;

    showDialog(
      context: context,
      builder: (context) => CustomCalendarPopup(
        mode: mode,
        initialDate: _controller.selectedDate,
        onDateSelected: (selectedDate, weekRange) {
          _controller.updateDate(selectedDate, weekRange);
        },
      ),
    );
  }

  Future<void> _showManualInterventionDialog() async {
    final service = NotificationService();
    var saved = false;
    await showRecordFixDialog(
      context,
      barrierDismissible: false,
      submissionError: () => service.lastInterventionError,
      onSubmit: (entry) async {
        saved = await service.recordManualIntervention(
          parameter: entry.parameter,
          currentValue: entry.currentValue,
          actionType: entry.actionType,
          amount: entry.amount,
          notes: entry.notes,
          reservoirVolumeL: entry.reservoirVolumeL,
          performedAtManila: entry.performedAtManila!,
        );
        return saved;
      },
    );

    if (!mounted || !saved) return;
    await _controller.loadSelectedLogs();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Intervention recorded successfully.')),
    );
  }

  Future<void> _openCalibration() async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CalibrationScreen()),
    );
    if (completed == true && mounted) {
      await _controller.loadSelectedLogs();
    }
  }

  Future<void> _confirmDeleteSingle(int index) async {
    final entry = _controller.rows[index];
    final dateStr = entry.values.isNotEmpty ? entry.values[0] : '';
    final timeStr = entry.values.length > 1 ? entry.values[1] : '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.background,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: AppDecorations.card(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete Log Record?',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete the log record for $dateStr at $timeStr? This action cannot be undone.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryButton),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primaryButton,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alertText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.deleteSingleRow(index);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log entry deleted.')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete the log entry: $error')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final count = _controller.selectedRowIndices.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.background,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: AppDecorations.card(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete $count Log Record${count > 1 ? 's' : ''}?',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete the selected $count log records? This action cannot be undone.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryButton),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primaryButton,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alertText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Delete All',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.deleteSelectedRows();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count log records deleted.')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not delete every selected log. Refresh the table and check which rows remain. Details: $error',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditModal(int index) async {
    final entry = _controller.rows[index];
    final dateStr = entry.values.isNotEmpty ? entry.values[0] : '';
    final timeStr = entry.values.length > 1 ? entry.values[1] : '';

    double initialPh = 6.5;
    double initialEc = 1.5;
    double initialTemp = 24.0;

    if (entry.values.length >= 5) {
      initialPh = double.tryParse(entry.values[2]) ?? 6.5;
      initialEc = double.tryParse(entry.values[3].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.5;
      initialTemp = double.tryParse(entry.values[4].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 24.0;
    }

    final phController = TextEditingController(text: initialPh.toStringAsFixed(6));
    final ecController = TextEditingController(text: initialEc.toStringAsFixed(6));
    final tempController = TextEditingController(text: initialTemp.toStringAsFixed(1));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.background,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: AppDecorations.card(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Log Record',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                '$dateStr • $timeStr',
                style: AppTextStyles.cardMeta.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text('Average pH', style: AppTextStyles.label),
              const SizedBox(height: 6),
              TextField(
                controller: phController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.calloutBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Average EC (mS/cm)', style: AppTextStyles.label),
              const SizedBox(height: 6),
              TextField(
                controller: ecController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.calloutBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Average Temp (°C)', style: AppTextStyles.label),
              const SizedBox(height: 6),
              TextField(
                controller: tempController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.calloutBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryButton),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primaryButton,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Save changes to log',
                      style: AppTextStyles.button.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final newPh = double.tryParse(phController.text) ?? initialPh;
      final newEc = double.tryParse(ecController.text) ?? initialEc;
      final newTemp = double.tryParse(tempController.text) ?? initialTemp;

      try {
        await _controller.updateRowValues(index, newPh, newEc, newTemp);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log record updated successfully.')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save the log record: $error')),
          );
        }
      }
    }
  }

  String? get _actionLabel => switch (_controller.selectedTab) {
        'Calibration logs' => 'Start Calibration',
        'Intervention logs' => 'Log Intervention',
        _ => null,
      };

  VoidCallback? get _actionCallback => switch (_controller.selectedTab) {
        'Calibration logs' => _openCalibration,
        'Intervention logs' => _showManualInterventionDialog,
        _ => null,
      };

  Widget? _buildHeaderAction() {
    final label = _actionLabel;
    if (label == null) return null;
    final style = OutlinedButton.styleFrom(
      foregroundColor: AppColors.iconCircle,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.iconCircle, width: 1.5),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: AppTextStyles.bodyBold.copyWith(fontSize: 13),
    );
    return OutlinedButton(
      onPressed: _actionCallback,
      style: style,
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrowHeader = !Responsive.isDesktop(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(selectedIndex: 2),
      floatingActionButton: narrowHeader
          ? ListenableBuilder(
              listenable: _controller,
              builder: (context, _) =>
                  _controller.isLoading ||
                          _controller.errorMessage != null ||
                          _actionLabel == null
                      ? const SizedBox.shrink()
                      : FloatingActionButton.extended(
                          onPressed: _actionCallback,
                          backgroundColor: AppColors.primaryButton,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          icon: Icon(
                            _controller.selectedTab == 'Calibration logs'
                                ? Icons.tune
                                : Icons.edit_note,
                            size: 20,
                          ),
                          label: Text(_actionLabel!,
                              style: AppTextStyles.bodyBold.copyWith(
                                  fontSize: 13, color: Colors.white)),
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

            final isMobile = Responsive.isMobile(context);
            final isAdmin = appProfile.value?.isAdmin == true &&
                _controller.selectedTab != 'Intervention logs';

            return AppFooterScrollView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                narrowHeader && _actionLabel != null ? 96 : (isMobile ? 16 : 24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(
                    title: 'History logs',
                    profile: _controller.profile,
                    onHistoryDateSelected: _controller.selectDateFromSearch,
                    compactLayout: narrowHeader,
                    titleAction: narrowHeader ? null : _buildHeaderAction(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: AppDecorations.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTabsAndControls(isMobile, isAdmin),
                        const SizedBox(height: 16),
                        isMobile
                            ? HistoryLogCards(
                                columns: _controller.columns,
                                rows: _controller.rows,
                                selectedTab: _controller.selectedTab,
                              )
                            : HistoryLogTable(
                                columns: _controller.columns,
                                rows: _controller.rows,
                                selectedTab: _controller.selectedTab,
                                isAdmin: isAdmin,
                                isSelectionMode: _controller.isSelectionMode,
                                selectedIndices: _controller.selectedRowIndices,
                                onSelectAll: _controller.toggleSelectAll,
                                onToggleRow: _controller.toggleRowSelection,
                                onDeleteRow: _confirmDeleteSingle,
                                onEditRow: _showEditModal,
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

  // ---------------------------------------------------------------------------
  // TABS + CONTROLS (mobile layout changed: stacked rows instead of one Wrap)
  // ---------------------------------------------------------------------------

  Widget _buildTabsAndControls(bool isMobile, bool isAdmin) {
    final tabs = _buildTabs(isMobile);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tabs scroll sideways instead of wrapping on narrow phones.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: tabs,
          ),
          const SizedBox(height: 14),
          _buildMobileControls(isAdmin),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.cardBorder),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            tabs,
            _buildRightControlsGroup(isAdmin),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: AppColors.cardBorder),
      ],
    );
  }

  /// Mobile: three stacked rows instead of one cramped Wrap.
  ///   1. date picker (full width)
  ///   2. Daily / Weekly / Monthly (full width, equal thirds)
  ///   3. admin selection controls (or log count) on the left,
  ///      "See legend" on the right
  Widget _buildMobileControls(bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDateChip(fullWidth: true),
        const SizedBox(height: 10),
        _buildSegmentedRangeFilters(isMobile: true),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: isAdmin
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: _buildSelectionControls(),
                    )
                  : Text(
                      '${_controller.rows.length} logs',
                      style: AppTextStyles.cardMeta.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
            ),
            _buildLegendButton(),
          ],
        ),
      ],
    );
  }

  /// Desktop / tablet: the original single-row group.
  Widget _buildRightControlsGroup(bool isAdmin) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isAdmin) ...[
          ..._buildSelectionControls(),
          Container(height: 18, width: 1, color: AppColors.cardBorder),
        ],
        _buildDateChip(),
        Container(height: 18, width: 1, color: AppColors.cardBorder),
        _buildSegmentedRangeFilters(),
        _buildLegendButton(),
      ],
    );
  }

  /// Admin only: "Select" button, or "Delete (n)" + "Cancel" in selection mode.
  List<Widget> _buildSelectionControls() {
    final bool isSelectionMode = _controller.isSelectionMode;
    final int selectedCount = _controller.selectedRowIndices.length;

    if (isSelectionMode) {
      return [
        ElevatedButton.icon(
          onPressed: selectedCount > 0 ? _confirmDeleteSelected : null,
          icon: const Icon(Icons.delete_outline_rounded, size: 15),
          label: Text('Delete ($selectedCount)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.alertText,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        OutlinedButton(
          onPressed: _controller.toggleSelectionMode,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.cardBorder),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Cancel',
            style: AppTextStyles.cardMeta.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ];
    }

    return [
      InkWell(
        onTap: _controller.toggleSelectionMode,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E2E2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Select',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    ];
  }

  /// Date button. [fullWidth] = true stretches it across the card (mobile)
  /// and adds a dropdown chevron so it reads as tappable.
  Widget _buildDateChip({bool fullWidth = false}) {
    final label = Text(
      _controller.activeRangeLabel,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.cardMeta.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: fullWidth ? 13 : 12,
      ),
    );

    return InkWell(
      onTap: () => _openCalendarPopup(_controller.selectedRange),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(minHeight: fullWidth ? 44 : 0),
        padding: EdgeInsets.symmetric(
          horizontal: fullWidth ? 14 : 12,
          vertical: fullWidth ? 10 : 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.calloutBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: AppColors.primaryButton,
            ),
            const SizedBox(width: 8),
            if (fullWidth) Expanded(child: label) else Flexible(child: label),
            if (fullWidth)
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendButton() {
    return InkWell(
      onTap: () => HistoryLogLegend.show(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: AppColors.primaryButton,
            ),
            const SizedBox(width: 4),
            Text(
              'See legend',
              style: AppTextStyles.cardMeta.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryButton,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Daily / Weekly / Monthly. On mobile it fills the full width with three
  /// equal segments and larger text; on desktop it stays compact.
  Widget _buildSegmentedRangeFilters({bool isMobile = false}) {
    final options = ['Daily', 'Weekly', 'Monthly'];

    final segments = options.map((range) {
      final isSelected = _controller.selectedRange == range;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openCalendarPopup(range),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 0 : 12,
            vertical: isMobile ? 10 : 5,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryButton : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            range,
            style: TextStyle(
              fontSize: isMobile ? 13 : 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        children: isMobile
            ? segments.map((s) => Expanded(child: s)).toList()
            : segments,
      ),
    );
  }

  Widget _buildTabs(bool isMobile) {
    final tabOptions = ['Sensor logs', 'Calibration logs', 'Intervention logs'];
    return Wrap(
      spacing: isMobile ? 12 : 24,
      children: tabOptions.map((title) => _tab(title, isMobile)).toList(),
    );
  }

  Widget _tab(String title, bool isMobile) {
    final isActive = _controller.selectedTab == title;
    return GestureDetector(
      onTap: () => _controller.selectTab(title),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: isMobile ? 15 : 18,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryButton : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}