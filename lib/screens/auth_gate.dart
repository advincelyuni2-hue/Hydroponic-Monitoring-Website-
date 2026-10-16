import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _sub;
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Opened from a reset-password email: wait for the recovery event.
    final isResetLink = Uri.base.queryParameters['reset'] == '1';
    final restored = isResetLink ? false : await AuthService().restoreSession();
    if (!mounted) return;
    setState(() {
      _home = restored ? const DashboardScreen() : const LoginScreen();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _home ??
        const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}