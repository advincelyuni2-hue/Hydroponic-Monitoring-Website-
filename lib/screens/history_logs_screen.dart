import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../controllers/history_logs_controller.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/history_log_table.dart';
import '../widgets/history_log_cards.dart';
import '../widgets/custom_calendar_popup.dart';
import '../utils/responsive.dart';

class HistoryLogsScreen extends StatefulWidget {
  const HistoryLogsScreen({super.key});

  @override
  State<HistoryLogsScreen> createState() => _HistoryLogsScreenState();
}

class _HistoryLogsScreenState extends State<HistoryLogsScreen> {
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
                        _buildTabsAndFilters(isMobile),
                        const SizedBox(height: 16),
                        isMobile
                            ? HistoryLogCards(
                                columns: _controller.columns,
                                rows: _controller.rows,
                              )
                            : HistoryLogTable(
                                columns: _controller.columns,
                                rows: _controller.rows,
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

  Widget _buildTabsAndFilters(bool isMobile) {
    final tabs = _buildTabs(isMobile);
    final filters = _buildRangeFilters();
    final activeText = Text(
      _controller.activeRangeLabel,
      style: AppTextStyles.cardMeta.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );

    final deleteButton = _controller.canDelete
        ? IconButton(
            tooltip: 'Delete logs in selected range',
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          )
        : const SizedBox.shrink();

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [tabs, deleteButton]),
              activeText,
            ],
          ),
          const SizedBox(height: 12),
          filters,
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorder),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [tabs, deleteButton]),
            Row(
              children: [
                activeText,
                const SizedBox(width: 16),
                filters,
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.cardBorder),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete history logs?'),
        content: Text('Delete logs for ${_controller.activeRangeLabel}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final deleted = await _controller.deleteSelectedLogs();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'History logs deleted.'
              : 'History logs could not be deleted.',
        ),
      ),
    );
  }

  Widget _buildTabs(bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tab('Sensor logs', isMobile),
        SizedBox(width: isMobile ? 16 : 24),
        _tab('Calibration logs', isMobile),
      ],
    );
  }

  Widget _tab(String title, bool isMobile) {
    final isActive = _controller.selectedTab == title;

    return GestureDetector(
      onTap: () => _controller.selectTab(title),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: isMobile ? 16 : 20,
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
            width: isActive ? (isMobile ? 70 : 85) : 0,
            decoration: BoxDecoration(
              color: AppColors.primaryButton,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeFilters() {
    final options = ['Daily', 'Weekly', 'Monthly'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((range) {
        final isSelected = _controller.selectedRange == range;

        return GestureDetector(
          onTap: () => _openCalendarPopup(range),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryButton
                  : const Color(0xFFE2E2E2),
              borderRadius: BorderRadius.circular(12),
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
    );
  }
}