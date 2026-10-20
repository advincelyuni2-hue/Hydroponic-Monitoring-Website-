import 'package:flutter/material.dart';
import '../config/public_page_content.dart';
import '../controllers/forgot_password_controller.dart';
import '../theme/public_page_styles.dart';
import '../utils/email_mask.dart';
import '../widgets/public_pages/public_auth_form.dart';
import '../widgets/public_pages/public_auth_layout.dart';
import 'landing_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ForgotPasswordController _controller = ForgotPasswordController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String text, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  Future<void> _handleSendCode() async {
    final success = await _controller.sendCode();
    if (!mounted) return;
    if (success) {
      _snack(_controller.successMessage!, color: PublicPageStyles.green);
    } else if (_controller.errorMessage != null) {
      _snack(_controller.errorMessage!);
    }
  }

  Future<void> _handleResetPassword() async {
    final success = await _controller.resetPassword();
    if (!mounted) return;
    if (success) {
      _snack(_controller.successMessage!, color: PublicPageStyles.green);
      Navigator.of(context).pop(); // Back to login screen
    } else if (_controller.errorMessage != null) {
      _snack(_controller.errorMessage!);
    }
  }

  void _openAbout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (landingContext) => LandingScreen(
          onLogin: () => Navigator.of(landingContext).pop(),
        ),
      ),
    );
  }

  Widget _buildNavigation() => Align(
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

  @override
  Widget build(BuildContext context) {
    return PublicAuthLayout(
      navigation: _buildNavigation(),
      formBuilder: (context, compact, dense) => _buildFormSection(
        compact: compact,
        dense: dense,
      ),
    );
  }

  Widget _buildFormSection({bool compact = false, bool dense = false}) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isCodeStep) {
          return _buildCodeForm(compact: compact, dense: dense);
        }
        return _buildEmailForm(compact: compact, dense: dense);
      },
    );
  }

  Widget _buildEmailForm({bool compact = false, bool dense = false}) {
    return PublicAuthForm(
      heading: PublicPageContent.forgotPassword,
      description:
          "Enter your email address and we'll send you a verification code to reset your password.",
      compact: compact,
      dense: dense,
      children: [
        PublicAuthField(
          controller: _controller.emailController,
          label: PublicPageContent.emailLabel,
          hint: PublicPageContent.emailHint,
          dense: dense,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) {
            if (!_controller.isLoading) _handleSendCode();
          },
        ),
        PublicAuthButton(
          text: 'Send Verification Code',
          onPressed: _handleSendCode,
          isLoading: _controller.isLoading,
          dense: dense,
        ),
        SizedBox(height: dense ? 12 : 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Remember your password? ',
              style: PublicPageStyles.body.copyWith(fontSize: 14),
            ),
            PublicAuthLink(
              text: 'Log in',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCodeForm({bool compact = false, bool dense = false}) {
    final maskedEmail = maskEmail(_controller.emailController.text.trim());

    return PublicAuthForm(
      heading: 'Reset your password',
      description:
          'Enter the verification code sent to $maskedEmail and choose a new password.',
      compact: compact,
      dense: dense,
      children: [
        PublicAuthField(
          controller: _controller.codeController,
          label: 'Verification code',
          hint: '123456',
          dense: dense,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.oneTimeCode],
        ),
        PublicAuthField(
          controller: _controller.newPasswordController,
          label: 'New password',
          hint: PublicPageContent.passwordHint,
          dense: dense,
          obscureText: _controller.obscurePassword,
          onToggleObscureText: _controller.togglePasswordVisibility,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
        ),
        PublicAuthField(
          controller: _controller.confirmPasswordController,
          label: 'Confirm new password',
          hint: PublicPageContent.passwordHint,
          dense: dense,
          obscureText: _controller.obscureConfirmPassword,
          onToggleObscureText: _controller.toggleConfirmPasswordVisibility,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_controller.isLoading) _handleResetPassword();
          },
        ),
        PublicAuthButton(
          text: 'Reset Password',
          onPressed: _handleResetPassword,
          isLoading: _controller.isLoading,
          dense: dense,
        ),
        SizedBox(height: dense ? 10 : 14),
        Center(
          child: TextButton(
            onPressed: _controller.isLoading ? null : _handleSendCode,
            child: Text(
              'Resend code',
              style: PublicPageStyles.body.copyWith(
                fontSize: 14,
                color: PublicPageStyles.green,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        SizedBox(height: dense ? 6 : 10),
        Center(
          child: PublicAuthLink(
            text: 'Use a different email',
            onPressed: _controller.isLoading
                ? null
                : _controller.backToEmailStep,
          ),
        ),
      ],
    );
  }
}