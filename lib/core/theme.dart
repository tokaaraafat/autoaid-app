import 'package:flutter/material.dart';

/// Dark "workshop" look: charcoal surfaces, crimson accent, teal secondary.
class AppColors {
  static const background = Color(0xFF0D1217);
  static const surface = Color(0xFF151C23);
  static const surfaceHigh = Color(0xFF1F2A33);
  static const crimson = Color(0xFFE5254B);
  static const crimsonDark = Color(0xFF4A1523);
  static const teal = Color(0xFF3FB5C6);
}

class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.crimson,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.crimson,
      onPrimary: Colors.white,
      primaryContainer: AppColors.crimsonDark,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.teal,
      surface: AppColors.surface,
      onSurface: Colors.white,
      surfaceContainerLow: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceHigh,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.crimsonDark,
      ),
    );
  }
}
