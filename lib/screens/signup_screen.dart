import 'package:flutter/material.dart';
import '../config/public_page_content.dart';
import '../controllers/signup_controller.dart';
import '../theme/public_page_styles.dart';
import '../utils/email_mask.dart';
import '../widgets/public_pages/public_auth_form.dart';
import '../widgets/public_pages/public_auth_layout.dart';
import 'dashboard_screen.dart';
import 'landing_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final SignupController _controller = SignupController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    final success = await _controller.createAccount();
    if (!mounted) return;
    if (success && !_controller.isOtpStep) {
      Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (context) => const DashboardScreen()),
);
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage!)),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final success = await _controller.verifyOtp();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (context) => const DashboardScreen()),
);
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage!)),
      );
    }
  }

  Future<void> _handleResendOtp() async {
    final success = await _controller.resendOtp();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'A new verification code was sent.'
              : _controller.errorMessage ?? 'Unable to resend the code.',
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignup() async {
    final success = await _controller.signUpWithGoogle();
    if (!mounted) return;
    if (!success && _controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage!)),
      );
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
        if (_controller.isOtpStep) {
          return _buildOtpForm(compact: compact, dense: dense);
        }

        return PublicAuthForm(
          heading: 'Create your account',
          description: 'Enter your details below to get started.',
          compact: compact,
          dense: dense,
          children: [
            PublicAuthField(
              controller: _controller.nameController,
              label: 'Your name',
              hint: 'John Doe',
              dense: dense,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
            ),
            PublicAuthField(
              controller: _controller.emailController,
              label: PublicPageContent.emailLabel,
              hint: PublicPageContent.emailHint,
              dense: dense,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            PublicAuthField(
              controller: _controller.passwordController,
              label: PublicPageContent.passwordLabel,
              hint: PublicPageContent.passwordHint,
              dense: dense,
              obscureText: _controller.obscurePassword,
              onToggleObscureText: _controller.togglePasswordVisibility,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            PublicAuthField(
              controller: _controller.confirmPasswordController,
              label: 'Confirm password',
              hint: PublicPageContent.passwordHint,
              dense: dense,
              obscureText: _controller.obscureConfirmPassword,
              onToggleObscureText: _controller.toggleConfirmPasswordVisibility,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_controller.isLoading) _handleCreateAccount();
              },
            ),
            PublicAuthButton(
              text: 'Create Account',
              onPressed: _handleCreateAccount,
              isLoading: _controller.isLoading,
              dense: dense,
            ),
            SizedBox(height: dense ? 12 : 20),
            Row(
              children: [
                const Expanded(child: Divider(color: PublicPageStyles.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    PublicPageContent.alternativeLogin,
                    style: PublicPageStyles.meta,
                  ),
                ),
                const Expanded(child: Divider(color: PublicPageStyles.border)),
              ],
            ),
            SizedBox(height: dense ? 12 : 20),
            PublicAuthButton(
              text: 'Sign Up with Google',
              onPressed: _handleGoogleSignup,
              isLoading: _controller.isLoading,
              dense: dense,
              secondary: true,
            ),
            SizedBox(height: dense ? 12 : 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
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
      },
    );
  }

  Widget _buildOtpForm({bool compact = false, bool dense = false}) {
    final maskedEmail = maskEmail(_controller.emailController.text.trim());

    return PublicAuthForm(
      heading: 'Verify your email',
      description: 'Enter the 6-digit code sent to $maskedEmail.',
      compact: compact,
      dense: dense,
      children: [
        PublicAuthField(
          controller: _controller.otpController,
          label: 'Verification code',
          hint: '123456',
          dense: dense,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          onSubmitted: (_) {
            if (!_controller.isLoading) _handleVerifyOtp();
          },
        ),
        PublicAuthButton(
          text: 'Verify Account',
          onPressed: _handleVerifyOtp,
          isLoading: _controller.isLoading,
          dense: dense,
        ),
        SizedBox(height: dense ? 10 : 14),
        Center(
          child: TextButton(
            onPressed: _controller.isLoading ? null : _handleResendOtp,
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
            text: 'Back to login',
            onPressed: _controller.isLoading
                ? null
                : () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}