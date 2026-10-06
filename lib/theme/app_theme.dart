import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextStyle _headingStyle(TextStyle? base) {
    return GoogleFonts.manrope(
      textStyle: base,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
  }

  static TextTheme _textTheme({required bool dark}) {
    final base = GoogleFonts.workSansTextTheme(
      dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return base.copyWith(
      displayLarge: _headingStyle(base.displayLarge),
      displayMedium: _headingStyle(base.displayMedium),
      displaySmall: _headingStyle(base.displaySmall),
      headlineLarge: _headingStyle(base.headlineLarge),
      headlineMedium: _headingStyle(base.headlineMedium),
      headlineSmall: _headingStyle(base.headlineSmall),
      titleLarge: _headingStyle(base.titleLarge),
      titleMedium: _headingStyle(base.titleMedium),
      titleSmall: _headingStyle(base.titleSmall),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryButton,
        brightness: Brightness.light,
        surface: AppColors.cardBackground,
      ),
      textTheme: _textTheme(dark: false),
      cardColor: AppColors.cardBackground,
      dividerColor: AppColors.cardBorder,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryButton,
        brightness: Brightness.dark,
        surface: AppColors.cardBackground,
      ),
      textTheme: _textTheme(dark: true),
      cardColor: AppColors.cardBackground,
      dividerColor: AppColors.cardBorder,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
      ),
    );
  }
}