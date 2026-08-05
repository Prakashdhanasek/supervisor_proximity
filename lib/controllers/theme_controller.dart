import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeController() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode');
    if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (mode == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_themeMode == ThemeMode.system) {
      await prefs.remove('themeMode');
    } else {
      await prefs.setString(
        'themeMode',
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    }
  }
}
