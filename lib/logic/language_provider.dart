import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLocale();
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('language_code');
    if (langCode != null) {
      _locale = Locale(langCode);
      notifyListeners();
    }
  }

  void setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }
}
