import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../services/app_state.dart';
import '../services/monitoring_service.dart';
import '../services/supabase_client.dart';
import '../services/user_service.dart';

class HistoryLogsController extends ChangeNotifier {
  final UserService _userService = UserService();
  final MonitoringService _monitoringService = MonitoringService();

  bool isLoading = true;
  String? errorMessage;
  UserProfile? profile;

  String selectedTab = 'Sensor logs'; // 'Sensor logs' | 'Calibration logs'
  String selectedRange = 'Daily'; // 'Daily' | 'Weekly' | 'Monthly'
  DateTime selectedDate = DateTime(2026, 7, 18);
  DateTimeRange? selectedWeekRange;

  List<String> columns = [];
  List<HistoryLogEntry> rows = [];

  HistoryLogsController() {
    initWeekRange();
    loadData();
  }

  void initWeekRange() {
    final start =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final end = start.add(const Duration(days: 6));
    selectedWeekRange = DateTimeRange(
      start: start,
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  String get activeRangeLabel {
    final months = [
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
    if (selectedRange == 'Daily') {
      return '${months[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}';
    } else if (selectedRange == 'Weekly') {
      final start = selectedWeekRange?.start ?? selectedDate;
      final end = selectedWeekRange?.end ?? selectedDate;
      final startMonth = months[start.month - 1].substring(0, 3);
      final endMonth = months[end.month - 1].substring(0, 3);
      return '$startMonth ${start.day} - $endMonth ${end.day}, ${end.year}';
    } else {
      return '${months[selectedDate.month - 1]}, ${selectedDate.year}';
    }
  }

  DateTimeRange _selectedDateRange() {
    if (selectedRange == 'Daily') {
      final start =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final end = DateTime(selectedDate.year, selectedDate.month,
          selectedDate.day, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    } else if (selectedRange == 'Weekly') {
      return selectedWeekRange ??
          DateTimeRange(start: selectedDate, end: selectedDate);
    } else {
      final start = DateTime(selectedDate.year, selectedDate.month, 1);
      final end = DateTime(
          selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    }
  }

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _userService.getProfile(
        supabaseClient?.auth.currentUser?.id ??
            appProfile.value?.id ??
            'mock-user-id',
      );
      await _loadSelectedLogs();
    } catch (e) {
      errorMessage = 'Failed to load history logs';
    }
    isLoading = false;
    notifyListeners();
  }

  void selectTab(String tab) {
    if (selectedTab == tab) return;
    selectedTab = tab;
    _loadSelectedLogs();
  }

  void selectRange(String range) {
    selectedRange = range;
    _loadSelectedLogs();
  }

  void updateDate(DateTime date, DateTimeRange? weekRange) {
    selectedDate = date;
    if (weekRange != null) {
      selectedWeekRange = weekRange;
    } else {
      initWeekRange();
    }
    _loadSelectedLogs();
  }

  Future<void> _loadSelectedLogs() async {
    isLoading = true;
    notifyListeners();
    try {
      final range = _selectedDateRange();
      if (selectedTab == 'Calibration logs') {
        columns = MonitoringService.calibrationLogColumns;
        rows = await _monitoringService.getCalibrationHistory(
          start: range.start,
          end: range.end,
        );
      } else {
        columns = const ['Time', 'Avg pH', 'Avg EC', 'Avg Temp', 'Status'];
        rows = await _monitoringService.getSensorHistory(
          start: range.start,
          end: range.end,
          aggregation: switch (selectedRange) {
            'Weekly' => HistoryAggregation.eightHours,
            'Monthly' => HistoryAggregation.daily,
            _ => HistoryAggregation.tenMinutes,
          },
        );
      }
    } catch (_) {
      errorMessage = 'Failed to load sensor history from Supabase';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get canDelete => profile?.isAdmin == true;

  Future<bool> deleteSelectedLogs() async {
    if (!canDelete) return false;
    try {
      final range = _selectedDateRange();
      if (selectedTab == 'Calibration logs') {
        await _monitoringService.deleteCalibrationLogs(
          start: range.start,
          end: range.end,
        );
      } else {
        await _monitoringService.deleteHistoryLogs(
          start: range.start,
          end: range.end,
        );
      }
      await _loadSelectedLogs();
      return true;
    } catch (_) {
      errorMessage = 'Unable to delete history logs. Please try again.';
      notifyListeners();
      return false;
    }
  }
}