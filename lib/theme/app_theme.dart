import 'package:flutter/material.dart';
import 'app_colors.dart';


class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryButton,
        surface: AppColors.background,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryButton,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121712),
      colorScheme: colorScheme.copyWith(
        surface: const Color(0xFF1B211B),
      ),
      cardColor: const Color(0xFF1B211B),
      dividerColor: const Color(0xFF3A443A),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF252D25),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4C584C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8EC66E), width: 1.5),
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF252D25),
        ),
      ),
    );
  }
}
