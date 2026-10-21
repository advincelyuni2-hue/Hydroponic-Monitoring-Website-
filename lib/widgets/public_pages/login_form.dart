import 'package:flutter/material.dart';
import '../../config/public_page_content.dart';
import '../../controllers/login_controller.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/public_page_styles.dart';
import '../custom_button.dart';
import 'public_auth_layout.dart';
import 'public_auth_form.dart';

/// Presentation only: the screen retains ownership of the login controller.
class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.controller,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onSignup,
    this.compact = false,
    this.dense = false,
  });

  final LoginController controller;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignup;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (MobileAuthPresentation.maybeOf(context) != null) return _mobileForm(context);
        return ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: PublicPageStyles.contentWidth),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // EDIT TEXT HERE: Login heading (public_page_content.dart).
                Text(PublicPageContent.loginHeading,
                    style: PublicPageStyles.heading.copyWith(
                        fontSize: compact || dense ? 30 : 38,
                        letterSpacing: -1)),
                const SizedBox(height: 8),
                Text(PublicPageContent.loginDescription,
                    style: PublicPageStyles.body),
                SizedBox(height: dense ? 12 : 22),
                Text(PublicPageContent.emailLabel,
                    style: PublicPageStyles.label),
                const SizedBox(height: 8),
                _buildInput(
                  controller: controller.emailController,
                  hint: PublicPageContent.emailHint,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: dense ? 12 : 20),
                Text(PublicPageContent.passwordLabel,
                    style: PublicPageStyles.label),
                const SizedBox(height: 8),
                _buildInput(
                  controller: controller.passwordController,
                  hint: PublicPageContent.passwordHint,
                  obscureText: controller.obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!controller.isLoading) onLogin();
                  },
                  suffixIcon: IconButton(
                    tooltip: controller.obscurePassword
                        ? PublicPageContent.showPassword
                        : PublicPageContent.hidePassword,
                    onPressed: controller.togglePasswordVisibility,
                    icon: Icon(
                      controller.obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: PublicPageStyles.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Checkbox(
                        value: controller.rememberMe,
                        onChanged: controller.toggleRememberMe,
                        activeColor: PublicPageStyles.green,
                      ),
                      Flexible(
                        child: Text(PublicPageContent.rememberMe,
                            style:
                                PublicPageStyles.body.copyWith(fontSize: 14)),
                      ),
                    ]),
                    TextButton(
                      onPressed: onForgotPassword,
                      child: Text(PublicPageContent.forgotPassword,
                          style: PublicPageStyles.body.copyWith(
                              fontSize: 14,
                              color: PublicPageStyles.green,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: PublicPageContent.loginButton,
                  height: dense ? 48 : 56,
                  backgroundColor: PublicPageStyles.green,
                  textStyle: PublicPageStyles.button,
                  isLoading: controller.isLoading,
                  onPressed: onLogin,
                ),
                SizedBox(height: dense ? 12 : 20),
                Row(children: [
                  const Expanded(
                      child: Divider(color: PublicPageStyles.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(PublicPageContent.alternativeLogin,
                        style: PublicPageStyles.meta),
                  ),
                  const Expanded(
                      child: Divider(color: PublicPageStyles.border)),
                ]),
                SizedBox(height: dense ? 12 : 20),
                ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () async {
                          final success = await controller.loginWithGoogle();
                          if (!context.mounted) return;
                          if (!success && controller.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(controller.errorMessage!)),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PublicPageStyles.sand,
                    foregroundColor: PublicPageStyles.ink,
                    elevation: 0,
                    minimumSize: Size(0, dense ? 48 : 56),
                    padding: EdgeInsets.symmetric(
                        horizontal: 18, vertical: dense ? 12 : 16),
                    shape: const StadiumBorder(),
                  ),
                  child: controller.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              child: Text('G',
                                  style: TextStyle(
                                      color: PublicPageStyles.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(PublicPageContent.googleLoginButton,
                                  textAlign: TextAlign.center,
                                  style: PublicPageStyles.darkButton),
                            ),
                          ],
                        ),
                ),
                SizedBox(height: dense ? 10 : 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(PublicPageContent.signupPrompt,
                        style: PublicPageStyles.body.copyWith(fontSize: 14)),
                    TextButton(
                      onPressed: onSignup,
                      child: Text(PublicPageContent.signupLink,
                          style: PublicPageStyles.label
                              .copyWith(decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileForm(BuildContext context) => PublicAuthForm(
    heading: PublicPageContent.loginHeading,
    description: PublicPageContent.loginDescription,
    compact: true, dense: true,
    children: [
      PublicAuthField(controller: controller.emailController,
        label: PublicPageContent.emailLabel, hint: PublicPageContent.emailHint,
        dense: true, keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.username]),
      PublicAuthField(controller: controller.passwordController,
        label: PublicPageContent.passwordLabel, hint: PublicPageContent.passwordHint,
        dense: true, obscureText: controller.obscurePassword,
        onToggleObscureText: controller.togglePasswordVisibility,
        autofillHints: const [AutofillHints.password], textInputAction: TextInputAction.done,
        onSubmitted: (_) { if (!controller.isLoading) onLogin(); }),
      Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 24, child: Checkbox(value: controller.rememberMe,
              onChanged: controller.toggleRememberMe, activeColor: PublicPageStyles.green)),
            const SizedBox(width: 4),
            Text(PublicPageContent.rememberMe, style: PublicPageStyles.body.copyWith(fontSize: 12)),
          ]),
          TextButton(onPressed: onForgotPassword,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(PublicPageContent.forgotPassword,
              style: PublicPageStyles.body.copyWith(fontSize: 12, color: PublicPageStyles.green,
                decoration: TextDecoration.underline))),
        ]),
      const SizedBox(height: 4),
      PublicAuthButton(text: PublicPageContent.loginButton, onPressed: onLogin,
        isLoading: controller.isLoading, dense: true),
      const SizedBox(height: 14),
      Row(children: [const Expanded(child: Divider(color: PublicPageStyles.border)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(PublicPageContent.alternativeLogin, style: PublicPageStyles.meta)),
        const Expanded(child: Divider(color: PublicPageStyles.border))]),
      const SizedBox(height: 14),
      PublicAuthButton(text: PublicPageContent.googleLoginButton, secondary: true,
        isLoading: controller.isLoading, dense: true,
        onPressed: () async {
          final success = await controller.loginWithGoogle();
          if (!context.mounted) return;
          if (!success && controller.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
          }
        }),
      Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(PublicPageContent.signupPrompt, style: PublicPageStyles.body.copyWith(fontSize: 12)),
          PublicAuthLink(text: PublicPageContent.signupLink, onPressed: onSignup),
        ]),
    ],
  );

  // Public-only field styling keeps shared fields on other screens unchanged.
  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required Iterable<String> autofillHints,
    required TextInputAction textInputAction,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: PublicPageStyles.border),
    );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: AppTextStyles.input
          .copyWith(color: PublicPageStyles.ink, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            PublicPageStyles.body.copyWith(color: PublicPageStyles.muted),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 18, vertical: dense ? 12 : 18),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
            borderSide:
                const BorderSide(color: PublicPageStyles.green, width: 1.5)),
      ),
    );
  }
}
