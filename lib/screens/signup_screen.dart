import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../controllers/signup_controller.dart';
import '../utils/responsive.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final SignupController _controller = SignupController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    final success = await _controller.createAccount();
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
                'Create your account',
                style: AppTextStyles.title.copyWith(fontSize: isMobile ? 26 : 32),
              ),
              SizedBox(height: isMobile ? 24 : 32),

              Text('Your name', style: AppTextStyles.label),
              const SizedBox(height: 8),
              CustomTextField(controller: _controller.nameController),
              const SizedBox(height: 24),

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
              const SizedBox(height: 24),

              Text('Confirm password', style: AppTextStyles.label),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _controller.confirmPasswordController,
                obscureText: _controller.obscureConfirmPassword,
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Create Account',
                backgroundColor: AppColors.primaryButton,
                textStyle: AppTextStyles.button,
                isLoading: _controller.isLoading,
                onPressed: _handleCreateAccount,
              ),
              const SizedBox(height: 16),

              CustomButton(
                text: 'Sign Up with Google',
                backgroundColor: AppColors.googleButton,
                textStyle: AppTextStyles.buttonDark,
                onPressed: () {
                  
                },
              ),
              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.footer,
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(text: 'Log in', style: AppTextStyles.footerLink),
                      ],
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
