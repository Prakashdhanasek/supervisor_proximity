import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleController() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!['en', 'ar', 'hi'].contains(newLocale.languageCode)) return;
    if (_locale.languageCode == newLocale.languageCode) return;

    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
    notifyListeners();
  }
}
