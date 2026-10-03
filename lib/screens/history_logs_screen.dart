import 'package:flutter/material.dart';
import '../controllers/history_logs_controller.dart';
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
              Text('Delete Log Record?',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
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
                      side: const BorderSide(color: AppColors.primaryButton),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: Text('Cancel',
                        style: AppTextStyles.button.copyWith(
                            color: AppColors.primaryButton, fontSize: 13)),
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
                          horizontal: 24, vertical: 10),
                    ),
                    child: Text('Delete',
                        style: AppTextStyles.button
                            .copyWith(color: Colors.white, fontSize: 13)),
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
            SnackBar(content: Text('Could not delete log entry: $error')),
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
              Text('Delete $count Log Record${count > 1 ? 's' : ''}?',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
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
                      side: const BorderSide(color: AppColors.primaryButton),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: Text('Cancel',
                        style: AppTextStyles.button.copyWith(
                            color: AppColors.primaryButton, fontSize: 13)),
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
                          horizontal: 24, vertical: 10),
                    ),
                    child: Text('Delete All',
                        style: AppTextStyles.button
                            .copyWith(color: Colors.white, fontSize: 13)),
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
        await _controller.loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete selected logs: $error')),
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
      initialEc =
          double.tryParse(entry.values[3].replaceAll(RegExp(r'[^0-9.]'), '')) ??
              1.5;
      initialTemp =
          double.tryParse(entry.values[4].replaceAll(RegExp(r'[^0-9.]'), '')) ??
              24.0;
    }

    final phController =
        TextEditingController(text: initialPh.toStringAsFixed(2));
    final ecController =
        TextEditingController(text: initialEc.toStringAsFixed(2));
    final tempController =
        TextEditingController(text: initialTemp.toStringAsFixed(1));

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
              Text('Edit Log Record',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text('$dateStr • $timeStr',
                  style: AppTextStyles.cardMeta.copyWith(fontSize: 12)),
              const SizedBox(height: 16),
              Text('Average pH', style: AppTextStyles.label),
              const SizedBox(height: 6),
              TextField(
                controller: phController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                      side: const BorderSide(color: AppColors.primaryButton),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: Text('Cancel',
                        style: AppTextStyles.button.copyWith(
                            color: AppColors.primaryButton, fontSize: 13)),
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
                          horizontal: 24, vertical: 10),
                    ),
                    child: Text('Save changes to log',
                        style: AppTextStyles.button.copyWith(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final newPh = double.tryParse(phController.text);
      final newEc = double.tryParse(ecController.text);
      final newTemp = double.tryParse(tempController.text);
      if (newPh == null || newEc == null || newTemp == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter valid numbers for all values.')),
          );
        }
      } else {
        try {
          await _controller.updateRowValues(index, newPh, newEc, newTemp);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Log record updated successfully.')),
            );
          }
        } catch (error) {
          await _controller.loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not update log record: $error')),
            );
          }
        }
      }
    }
    phController.dispose();
    ecController.dispose();
    tempController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(selectedIndex: 2),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_controller.errorMessage!,
                        style: AppTextStyles.body),
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
            final isAdmin = appProfile.value?.isAdmin == true;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(
                    title: 'History logs',
                    profile: _controller.profile,
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
                              )
                            : HistoryLogTable(
                                columns: _controller.columns,
                                rows: _controller.rows,
                                selectedTab: _controller.selectedTab,
                                isAdmin: isAdmin,
                                isSelectionMode: _controller.isSelectionMode,
                                selectedIndices:
                                    _controller.selectedRowIndices,
                                onSelectAll: _controller.toggleSelectAll,
                                onToggleRow: _controller.toggleRowSelection,
                                onDeleteRow: _confirmDeleteSingle,
                                onEditRow: _controller.selectedTab ==
                                            'Sensor logs' &&
                                        _controller.selectedRange == 'Daily'
                                    ? _showEditModal
                                    : null,
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

  Widget _buildTabsAndControls(bool isMobile, bool isAdmin) {
    final tabs = _buildTabs(isMobile);
    final controlsGroup = _buildRightControlsGroup(isAdmin);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tabs,
          const SizedBox(height: 12),
          controlsGroup,
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
            controlsGroup,
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: AppColors.cardBorder),
      ],
    );
  }

  Widget _buildRightControlsGroup(bool isAdmin) {
    final bool isSelectionMode = _controller.isSelectionMode;
    final int selectedCount = _controller.selectedRowIndices.length;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Selection Action Bar Pills
        if (isAdmin) ...[
          if (isSelectionMode) ...[
            ElevatedButton.icon(
              onPressed: selectedCount > 0 ? _confirmDeleteSelected : null,
              icon: const Icon(Icons.delete_outline_rounded, size: 15),
              label: Text('Delete ($selectedCount)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertText,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _controller.toggleSelectionMode,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.cardBorder),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Cancel',
                  style: AppTextStyles.cardMeta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
            ),
          ] else ...[
            InkWell(
              onTap: _controller.toggleSelectionMode,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          ],
          Container(
            height: 18,
            width: 1,
            color: AppColors.cardBorder,
          ),
        ],

        // Interactive Date Pill Button
        InkWell(
          onTap: () => _openCalendarPopup(_controller.selectedRange),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.calloutBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.primaryButton),
                const SizedBox(width: 6),
                Text(
                  _controller.activeRangeLabel,
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

        // Vertical Separator
        Container(
          height: 18,
          width: 1,
          color: AppColors.cardBorder,
        ),

        // Segmented Horizon Filters
        _buildSegmentedRangeFilters(),

        // "See legend" Text Button with Icon
        InkWell(
          onTap: () => HistoryLogLegend.show(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
        ),
      ],
    );
  }

  Widget _buildSegmentedRangeFilters() {
    final options = ['Daily', 'Weekly', 'Monthly'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((range) {
          final isSelected = _controller.selectedRange == range;
          return GestureDetector(
            onTap: () => _openCalendarPopup(range),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryButton : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                range,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabs(bool isMobile) {
    final tabOptions = ['Sensor logs', 'Calibration logs', 'Reports logs'];
    return Wrap(
      spacing: isMobile ? 12 : 24,
      children:
          tabOptions.map((title) => _tab(title, isMobile)).toList(),
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
                color: isActive
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryButton
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}