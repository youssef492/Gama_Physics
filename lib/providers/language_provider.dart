import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('ar', 'EG');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'ar';
      _locale = langCode == 'ar'
          ? const Locale('ar', 'EG')
          : const Locale('en', 'US');
    } catch (_) {
      _locale = const Locale('ar', 'EG'); // fallback
    }
    notifyListeners();
  }

  Future<void> toggle() async {
    if (isArabic) {
      await setEnglish();
    } else {
      await setArabic();
    }
  }

  Future<void> setArabic() async {
    _locale = const Locale('ar', 'EG');
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', 'ar');
    } catch (_) {}
  }

  Future<void> setEnglish() async {
    _locale = const Locale('en', 'US');
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', 'en');
    } catch (_) {}
  }
}
