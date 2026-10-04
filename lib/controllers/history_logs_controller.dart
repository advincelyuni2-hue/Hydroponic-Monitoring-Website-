import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../services/monitoring_service.dart';
import '../services/user_service.dart';
import '../services/app_state.dart';
import '../services/supabase_client.dart';
import '../utils/manila_time.dart';

class HistoryLogsController extends ChangeNotifier {
  final UserService userService = UserService();
  final MonitoringService monitoringService = MonitoringService();

  bool isLoading = true;
  String? errorMessage;
  UserProfile? profile;

  String selectedTab = 'Sensor logs'; // 'Sensor logs' | 'Calibration logs' | 'Reports logs'
  String selectedRange = 'Daily'; // 'Daily' | 'Weekly' | 'Monthly'
  DateTime selectedDate = manilaNow();
  DateTimeRange? selectedWeekRange;

  List<String> columns = [];
  List<HistoryLogEntry> rows = [];

  // Admin selection state
  bool isSelectionMode = false;
  final Set<int> selectedRowIndices = {};

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

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await userService.getProfile(
        supabaseClient?.auth.currentUser?.id ??
            appProfile.value?.id ??
            'mock-user-id',
      );
      await loadSelectedLogs();
    } catch (e) {
      errorMessage = 'Failed to load history logs';
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleSelectionMode() {
    isSelectionMode = !isSelectionMode;
    selectedRowIndices.clear();
    notifyListeners();
  }

  void toggleSelectAll(bool? select) {
    if (select == true) {
      selectedRowIndices.addAll(List.generate(rows.length, (i) => i));
    } else {
      selectedRowIndices.clear();
    }
    notifyListeners();
  }

  void toggleRowSelection(int index) {
    if (selectedRowIndices.contains(index)) {
      selectedRowIndices.remove(index);
    } else {
      selectedRowIndices.add(index);
    }
    notifyListeners();
  }

  void selectTab(String tab) {
    if (selectedTab == tab) return;
    selectedTab = tab;
    isSelectionMode = false;
    selectedRowIndices.clear();
    loadSelectedLogs();
  }

  void selectRange(String range) {
    selectedRange = range;
    loadSelectedLogs();
  }

  void updateDate(DateTime date, DateTimeRange? weekRange) {
    selectedDate = date;
    if (weekRange != null) {
      selectedWeekRange = weekRange;
    } else {
      initWeekRange();
    }
    loadSelectedLogs();
  }

  Future<void> loadSelectedLogs() async {
    selectedRowIndices.clear();
<<<<<<< HEAD
=======
    if (selectedTab == 'Calibration logs') {
      columns = const ['Time', 'Sensor', 'Action', 'Status'];
      rows = const [];
      isLoading = false;
      notifyListeners();
      return;
    }

    if (selectedTab == 'Reports logs') {
      columns = const [
        'Date',
        'Time',
        'Average pH',
        'Average EC',
        'Average Temp',
        'Critical Alerts'
      ];
      rows = const [];
      isLoading = false;
      notifyListeners();
      return;
    }

>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final range = _selectedDateRange();
<<<<<<< HEAD
      if (selectedTab == 'Calibration logs') {
        columns = MonitoringService.calibrationLogColumns;
        rows = await monitoringService.getCalibrationHistory(
          start: range.start,
          end: range.end,
        );
      } else if (selectedTab == 'Reports logs') {
        columns = const [
          'Date',
          'Time',
          'Average pH',
          'Average EC',
          'Average Temp',
          'Critical Alerts'
        ];
        rows = const [];
      } else {
        columns = const [
          'Date',
          'Time',
          'Average pH',
          'Average EC',
          'Average Temp',
          'Status'
        ];
        rows = await monitoringService.getSensorHistory(
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
      errorMessage = 'Failed to load $selectedTab from Supabase';
=======
      columns = const [
        'Date',
        'Time',
        'Average pH',
        'Average EC',
        'Average Temp',
        'Status'
      ];

      rows = await monitoringService.getSensorHistory(
        start: range.start,
        end: range.end,
        aggregation: switch (selectedRange) {
          'Weekly' => HistoryAggregation.eightHours,
          'Monthly' => HistoryAggregation.daily,
          _ => HistoryAggregation.tenMinutes,
        },
      );
    } catch (_) {
      errorMessage = 'Failed to load sensor history from Supabase';
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSingleRow(int index) async {
<<<<<<< HEAD
    if (index < 0 || index >= rows.length) return;
    await _deleteEntry(rows[index]);
    rows.removeAt(index);
    selectedRowIndices.remove(index);
    notifyListeners();
=======
    if (index >= 0 && index < rows.length) {
      rows.removeAt(index);
      selectedRowIndices.remove(index);
      notifyListeners();
    }
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  }

  Future<void> deleteSelectedRows() async {
    final sortedIndices = selectedRowIndices.toList()
      ..sort((a, b) => b.compareTo(a));
    for (final idx in sortedIndices) {
<<<<<<< HEAD
      if (idx >= 0 && idx < rows.length) await _deleteEntry(rows[idx]);
    }
    for (final idx in sortedIndices) {
      if (idx >= 0 && idx < rows.length) rows.removeAt(idx);
=======
      if (idx >= 0 && idx < rows.length) {
        rows.removeAt(idx);
      }
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    }
    selectedRowIndices.clear();
    isSelectionMode = false;
    notifyListeners();
  }

  Future<void> updateRowValues(
      int index, double newPh, double newEc, double newTemp) async {
<<<<<<< HEAD
    if (index < 0 || index >= rows.length) return;
    final entry = rows[index];
    final start = entry.recordStart;
    final duration = entry.recordDuration;
    if (selectedTab != 'Sensor logs' ||
        start == null ||
        duration == null ||
        duration != const Duration(minutes: 1)) {
      throw StateError('Only individual daily sensor readings can be edited.');
    }
    await monitoringService.updateSensorHistoryBucket(
      start: start,
      end: start.add(duration),
      ph: newPh,
      ec: newEc,
      temperature: newTemp,
    );
    await loadSelectedLogs();
  }

  Future<void> _deleteEntry(HistoryLogEntry entry) async {
    final start = entry.recordStart;
    if (start == null) {
      throw StateError('This history entry cannot be identified for deletion.');
    }
    if (selectedTab == 'Calibration logs') {
      await monitoringService.deleteCalibrationLog(start);
      return;
    }
    if (selectedTab != 'Sensor logs') {
      throw StateError('Report log deletion is not available.');
    }
    final duration = entry.recordDuration;
    if (duration == null) {
      throw StateError('This sensor history entry has no time range.');
    }
    await monitoringService.deleteHistoryLogs(
      start: start,
      end: start.add(duration),
    );
=======
    if (index >= 0 && index < rows.length) {
      final oldEntry = rows[index];
      final newValues = List<String>.from(oldEntry.values);

      if (newValues.length >= 6) {
        newValues[2] = newPh.toStringAsFixed(2);
        newValues[3] = '${newEc.toStringAsFixed(2)} mS/cm';
        newValues[4] = '${newTemp.toStringAsFixed(1)} °C';
      }

      rows[index] = HistoryLogEntry(
        newValues,
        ranges: oldEntry.ranges,
      );
      notifyListeners();
    }
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  }

  DateTimeRange _selectedDateRange() {
    if (selectedRange == 'Weekly') {
      final start = selectedWeekRange?.start ?? selectedDate;
      return DateTimeRange(
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(start.year, start.month, start.day)
            .add(const Duration(days: 7)),
      );
    }
    if (selectedRange == 'Monthly') {
      final start = DateTime(selectedDate.year, selectedDate.month);
      return DateTimeRange(
        start: start,
        end: DateTime(selectedDate.year, selectedDate.month + 1),
      );
    }
    final start =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return DateTimeRange(
      start: start,
      end: start.add(const Duration(days: 1)),
    );
  }
}