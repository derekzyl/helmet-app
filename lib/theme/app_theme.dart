import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F131C);
  static const Color surfaceLowest = Color(0xFF0A0E16);
  static const Color surfaceLow = Color(0xFF181C24);
  static const Color surfaceContainer = Color(0xFF1C2028);
  static const Color surfaceHigh = Color(0xFF262A33);
  static const Color surfaceHighest = Color(0xFF31353E);

  static const Color primary = Color(0xFF4EDEA3);
  static const Color primaryContainer = Color(0xFF10B981);
  static const Color onPrimary = Color(0xFF003824);

  static const Color secondary = Color(0xFFADC6FF);
  static const Color secondaryContainer = Color(0xFF0566D9);

  static const Color tertiary = Color(0xFF4CD7F6);
  
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);

  static const Color onSurface = Color(0xFFDFE2EE);
  static const Color onSurfaceVariant = Color(0xFFBBCABF);
  static const Color outline = Color(0xFF86948A);
  static const Color outlineVariant = Color(0xFF3C4A42);
}

class AppLightColors {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF1F5F9);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceHigh = Color(0xFFE2E8F0);
  static const Color surfaceHighest = Color(0xFFCBD5E1);

  static const Color primary = Color(0xFF059669);
  static const Color primaryContainer = Color(0xFF10B981);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF2563EB);
  static const Color secondaryContainer = Color(0xFF3B82F6);

  static const Color tertiary = Color(0xFF0284C7);

  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF475569);
  static const Color outline = Color(0xFF64748B);
  static const Color outlineVariant = Color(0xFFE2E8F0);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        onError: AppColors.onError,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLowest,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLowest,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppLightColors.background,
      colorScheme: const ColorScheme.light(
        surface: AppLightColors.background,
        primary: AppLightColors.primary,
        onPrimary: AppLightColors.onPrimary,
        secondary: AppLightColors.secondary,
        tertiary: AppLightColors.tertiary,
        error: AppLightColors.error,
        onError: AppLightColors.onError,
        onSurface: AppLightColors.onSurface,
        onSurfaceVariant: AppLightColors.onSurfaceVariant,
        outline: AppLightColors.outline,
        outlineVariant: AppLightColors.outlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppLightColors.surfaceLowest,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppLightColors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppLightColors.surfaceLowest,
        selectedItemColor: AppLightColors.primary,
        unselectedItemColor: AppLightColors.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
