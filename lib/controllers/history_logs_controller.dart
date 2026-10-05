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
    if (selectedTab == 'Calibration logs') {
        isLoading = true;
        errorMessage = null;
        columns = MonitoringService.calibrationLogColumns;
        notifyListeners();

        try {
          final range = _selectedDateRange();
          rows = await monitoringService.getCalibrationHistory(
            start: range.start,
            end: range.end,
          );
        } catch(_) {
          errorMessage = 'Failed to load calibration logs from Supabase';
        } finally {
          isLoading = false;
          notifyListeners();
        }
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

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final range = _selectedDateRange();
      final aggregation = switch (selectedRange) {
        'Weekly' => HistoryAggregation.eightHours,
        'Monthly' => HistoryAggregation.daily,
        _ => HistoryAggregation.tenMinutes,
      };

      final sensorRows = await monitoringService.getSensorHistory(
        start: range.start,
        end: range.end,
        aggregation: aggregation,
      );

      if (selectedRange == 'Monthly') {
        columns = const [
          'Date',
          'Average pH',
          'Average EC',
          'Average Temp',
          'Status',
        ];

        rows = sensorRows.map((entry) {
          return HistoryLogEntry(
            [
              entry.values[0],
              ...entry.values.skip(2),
            ],
            ranges: {
              for (final range in entry.ranges.entries)
                range.key - 1: range.value,
            },
            recordStart: entry.recordStart,
            recordDuration: entry.recordDuration,
          );
        }).toList();
      } else {
        columns = const [
          'Date',
          'Time',
          'Average pH',
          'Average EC',
          'Average Temp',
          'Status',
        ];
        rows = sensorRows;
      }
    } catch (_) {
      errorMessage = 'Failed to load sensor history from Supabase';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSingleRow(int index) async {
    if (index >= 0 && index < rows.length) {
      rows.removeAt(index);
      selectedRowIndices.remove(index);
      notifyListeners();
    }
  }

  Future<void> deleteSelectedRows() async {
    final sortedIndices = selectedRowIndices.toList()
      ..sort((a, b) => b.compareTo(a));
    for (final idx in sortedIndices) {
      if (idx >= 0 && idx < rows.length) {
        rows.removeAt(idx);
      }
    }
    selectedRowIndices.clear();
    isSelectionMode = false;
    notifyListeners();
  }

  Future<void> updateRowValues(
      int index, double newPh, double newEc, double newTemp) async {
    if (index >= 0 && index < rows.length) {
      final oldEntry = rows[index];
      final newValues = List<String>.from(oldEntry.values);

      final valueStart = selectedRange == 'Monthly' ? 1 : 2;

      if (newValues.length > valueStart + 2) {
        newValues[valueStart] = newPh.toStringAsFixed(2);
        newValues[valueStart + 1] = '${newEc.toStringAsFixed(2)} mS/cm';
        newValues[valueStart + 2] = '${newTemp.toStringAsFixed(1)} °C';
      }

      rows[index] = HistoryLogEntry(
        newValues,
        ranges: oldEntry.ranges,
      );
      notifyListeners();
    }
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