import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF021A15);
  static const surface = Color(0xFF09261F);
  static const surfaceHigh = Color(0xFF0E342A);
  static const primary = Color(0xFF20DFA1);
  static const primarySoft = Color(0xFF71D9A8);
  static const text = Color(0xFFF1FFF8);
  static const textMuted = Color(0xFF95AFA5);
  static const border = Color(0xFF245246);
  static const danger = Color(0xFFFF6B70);
  static const warning = Color(0xFFFFCE55);
  static const info = Color(0xFF49A8FF);
}

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Color(0xFF002E21),
      secondary: AppColors.primarySoft,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamilyFallback: const [
        'PingFang SC',
        'Noto Sans CJK SC',
        'sans-serif',
      ],
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: AppColors.textMuted,
        ),
      ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      dividerColor: AppColors.border,
      iconTheme: const IconThemeData(color: AppColors.text),
      splashColor: AppColors.primary.withValues(alpha: 0.14),
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
    );
  }
}
