import 'app_confirm_dialog.dart';
import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'side_nav.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
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
  final bool? isOffline;
  final bool isCalibrating;
  final DateTime? lastReceived;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    this.isOffline,
    this.isCalibrating = false,
    this.lastReceived,
  });

  void navigateTo(BuildContext context, int index) {
    if (index == selectedIndex) {
      Navigator.pop(context);
      return;
    }

    final navigator = Navigator.of(context);
    Navigator.pop(context);

    switch (index) {
      case 0: // Dashboard
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 1: // Forecasts
        navigator.pushReplacement(
          MaterialPageRoute(
              builder: (context) => const ForecastingDashboardScreen()),
        );
        break;
      case 2: // History logs
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const HistoryLogsScreen()),
        );
        break;
      case 3: // Reports
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const ReportsScreen()),
        );
        break;
      case 4: // Settings
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 5: // Help
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const HelpScreen()),
        );
        break;
      case 6: // Admin Settings
        if (appProfile.value?.isAdmin == true) {
          navigator.pushReplacement(
            MaterialPageRoute(
                builder: (context) => const AdminSettingsScreen()),
          );
        }
        break;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(context,
        title: 'Log out?',
        message: 'You will need to sign in again to access the monitoring app.',
        cancelLabel: 'No',
        confirmLabel: 'Log out',
        confirmColor: AppColors.alertText);
    if (confirmed != true || !context.mounted) return;
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => Drawer(
        width: 280,
        backgroundColor: const Color(0xFF173E0A),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
        clipBehavior: Clip.antiAlias,
        child: SideNav(
            selectedIndex: selectedIndex,
            onSelect: (index) => navigateTo(context, index),
            onClose: () => Navigator.pop(context),
            onLogout: () => _logout(context),
            isOffline: isOffline,
            isCalibrating: isCalibrating,
            lastReceived: lastReceived),
      );
}
