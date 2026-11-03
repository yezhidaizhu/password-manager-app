import 'package:app_password_manager/controllers/theme_controller.dart';
import 'package:app_password_manager/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists the selected theme mode', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();
    await controller.initialize();
    expect(controller.mode, ThemeMode.system);

    await controller.setMode(ThemeMode.light);
    final restored = ThemeController();
    await restored.initialize();

    expect(restored.mode, ThemeMode.light);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });
}
