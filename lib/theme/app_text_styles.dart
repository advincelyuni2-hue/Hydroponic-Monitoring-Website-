import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Titles use Manrope (Bold). Everything else uses Work Sans.
class AppTextStyles {
  AppTextStyles._();

  /// "Login your account"
  static TextStyle title = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// "Your email" / "Password" labels above each field
  static TextStyle label = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Text the user types inside input fields
  static TextStyle input = GoogleFonts.workSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// "Remember me" / "Forgot Password?"
  static TextStyle bodySmall = GoogleFonts.workSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Text on the green "Log In" button
  static TextStyle button = GoogleFonts.workSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryButtonText,
  );

  /// Text on the tan "Log In with Google" button
  static TextStyle buttonDark = GoogleFonts.workSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.googleButtonText,
  );

  /// "Don't have an account?"
  static TextStyle footer = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// "Sign up" (the clickable part)
  static TextStyle footerLink = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ----- Dashboard -----

  /// "Dashboard" page heading
  static TextStyle pageHeading = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// "Parameter Status" / "Latest Insight" / "Recent Notifications" section titles
  static TextStyle sectionTitle = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// "pH Level" / "EC Level" card labels
  static TextStyle cardLabel = GoogleFonts.workSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// "Current value: 5.8"
  static TextStyle cardValue = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// "Ideal range: 5.5 - 6.5" / "Last updated: 8:00AM"
  static TextStyle cardMeta = GoogleFonts.workSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Regular body text used inside dashboard cards
  static TextStyle body = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Bold body text (e.g. "Humidity: 78%")
  static TextStyle bodyBold = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Alert / warning text (e.g. "pH Drift Warning", "Critical Overheating")
  static TextStyle alert = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.alertText,
  );
}
