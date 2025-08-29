import 'package:shared_preferences/shared_preferences.dart';
import '../constants/activity_types.dart';

class SettingsService {
  static const String _languageKey = 'app_language';
  static const String _waypointsVisibleKey = 'waypoints_visible_default';
  static const String _unitsKey = 'units_system';
  static const String _defaultActivityKey = 'default_activity';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Language settings
  static String getLanguage() {
    return _prefs?.getString(_languageKey) ?? 'Nederlands';
  }

  static Future<void> setLanguage(String language) async {
    await _prefs?.setString(_languageKey, language);
  }

  // Waypoints visibility settings
  static bool getWaypointsVisible() {
    return _prefs?.getBool(_waypointsVisibleKey) ?? true;
  }

  static Future<void> setWaypointsVisible(bool visible) async {
    await _prefs?.setBool(_waypointsVisibleKey, visible);
  }

  // Units system settings  
  static String getUnitsSystem() {
    return _prefs?.getString(_unitsKey) ?? 'Metric';
  }

  static Future<void> setUnitsSystem(String units) async {
    await _prefs?.setString(_unitsKey, units);
  }

  // Default activity type settings
  static ActivityType getDefaultActivity() {
    final activityName = _prefs?.getString(_defaultActivityKey) ?? 'walking';
    return ActivityType.values.firstWhere(
      (type) => type.name == activityName,
      orElse: () => ActivityType.walking,
    );
  }

  static Future<void> setDefaultActivity(ActivityType activity) async {
    await _prefs?.setString(_defaultActivityKey, activity.name);
  }

  // Clear all settings
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}