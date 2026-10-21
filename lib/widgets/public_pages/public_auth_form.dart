import 'package:flutter/material.dart';
import '../../config/public_page_content.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/public_page_styles.dart';
import '../custom_button.dart';
import 'public_brand.dart';
import 'public_auth_layout.dart';

/// Shared form presentation; validation and submission stay with each screen.
class PublicAuthForm extends StatelessWidget {
  const PublicAuthForm(
      {super.key,
      required this.heading,
      required this.description,
      required this.children,
      required this.compact,
      required this.dense});
  final String heading;
  final String description;
  final List<Widget> children;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final mobile = MobileAuthPresentation.maybeOf(context);
    if (mobile != null) {
      final hasFooter = children.isNotEmpty && children.last is Wrap;
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: mobile.minimumFormHeight),
        child: IntrinsicHeight(child: AutofillGroup(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(heading, textAlign: TextAlign.center,
              style: PublicPageStyles.heading.copyWith(fontSize: 25, letterSpacing: -0.7)),
            const SizedBox(height: 6),
            Text(description, textAlign: TextAlign.center,
              style: PublicPageStyles.body.copyWith(fontSize: 13, height: 1.35)),
            const SizedBox(height: 24),
            ...children.take(hasFooter ? children.length - 1 : children.length),
            if (hasFooter) ...[const Spacer(), const SizedBox(height: 20), children.last],
          ],
        ))),
      );
    }
    return ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: PublicPageStyles.contentWidth),
        child: AutofillGroup(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
  heading,
  style: PublicPageStyles.heading.copyWith(
    fontSize: compact || dense ? 30 : 38, 
    letterSpacing: -1,
  ),
),
const SizedBox(height: 8),
Text(description, style: PublicPageStyles.body),
SizedBox(height: dense ? 16 : 24),
...children,
          ],
        )),
      );
  }
}

class PublicAuthField extends StatelessWidget {
  const PublicAuthField(
      {super.key,
      required this.controller,
      required this.label,
      required this.hint,
      this.dense = false,
      this.keyboardType = TextInputType.text,
      this.obscureText = false,
      this.onToggleObscureText,
      this.autofillHints,
      this.textInputAction = TextInputAction.next,
      this.onSubmitted});
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool dense;
  final TextInputType keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleObscureText;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final mobile = MobileAuthPresentation.maybeOf(context) != null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(mobile ? 28 : 14),
      borderSide: const BorderSide(color: PublicPageStyles.border),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 12 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: mobile ? PublicPageStyles.label.copyWith(fontSize: 12) : PublicPageStyles.label),
        const SizedBox(height: 8),
        TextField(
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
            hintStyle: mobile ? PublicPageStyles.body.copyWith(fontSize: 13) : PublicPageStyles.body,
            isDense: mobile,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 18, vertical: dense ? 12 : 18),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
                borderSide: const BorderSide(
                    color: PublicPageStyles.green, width: 1.5)),
            suffixIcon: onToggleObscureText == null
                ? null
                : IconButton(
                    onPressed: onToggleObscureText,
                    tooltip: obscureText
                        ? PublicPageContent.showPassword
                        : PublicPageContent.hidePassword,
                    icon: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: PublicPageStyles.muted),
                  ),
          ),
        ),
      ]),
    );
  }
}

class PublicAuthButton extends StatelessWidget {
  const PublicAuthButton(
      {super.key,
      required this.text,
      required this.onPressed,
      required this.isLoading,
      this.dense = false,
      this.secondary = false});
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool dense;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    if (MobileAuthPresentation.maybeOf(context) != null) {
      return SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary ? Colors.white : PublicPageStyles.green,
          foregroundColor: secondary ? PublicPageStyles.ink : Colors.white,
          elevation: 0, minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: const StadiumBorder(),
          side: secondary ? const BorderSide(color: PublicPageStyles.border) : null),
        child: isLoading ? SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2,
            color: secondary ? PublicPageStyles.green : Colors.white))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (secondary) ...[
                const CircleAvatar(radius: 10, backgroundColor: PublicPageStyles.placeholder,
                  child: Text('G', style: TextStyle(fontSize: 12, color: PublicPageStyles.green))),
                const SizedBox(width: 10),
              ],
              Flexible(child: Text(text, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: secondary ? FontWeight.w500 : FontWeight.w700))),
            ]),
      ));
    }
    return CustomButton(
        text: text,
        onPressed: onPressed,
        isLoading: isLoading,
        height: dense ? 48 : 56,
        backgroundColor:
            secondary ? PublicPageStyles.sand : PublicPageStyles.green,
        textStyle:
            secondary ? PublicPageStyles.darkButton : PublicPageStyles.button,
      );
  }
}

class PublicAuthLink extends StatelessWidget {
  const PublicAuthLink(
      {super.key, required this.text, required this.onPressed});
  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        child: Text(text,
            textAlign: TextAlign.center,
            style: PublicPageStyles.label.copyWith(
                fontSize: MobileAuthPresentation.maybeOf(context) != null ? 13 : null,
                decoration: MobileAuthPresentation.maybeOf(context) != null ? TextDecoration.underline : null,
                color: onPressed == null
                    ? PublicPageStyles.muted
                    : PublicPageStyles.green)),
      );
}
