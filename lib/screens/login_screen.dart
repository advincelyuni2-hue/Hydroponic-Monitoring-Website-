import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../controllers/login_controller.dart';
import '../utils/responsive.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController _controller = LoginController();

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= Responsive.tabletMaxWidth;
            final isMobile = constraints.maxWidth < Responsive.mobileMaxWidth;
            final formSection = _buildFormSection(isMobile: isMobile);

            if (isDesktop) {
              // Desktop / wide screen: image on the left, form on the right
              return Row(
                children: [
                  Expanded(flex: 1, child: _buildImagePlaceholder()),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                        child: formSection,
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              child: Center(child: formSection),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.imagePlaceholder,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildFormSection({required bool isMobile}) {
    // ListenableBuilder rebuilds this section whenever the controller
    // calls notifyListeners() (e.g. loading starts/stops, checkbox toggled).
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Login your account',
                style: AppTextStyles.title.copyWith(fontSize: isMobile ? 26 : 32),
              ),
              SizedBox(height: isMobile ? 24 : 32),

              Text('Your email', style: AppTextStyles.label),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _controller.emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              Text('Password', style: AppTextStyles.label),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _controller.passwordController,
                obscureText: _controller.obscurePassword,
              ),
              const SizedBox(height: 16),

            
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _controller.rememberMe,
                          onChanged: _controller.toggleRememberMe,
                          side: const BorderSide(color: AppColors.checkboxBorder),
                        ),
                        Text('Remember me', style: AppTextStyles.bodySmall),
                      ],
                    ),
                    TextButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  },
  style: TextButton.styleFrom(padding: EdgeInsets.zero),
  child: Text('Forgot Password?', style: AppTextStyles.bodySmall),
),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 20 : 24),

              CustomButton(
                text: 'Log In',
                backgroundColor: AppColors.primaryButton,
                textStyle: AppTextStyles.button,
                isLoading: _controller.isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 16),

              CustomButton(
                text: 'Log In with Google',
                backgroundColor: AppColors.googleButton,
                textStyle: AppTextStyles.buttonDark,
                onPressed: () async {
                  await _controller.loginWithGoogle();
                },
              ),
              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.footer,
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(text: 'Sign up', style: AppTextStyles.footerLink),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    );
                  },
                  child: Text(
                    '[DEV] Skip to Dashboard →',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
