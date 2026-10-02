import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../controllers/forgot_password_controller.dart';
import '../utils/responsive.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ForgotPasswordController _controller = ForgotPasswordController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final success = await _controller.sendResetLink();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.successMessage!),
          backgroundColor: Colors.green[700],
        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 32,
                        ),
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
                'Forgot Password',
                style: AppTextStyles.title.copyWith(
                  fontSize: isMobile ? 26 : 32,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Enter your email address and we'll send you instructions to reset your password.",
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              SizedBox(height: isMobile ? 24 : 32),

              Text('Your email', style: AppTextStyles.label),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _controller.emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: isMobile ? 24 : 32),

              CustomButton(
                text: 'Send Reset Link',
                backgroundColor: AppColors.primaryButton,
                textStyle: AppTextStyles.button,
                isLoading: _controller.isLoading,
                onPressed: _handleResetPassword,
              ),
              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.footer,
                      children: [
                        const TextSpan(text: 'Remember your password? '),
                        TextSpan(
                          text: 'Log in',
                          style: AppTextStyles.footerLink,
                        ),
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