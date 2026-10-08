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

  String selectedTab =
      'Sensor logs'; // 'Sensor logs' | 'Calibration logs' | 'Intervention logs'
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
      } catch (_) {
        errorMessage = 'Failed to load calibration logs from Supabase';
      } finally {
        isLoading = false;
        notifyListeners();
      }
      return;
    }

    if (selectedTab == 'Intervention logs') {
      isLoading = true;
      errorMessage = null;
      columns = MonitoringService.interventionLogColumns;
      notifyListeners();

      try {
        final range = _selectedDateRange();
        rows = await monitoringService.getInterventionHistory(
          start: range.start,
          end: range.end,
        );
      } catch (_) {
        errorMessage = 'Failed to load intervention logs from Supabase';
      } finally {
        isLoading = false;
        notifyListeners();
      }
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
        _ => HistoryAggregation.fiveMinutes,
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
    if (index < 0 || index >= rows.length) return;

    final entry = rows[index];
    final recordStart = entry.recordStart;

    if (recordStart == null) {
      throw StateError('This log entry has no saved timestamp.');
    }

    if (selectedTab == 'Sensor logs') {
      final duration = entry.recordDuration;

      if (duration == null) {
        throw StateError('This sensor log has no saved time range.');
      }

      await monitoringService.deleteSingleSensorHistoryBucket(
        start: recordStart,
        end: recordStart.add(duration),
      );
    } else if (selectedTab == 'Calibration logs') {
      await monitoringService.deleteCalibrationLog(recordStart);
    } else {
      throw StateError('This log type cannot be deleted here.');
    }

    // Remove it from the screen only after the database delete succeeds.
    rows.removeAt(index);
    selectedRowIndices.remove(index);
    notifyListeners();
  }

  Future<void> deleteSelectedRows() async {
    final sortedIndices = selectedRowIndices.toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedIndices.isEmpty) return;

    var deletedCount = 0;

    try {
      for (final index in sortedIndices) {
        if (index < 0 || index >= rows.length) continue;

        final entry = rows[index];
        final recordStart = entry.recordStart;

        if (recordStart == null) {
          throw StateError('A selected log has no saved timestamp.');
        }

        if (selectedTab == 'Sensor logs') {
          final duration = entry.recordDuration;

          if (duration == null) {
            throw StateError('A selected sensor log has no saved time range.');
          }

          await monitoringService.deleteSingleSensorHistoryBucket(
            start: recordStart,
            end: recordStart.add(duration),
          );
        } else if (selectedTab == 'Calibration logs') {
          await monitoringService.deleteCalibrationLog(recordStart);
        } else {
          throw StateError('These selected logs cannot be deleted here.');
        }

        // Remove this row from the screen only after its database delete succeeds.
        rows.removeAt(index);
        deletedCount++;
      }
    } catch (error) {
      selectedRowIndices.clear();
      isSelectionMode = false;
      notifyListeners();

      throw StateError(
        'Deleted $deletedCount of ${sortedIndices.length} selected logs. '
        'Refresh the table and check which rows remain. Details: $error',
      );
    }

    selectedRowIndices.clear();
    isSelectionMode = false;
    notifyListeners();
  }

  Future<void> updateRowValues(
      int index, double newPh, double newEc, double newTemp) async {
    if (index >= 0 && index < rows.length) {
      final oldEntry = rows[index];
      final recordStart = oldEntry.recordStart;
      final recordDuration = oldEntry.recordDuration;

      if (recordStart == null || recordDuration == null) {
        throw StateError('This history row cannot be saved.');
      }

      // Save the edited sensor averages to Supabase first.
      await monitoringService.updateSensorHistoryBucket(
        start: recordStart,
        end: recordStart.add(recordDuration),
        ph: newPh,
        ec: newEc,
        temperature: newTemp,
      );

      // Keep the existing local display update.
      final newValues = List<String>.from(oldEntry.values);
      final valueStart = selectedRange == 'Monthly' ? 1 : 2;

      if (newValues.length > valueStart + 2) {
        newValues[valueStart] = newPh.toStringAsFixed(6);
        newValues[valueStart + 1] = '${newEc.toStringAsFixed(6)} mS/cm';
        newValues[valueStart + 2] = '${newTemp.toStringAsFixed(1)} °C';
      }

      final start = oldEntry.recordStart;
      if (start == null) {
        throw StateError('This log does not have a database timestamp.');
      }
      await monitoringService.updateSensorHistoryBucket(
        start: start,
        end: start.add(
          oldEntry.recordDuration ?? const Duration(minutes: 5),
        ),
        ph: newPh,
        ec: newEc,
        temperature: newTemp,
      );

      rows[index] = HistoryLogEntry(
        newValues,
        ranges: oldEntry.ranges,
        recordStart: oldEntry.recordStart,
        recordDuration: oldEntry.recordDuration,
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
