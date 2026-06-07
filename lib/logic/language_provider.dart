import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_session.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLocale();
  }

  void _loadLocale() async {
    // 1. Try Loading from UserSession (User Specific)
    final String? userLang = await UserSession.getUserLanguage();
    if (userLang != null) {
      _locale = Locale(userLang);
      notifyListeners();
      return;
    }

    // 2. Fallback to Global Prefs (if any legacy or guest default)
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('language_code');
    if (langCode != null) {
      _locale = Locale(langCode);
      notifyListeners();
    }
  }

  void setLocale(Locale locale) async {
    _locale = locale;
    // 1. Save to UserSession (User Specific)
    await UserSession.setUserLanguage(locale.languageCode);

    // 2. Save Global fallback (Optional, but good for guest experience consistency)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);

    // 3. Changing the app language is a strong signal that overrides any
    // sticky AI Sage chat override — the user wants the whole app, AI
    // included, in the new language. Wipe the persisted override so the
    // next chat falls back to the new app language.
    await UserSession.setChatLanguage(null);

    notifyListeners();
  }
}
