import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _preferenceKey = 'keynest.theme-mode';

  ThemeMode mode = ThemeMode.system;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    mode = switch (preferences.getString(_preferenceKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    if (mode == value) return;
    mode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, value.name);
  }

  String get label => switch (mode) {
    ThemeMode.system => '跟随系统',
    ThemeMode.light => '浅色主题',
    ThemeMode.dark => '深色主题',
  };
}
