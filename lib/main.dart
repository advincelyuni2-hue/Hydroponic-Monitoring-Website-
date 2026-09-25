import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/app_state.dart';
import 'services/supabase_client.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();

  // Restore session & profile if a user is already logged in on startup
  final client = supabaseClient;
  final currentUser = client?.auth.currentUser;
  if (currentUser != null) {
    try {
      final profile = await UserService().getProfile(currentUser.id);
      setAppProfile(profile);
    } catch (e) {
      debugPrint('Failed to restore user profile on app startup: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final client = supabaseClient;
    final isLoggedIn = client?.auth.currentUser != null;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Hydroponic Monitoring',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
        );
      },
    );
  }
}