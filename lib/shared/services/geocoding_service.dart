import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('Geocoding error: $e');
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

  /// Search for places using forward geocoding
  static Future<List<SearchResult>> searchPlaces(String query, {
    LatLng? biasLocation,
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final queryParams = {
        'format': 'json',
        'q': query,
        'limit': limit.toString(),
        'addressdetails': '1',
        'extratags': '1',
      };

      // Add bias towards a location if provided (e.g., user's current location)
      if (biasLocation != null) {
        queryParams['viewbox'] = '${biasLocation.longitude - 0.1},${biasLocation.latitude + 0.1},'
                                 '${biasLocation.longitude + 0.1},${biasLocation.latitude - 0.1}';
        queryParams['bounded'] = '0'; // Don't restrict to viewbox, just bias
      }

      final response = await _dio.get(
        '$_nominatimBaseUrl/search',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'User-Agent': 'Pathify-App/1.0',
          },
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data;
        return results.map((result) => SearchResult.fromJson(result)).toList();
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }

    return [];
  }
}

/// Represents a search result from geocoding
class SearchResult {
  final String displayName;
  final String type;
  final LatLng location;
  final Map<String, dynamic> address;
  final double importance;

  SearchResult({
    required this.displayName,
    required this.type,
    required this.location,
    required this.address,
    required this.importance,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      type: json['type'] ?? 'unknown',
      location: LatLng(
        double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
        double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      ),
      address: json['address'] ?? {},
      importance: double.tryParse(json['importance']?.toString() ?? '0') ?? 0.0,
    );
  }

  /// Get a short, user-friendly title for this result
  String get title {
    final address = this.address;
    final city = address['city'] ?? address['town'] ?? address['village'];
    final road = address['road'];
    final suburb = address['suburb'];
    
    if (road != null && city != null) {
      return '$road, $city';
    } else if (suburb != null && city != null) {
      return '$suburb, $city';
    } else if (city != null) {
      return city;
    } else {
      return displayName.split(',').take(2).join(', ');
    }
  }

  /// Get a subtitle with additional location context
  String get subtitle {
    final parts = displayName.split(', ');
    if (parts.length > 2) {
      return parts.skip(2).take(2).join(', ');
    }
    return displayName;
  }

  /// Determine if this is a city-level result
  bool get isCity {
    return ['city', 'town', 'village', 'municipality'].contains(type);
  }

  /// Determine if this is a street-level result
  bool get isStreet {
    return ['residential', 'highway', 'primary', 'secondary', 'tertiary', 'unclassified'].contains(type) ||
           address.containsKey('road');
  }
}