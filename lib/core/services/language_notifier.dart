import 'package:flutter/foundation.dart';
import 'settings_service.dart';

class LanguageNotifier extends ChangeNotifier {
  static final LanguageNotifier _instance = LanguageNotifier._internal();
  factory LanguageNotifier() => _instance;
  LanguageNotifier._internal();

  String _currentLanguage = 'Nederlands';

  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    await SettingsService.init();
    _currentLanguage = SettingsService.getLanguage();
  }

  Future<void> setLanguage(String language) async {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      await SettingsService.setLanguage(language);
      notifyListeners(); // This will trigger rebuilds throughout the app
    }
  }
}