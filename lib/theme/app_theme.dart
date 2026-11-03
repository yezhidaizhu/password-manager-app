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

abstract final class AppLightColors {
  static const background = Color(0xFFF4F8F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFEAF4EF);
  static const primary = Color(0xFF0B8F68);
  static const primarySoft = Color(0xFF147A5D);
  static const text = Color(0xFF10241D);
  static const textMuted = Color(0xFF64786F);
  static const border = Color(0xFFC5DCD2);
  static const danger = Color(0xFFB3261E);
  static const warning = Color(0xFF9A6400);
  static const info = Color(0xFF1769AA);
}

abstract final class AppGradients {
  static LinearGradient surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10342B), Color(0xFF08251E)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF0F7F3)],
          );
  }

  static LinearGradient surfaceBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0, 0.48, 1],
            colors: [Color(0xAA20DFA1), Color(0x66245246), Color(0x5571D9A8)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0, 0.52, 1],
            colors: [Color(0x9920DFA1), Color(0xAAC5DCD2), Color(0x5571D9A8)],
          );
  }
}

extension AppThemeContext on BuildContext {
  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get appSurface => Theme.of(this).colorScheme.surface;
  Color get appText => Theme.of(this).colorScheme.onSurface;
  Color get appTextMuted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get appBorder => Theme.of(this).colorScheme.outline;
  Color get appDanger => Theme.of(this).colorScheme.error;
  Color get appWarning => Theme.of(this).brightness == Brightness.dark
      ? AppColors.warning
      : AppLightColors.warning;
  Color get appInfo => Theme.of(this).brightness == Brightness.dark
      ? AppColors.info
      : AppLightColors.info;
}

abstract final class AppTheme {
  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Color(0xFF002E21),
      secondary: AppColors.primarySoft,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textMuted,
      error: AppColors.danger,
      outline: AppColors.border,
      outlineVariant: Color(0xFF173C32),
    ),
    background: AppColors.background,
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: AppLightColors.primary,
      onPrimary: Colors.white,
      secondary: AppLightColors.primarySoft,
      surface: AppLightColors.surface,
      onSurface: AppLightColors.text,
      onSurfaceVariant: AppLightColors.textMuted,
      error: AppLightColors.danger,
      outline: AppLightColors.border,
      outlineVariant: Color(0xFFDCE9E3),
    ),
    background: AppLightColors.background,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamilyFallback: const [
        'PingFang SC',
        'Noto Sans CJK SC',
        'sans-serif',
      ],
      textTheme: TextTheme(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: scheme.onSurfaceVariant,
        ),
      ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      dividerColor: scheme.outlineVariant,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.6,
        space: 1,
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, 44)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, 44)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, 44)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 14),
        minVerticalPadding: 8,
        visualDensity: VisualDensity(vertical: -1),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(44, 44)),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      splashColor: scheme.primary.withValues(alpha: 0.14),
      highlightColor: scheme.primary.withValues(alpha: 0.08),
    );
  }
}
