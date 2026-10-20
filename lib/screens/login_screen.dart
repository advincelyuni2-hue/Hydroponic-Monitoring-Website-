import 'package:flutter/material.dart';
import '../services/supabase_client.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../config/public_page_content.dart';
import '../theme/public_page_styles.dart';
import '../widgets/public_pages/login_form.dart';
import '../widgets/public_pages/public_auth_layout.dart';
import '../controllers/login_controller.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'landing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController _controller = LoginController();

  @override
  void initState() {
    super.initState();
    _restoreAuthenticatedSession();
  }

  Future<void> _restoreAuthenticatedSession() async {
    final client = supabaseClient;
    final user = client?.auth.currentUser;
    if (user == null || !mounted) return;

    final profile = await UserService().getProfile(user.id);
    if (!profile.isActive) {
      await AuthService().logout();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final success = await _controller.login();
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PublicAuthLayout(
        loginBenefits: true,
        navigation: _buildAboutNavigation(),
        formBuilder: (_, compact, dense) =>
            _buildFormSection(compact: compact, dense: dense),
      );

  void _openAbout() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (landingContext) => LandingScreen(
        onLogin: () => Navigator.of(landingContext).pop(),
      ),
    ));
  }

  Widget _buildAboutNavigation() => Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton(
        onPressed: _openAbout,
        style: OutlinedButton.styleFrom(
          foregroundColor: PublicPageStyles.green,
          side: const BorderSide(color: PublicPageStyles.green),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text(PublicPageContent.aboutLink),
      ),
    );

  Widget _buildFormSection({bool compact = false, bool dense = false}) =>
      LoginForm(
        controller: _controller,
        compact: compact,
        dense: dense,
        onLogin: _handleLogin,
        onForgotPassword: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
        },
        onSignup: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SignupScreen()));
        },
      );
}
