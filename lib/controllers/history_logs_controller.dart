import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../services/user_service.dart';

class HistoryLogsController extends ChangeNotifier {
  final UserService _userService = UserService();

  bool isLoading = true;
  String? errorMessage;

  UserProfile? profile;

  String selectedTab = 'Sensor logs'; // 'Sensor logs' | 'Calibration logs'
  String selectedRange = 'Daily';     // 'Daily' | 'Weekly' | 'Monthly'

  DateTime selectedDate = DateTime(2026, 7, 18);
  DateTimeRange? selectedWeekRange;

  List<String> columns = [];
  List<HistoryLogEntry> rows = [];

  HistoryLogsController() {
    _initWeekRange();
    loadData();
  }


void _initWeekRange() {
  final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final end = start.add(const Duration(days: 6));
  selectedWeekRange = DateTimeRange(
    start: start,
    end: DateTime(end.year, end.month, end.day, 23, 59, 59),
  );
}

  String get activeRangeLabel {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
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
      profile = await _userService.getProfile('mock-user-id');
      _generateTableData();
    } catch (e) {
      errorMessage = 'Failed to load history logs';
    }

    isLoading = false;
    notifyListeners();
  }

  void selectTab(String tab) {
    if (selectedTab == tab) return;
    selectedTab = tab;
    _generateTableData();
    notifyListeners();
  }

  void selectRange(String range) {
    selectedRange = range;
    _generateTableData();
    notifyListeners();
  }

  void updateDate(DateTime date, DateTimeRange? weekRange) {
    selectedDate = date;
    if (weekRange != null) {
      selectedWeekRange = weekRange;
    } else {
      _initWeekRange();
    }
    _generateTableData();
    notifyListeners();
  }

  void _generateTableData() {
    final isSensor = selectedTab == 'Sensor logs';

    if (selectedRange == 'Daily') {
      columns = isSensor
          ? ['Time', 'Parameter', 'Recorded Value', 'Status']
          : ['Time', 'Sensor', 'Action', 'Status'];

      rows = isSensor
          ? const [
              HistoryLogEntry(['8:00 AM', 'pH Level', '6.5', 'Normal']),
              HistoryLogEntry(['10:30 AM', 'EC Level', '1.8 mS/cm', 'Normal']),
              HistoryLogEntry(['1:15 PM', 'Water Temp', '24.2 °C', 'Warning']),
              HistoryLogEntry(['4:00 PM', 'pH Level', '6.2', 'Normal']),
            ]
          : const [
              HistoryLogEntry(['9:00 AM', 'pH Sensor', '2-Point Cal', 'Completed']),
              HistoryLogEntry(['2:30 PM', 'EC Probe', 'Slope Adjust', 'Completed']),
            ];
    } else if (selectedRange == 'Weekly') {
      columns = isSensor
          ? ['Week', 'Avg pH', 'Avg EC', 'Status']
          : ['Week', 'Sensor', 'Calibrations', 'Status'];

      rows = isSensor
          ? const [
              HistoryLogEntry(['Week 1', '6.4', '1.7 mS/cm', 'Normal']),
              HistoryLogEntry(['Week 2', '6.5', '1.8 mS/cm', 'Normal']),
              HistoryLogEntry(['Week 3', '6.2', '2.0 mS/cm', 'Warning']),
              HistoryLogEntry(['Week 4', '6.6', '1.8 mS/cm', 'Normal']),
            ]
          : const [
              HistoryLogEntry(['Week 1', 'pH Sensor', '2 Runs', 'Verified']),
              HistoryLogEntry(['Week 2', 'EC Probe', '1 Run', 'Verified']),
            ];
    } else {
      // Monthly
      columns = isSensor
          ? ['Date', 'Avg pH', 'Avg EC', 'Status']
          : ['Date', 'Sensor', 'Calibrations', 'Status'];

      rows = isSensor
          ? const [
              HistoryLogEntry(['Jul 01, 2026', '6.4', '1.7 mS/cm', 'Normal']),
              HistoryLogEntry(['Jul 02, 2026', '6.5', '1.8 mS/cm', 'Normal']),
              HistoryLogEntry(['Jul 03, 2026', '6.3', '1.9 mS/cm', 'Normal']),
              HistoryLogEntry(['Jul 04, 2026', '6.1', '2.1 mS/cm', 'Warning']),
              HistoryLogEntry(['Jul 05, 2026', '6.5', '1.8 mS/cm', 'Normal']),
            ]
          : const [
              HistoryLogEntry(['Jul 01, 2026', 'pH Sensor', '1 Cal', 'Completed']),
              HistoryLogEntry(['Jul 15, 2026', 'EC Probe', '1 Cal', 'Completed']),
            ];
    }
  }
}