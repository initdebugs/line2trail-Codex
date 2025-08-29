import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static final _dio = Dio();
  
  /// Get city name from coordinates using reverse geocoding
  static Future<String?> getCityFromCoordinates(LatLng coordinates) async {
    try {
      final response = await _dio.get(
        '$_nominatimBaseUrl/reverse',
        queryParameters: {
          'format': 'json',
          'lat': coordinates.latitude.toString(),
          'lon': coordinates.longitude.toString(),
          'zoom': '10',
          'addressdetails': '1',
        },
        options: Options(
          headers: {
            'User-Agent': 'Pathify-App/1.0',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final address = data['address'] as Map<String, dynamic>?;
        
        if (address != null) {
          // Try to get city, town, village, or suburb
          final city = address['city'] ?? 
                      address['town'] ?? 
                      address['village'] ?? 
                      address['suburb'] ?? 
                      address['municipality'];
                      
          final state = address['state'];
          final country = address['country'];
          
          // Format location string
          if (city != null) {
            if (state != null && country != null) {
              return '$city, $state, $country';
            } else if (state != null) {
              return '$city, $state';
            } else if (country != null) {
              return '$city, $country';
            } else {
              return city;
            }
          }
        }
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    
    return null;
  }
  
  /// Get location from the center of a route
  static Future<String?> getLocationFromRoute(List<LatLng> routePoints) async {
    if (routePoints.isEmpty) return null;
    
    // Calculate the center point of the route
    double totalLat = 0;
    double totalLng = 0;
    
    for (final point in routePoints) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }
    
    final centerLat = totalLat / routePoints.length;
    final centerLng = totalLng / routePoints.length;
    
    return getCityFromCoordinates(LatLng(centerLat, centerLng));
  }
}