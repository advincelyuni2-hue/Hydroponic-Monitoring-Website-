import 'package:flutter/material.dart';
import '../screens/admin_settings_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/forecasting_dashboard_screen.dart';
import '../screens/help_screen.dart';
import '../screens/history_logs_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../services/app_state.dart';

/// Opens a main screen by its side-menu index, the same way the side menu does.
/// 0 Dashboard, 1 Forecasts, 2 History logs, 3 Reports, 4 Settings, 5 Help,
/// 6 Admin settings (admins only).
void openAppPage(NavigatorState navigator, int index) {
  final Widget? page = switch (index) {
    0 => const DashboardScreen(),
    1 => const ForecastingDashboardScreen(),
    2 => const HistoryLogsScreen(),
    3 => const ReportsScreen(),
    4 => const SettingsScreen(),
    5 => const HelpScreen(),
    6 => appProfile.value?.isAdmin == true ? const AdminSettingsScreen() : null,
    _ => null,
  };
  if (page == null) return;
  navigator.pushReplacement(MaterialPageRoute(builder: (_) => page));
}