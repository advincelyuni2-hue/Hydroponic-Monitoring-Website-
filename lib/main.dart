import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'screens/auth_gate.dart';
import 'services/supabase_client.dart';
import 'theme/theme_mode_controller.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'widgets/idle_session_guard.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  await loadSavedPreferences();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Monitoring App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          builder: (context, child) {
            return IdleSessionGuard(
              onTimeout: () async {
                try {
                  await AuthService().logout();
                } finally {
                  appNavigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AuthGate(),
        );
      },
    );
  }
}
