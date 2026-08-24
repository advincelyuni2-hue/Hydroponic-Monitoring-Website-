import 'package:flutter/material.dart';
import 'theme_mode_controller.dart';


class AppColors {
  AppColors._(); 

  // Background
  static Color get background => _isDark ? const Color(0xFF121712) : const Color(0xFFFDFDF0);

  // Left-side image placeholder
  static const Color imagePlaceholder = Color(0xFFD9D9D9);

  // Text
  static Color get textPrimary => _isDark ? Colors.white : const Color(0xFF1A1A1A);
  static Color get textSecondary =>
      _isDark ? const Color(0xFFB8C2B8) : const Color(0xFF8A8A8A);

  // Buttons
  static const Color primaryButton = Color(0xFF2D6A0D); // dark green "Log In"
  static const Color primaryButtonText = Color(0xFFFFFFFF);
  static const Color googleButton = Color(0xFFD6D3AE); // tan "Log In with Google"
  static const Color googleButtonText = Color(0xFF1A1A1A);

  // Inputs
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFE0E0E0);

  // Checkbox
  static const Color checkboxBorder = Color(0xFFBDBDBD);

  // Dashboard cards
    static Color get cardBackground => _isDark ? const Color(0xFF1B211B) : Colors.white;
    static Color get cardBorder =>
      _isDark ? const Color(0xFF4C584C) : const Color(0xFFECECEC);
    static Color get statusCardGreen =>
      _isDark ? const Color(0xFF2B4728) : const Color(0xFFE3F2D3);
    static Color get statusCardYellow =>
      _isDark ? const Color(0xFF4A4525) : const Color(0xFFF7F2CE);

  // Alerts
  static const Color alertBorder = Color(0xFFD9483C);
  static const Color alertText = Color(0xFFD9483C);
  static Color get alertBackground =>
      _isDark ? const Color(0xFF4A2422) : const Color(0xFFFCECEA);

  // Icon circles (header)
  static const Color iconCircle = Color(0xFF2D6A0D);

  // Side navigation
  static const Color sidebarBackground = Color.fromARGB(255, 51, 84, 45);
  static const Color sidebarSelectedBackground = Color(0xFFFFFFFF);
  static const Color sidebarText = Color(0xFFFFFFFF);

  // Charts
  static const Color chartLine = Color(0xFF2D6A0D);
  static const Color chartGrid = Color(0xFFE0E0E0);

  // Prediction Insights callout box
  static Color get calloutBackground =>
      _isDark ? const Color(0xFF293129) : const Color(0xFFEDEDED);

  //HIstory table
  static Color get tableStripe =>
      _isDark ? const Color(0xFF252D25) : const Color.fromARGB(255, 247, 249, 241);

  static bool get _isDark => appThemeMode.value == ThemeMode.dark;
}
