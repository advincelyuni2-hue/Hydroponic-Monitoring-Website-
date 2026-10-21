import 'package:flutter/material.dart';
import 'app_text_styles.dart';

/// Scoped to public pages; never changes the application's saved theme.
class PublicPageStyles {
  PublicPageStyles._();

  static const background = Color(0xFFFDFDF0);
  static const ink = Color(0xFF192610);
  static const muted = Color(0xFF626B56);
  static const green = Color(0xFF2D6A0D);
  static const forest = Color(0xFF17370B);
  static const lime = Color(0xFFAFE36C);
  static const sand = Color(0xFFDEDDB8);
  static const border = Color(0xFFDDDFC8);
  static const placeholder = Color(0xFFE6EED3);
  static const stripe = Color(0xFFDCE7C7);
  static const panelRadius = 28.0;
  static const contentWidth = 480.0;

  static TextStyle get heading => AppTextStyles.title.copyWith(color: ink);
  static TextStyle get body =>
      AppTextStyles.body.copyWith(color: muted, fontSize: 16, height: 1.55);
  static TextStyle get label => AppTextStyles.label.copyWith(color: ink);
  static TextStyle get meta => AppTextStyles.cardMeta.copyWith(color: muted);
  static TextStyle get button =>
      AppTextStyles.button.copyWith(color: Colors.white);
  static TextStyle get darkButton => AppTextStyles.button.copyWith(color: ink);

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: green,
        onPrimary: Colors.white,
        surface: background,
        onSurface: ink,
        onSurfaceVariant: muted,
      ),
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: green,
        selectionColor: placeholder,
        selectionHandleColor: green,
      ),
      checkboxTheme: const CheckboxThemeData(
        side: BorderSide(color: green),
      ),
    );
  }
}
