import 'package:shared_preferences/shared_preferences.dart';
import '../constants/activity_types.dart';

class SettingsService {
  static const String _waypointsVisibleKey = 'waypoints_visible_default';
  static const String _unitsKey = 'units_system';
  static const String _defaultActivityKey = 'default_activity';
  static const String _mapLayerKey = 'map_layer';
  static const String _walkingSpeedKey = 'walking_speed';
  static const String _runningSpeedKey = 'running_speed';
  static const String _cyclingSpeedKey = 'cycling_speed';
  static const String _hikingSpeedKey = 'hiking_speed';
  static const String _runningSpeedUnitKey = 'running_speed_unit';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Language settings removed (Dutch-only app)

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

  // Map layer settings
  static String getMapLayer() {
    return _prefs?.getString(_mapLayerKey) ?? 'OpenStreetMap';
  }

  static Future<void> setMapLayer(String layer) async {
    await _prefs?.setString(_mapLayerKey, layer);
  }

  // Activity speed settings
  static double getActivitySpeed(ActivityType activity) {
    switch (activity) {
      case ActivityType.walking:
        return _prefs?.getDouble(_walkingSpeedKey) ?? 5.0; // 5 km/h default
      case ActivityType.running:
        return _prefs?.getDouble(_runningSpeedKey) ?? 10.0; // 10 km/h default
      case ActivityType.cycling:
        return _prefs?.getDouble(_cyclingSpeedKey) ?? 20.0; // 20 km/h default
      case ActivityType.hiking:
        return _prefs?.getDouble(_hikingSpeedKey) ?? 4.0; // 4 km/h default
    }
  }

  static Future<void> setActivitySpeed(ActivityType activity, double speed) async {
    switch (activity) {
      case ActivityType.walking:
        await _prefs?.setDouble(_walkingSpeedKey, speed);
        break;
      case ActivityType.running:
        await _prefs?.setDouble(_runningSpeedKey, speed);
        break;
      case ActivityType.cycling:
        await _prefs?.setDouble(_cyclingSpeedKey, speed);
        break;
      case ActivityType.hiking:
        await _prefs?.setDouble(_hikingSpeedKey, speed);
        break;
    }
  }

  // Running speed unit preference (km/h or min/km)
  static String getRunningSpeedUnit() {
    return _prefs?.getString(_runningSpeedUnitKey) ?? 'km/h';
  }

  static Future<void> setRunningSpeedUnit(String unit) async {
    await _prefs?.setString(_runningSpeedUnitKey, unit);
  }

  // Clear all settings
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
