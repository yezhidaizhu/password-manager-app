import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF101312);
  static const surface = Color(0xFF181C1A);
  static const surfaceHigh = Color(0xFF222724);
  static const primary = Color(0xFF059669);
  static const primarySoft = Color(0xFF71D9A8);
  static const text = Color(0xFFF2F5F3);
  static const textMuted = Color(0xFFA4AAA7);
  static const border = Color(0xFF343B37);
  static const danger = Color(0xFFFF6B70);
  static const warning = Color(0xFFFFCE55);
  static const info = Color(0xFF49A8FF);
}

abstract final class AppLightColors {
  static const background = Color(0xFFF6F7F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFEFF1F2);
  static const primary = Color(0xFF059669);
  static const primarySoft = Color(0xFF147A5D);
  static const text = Color(0xFF17191C);
  static const textMuted = Color(0xFF686D73);
  static const border = Color(0xFFD9DDE1);
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
            colors: [Color(0xFF202421), Color(0xFF171A18)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF4F5F6)],
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
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF183D30),
      onPrimaryContainer: Color(0xFFA4F5D2),
      secondary: AppColors.primarySoft,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textMuted,
      error: AppColors.danger,
      outline: AppColors.border,
      outlineVariant: Color(0xFF292F2C),
    ),
    background: AppColors.background,
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: AppLightColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE2F3EB),
      onPrimaryContainer: Color(0xFF126347),
      secondary: AppLightColors.primarySoft,
      surface: AppLightColors.surface,
      onSurface: AppLightColors.text,
      onSurfaceVariant: AppLightColors.textMuted,
      error: AppLightColors.danger,
      outline: AppLightColors.border,
      outlineVariant: Color(0xFFE8EAED),
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
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        showCheckmark: false,
        side: BorderSide(color: scheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: TextStyle(
          fontSize: 13,
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurface,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 14),
        dense: true,
        minLeadingWidth: 36,
        horizontalTitleGap: 10,
        minVerticalPadding: 4,
        visualDensity: VisualDensity(vertical: -2),
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
