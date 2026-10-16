import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'theme_mode_controller.dart';

/// Titles use Manrope (Bold). Everything else uses Work Sans.
class AppTextStyles {
  AppTextStyles._();

  static Color get _primaryText => appThemeMode.value == ThemeMode.dark
      ? Colors.white
      : AppColors.textPrimary;
  static Color get _secondaryText => appThemeMode.value == ThemeMode.dark
      ? const Color(0xFFB8C2B8)
      : AppColors.textSecondary;

  /// "Login your account"
  static TextStyle get title => GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: _primaryText,
  );

  /// "Your email" / "Password" labels above each field
  static TextStyle get label => GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _primaryText,
  );

  /// Text the user types inside input fields
  static TextStyle get input => GoogleFonts.workSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _primaryText,
  );

  /// "Remember me" / "Forgot Password?"
  static TextStyle get bodySmall => GoogleFonts.workSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: _secondaryText,
  );

  /// Text on the green "Log In" button
  static TextStyle get button => GoogleFonts.workSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryButtonText,
  );

  /// Text on the tan "Log In with Google" button
  static TextStyle get buttonDark => GoogleFonts.workSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.googleButtonText,
  );

  /// "Don't have an account?"
  static TextStyle get footer => GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _secondaryText,
  );

  /// "Sign up" (the clickable part)
  static TextStyle get footerLink => GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _primaryText,
  );

  // ----- Dashboard -----

  /// "Dashboard" page heading
  static TextStyle get pageHeading => GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: _primaryText,
  );

  /// "Parameter Status" / "Latest Insight" / "Recent Notifications" section titles
  static TextStyle get sectionTitle => GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: _primaryText,
  );

  /// "pH Level" / "EC Level" card labels
  static TextStyle get cardLabel => GoogleFonts.workSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: _primaryText,
  );

  /// "Current value: 5.8"
  static TextStyle get cardValue => GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _primaryText,
  );

  /// "Ideal range: 5.5 - 6.5" / "Last updated: 8:00AM"
  static TextStyle get cardMeta => GoogleFonts.workSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _secondaryText,
  );

  /// Regular body text used inside dashboard cards
  static TextStyle get body => GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _primaryText,
  );

  /// Bold body text (e.g. "Humidity: 78%")
  static TextStyle get bodyBold => GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _primaryText,
  );

  /// Alert / warning text (e.g. "pH Drift Warning", "Critical Overheating")
  static TextStyle get alert => GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.alertText,
  );
}
