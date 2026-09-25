import 'package:flutter/material.dart';
import 'side_nav.dart';
import '../services/app_state.dart';
import '../screens/dashboard_screen.dart';
import '../screens/forecasting_dashboard_screen.dart';
import '../screens/history_logs_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/help_screen.dart';
import '../screens/admin_settings_screen.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
  });

  void navigateTo(BuildContext context, int index) {
    if (index == selectedIndex) return;
    final navigator = Navigator.of(context);
    Navigator.pop(context);

    switch (index) {
      case 0: // Dashboard
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        break;
      case 1: // Forecasts
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const ForecastingDashboardScreen()),
        );
        break;
      case 2: // History logs
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const HistoryLogsScreen()),
        );
        break;
      case 3: // Reports
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
        break;
      case 4: // Settings
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
      case 5: // Help
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const HelpScreen()),
        );
        break;
      case 6: // Admin settings
        if (appProfile.value?.isAdmin == true) {
          navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 260,
      child: SafeArea(
        child: SideNav(
          selectedIndex: selectedIndex,
          onSelect: (index) => navigateTo(context, index),
        ),
      ),
    );
  }
}