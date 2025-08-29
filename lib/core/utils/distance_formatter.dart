import '../services/settings_service.dart';

class DistanceFormatter {
  static String formatDistance(double distanceKm) {
    final unitsSystem = SettingsService.getUnitsSystem();
    
    if (unitsSystem == 'Imperial') {
      // Convert to miles
      final distanceMiles = distanceKm * 0.621371;
      
      if (distanceMiles < 0.1) {
        // Show in feet for very short distances
        final distanceFeet = distanceKm * 3280.84;
        return '${distanceFeet.round()}ft';
      } else if (distanceMiles < 1.0) {
        return '${(distanceMiles * 10).round() / 10}mi';
      } else {
        return '${distanceMiles.toStringAsFixed(1)}mi';
      }
    } else {
      // Metric system
      if (distanceKm < 1.0) {
        return '${(distanceKm * 1000).round()}m';
      } else {
        return '${distanceKm.toStringAsFixed(1)}km';
      }
    }
  }
  
  static String formatSpeed(double kmh) {
    final unitsSystem = SettingsService.getUnitsSystem();
    
    if (unitsSystem == 'Imperial') {
      final mph = kmh * 0.621371;
      return '${mph.toStringAsFixed(1)}mph';
    } else {
      return '${kmh.toStringAsFixed(1)}km/h';
    }
  }
}