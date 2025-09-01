import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Service for geocoding and reverse geocoding using Nominatim (OpenStreetMap)
class GeocodingService {
  static final _dio = Dio();
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Search for locations by query text
  static Future<List<LocationSearchResult>> searchLocations(String query, {LatLng? userLocation}) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '10',
          'countrycodes': 'NL,BE,DE,FR', // Focus on nearby countries for better results
          if (userLocation != null) 'lat': userLocation.latitude.toString(),
          if (userLocation != null) 'lon': userLocation.longitude.toString(),
        },
        options: Options(
          headers: {
            'User-Agent': 'Pathify Mobile App (https://pathify.app)',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => LocationSearchResult.fromJson(item)).toList();
      }
    } catch (e) {
      print('Geocoding search error: $e');
    }

    return [];
  }

  /// Get city name from coordinates
  static Future<String?> getCityFromCoordinates(LatLng point) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/reverse',
        queryParameters: {
          'lat': point.latitude.toString(),
          'lon': point.longitude.toString(),
          'format': 'json',
          'addressdetails': '1',
        },
        options: Options(
          headers: {
            'User-Agent': 'Pathify Mobile App (https://pathify.app)',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final address = data['address'] as Map<String, dynamic>?;
        
        if (address != null) {
          // Try to get city, town, or village
          return address['city'] ?? 
                 address['town'] ?? 
                 address['village'] ?? 
                 address['municipality'] ??
                 address['county'];
        }
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }

    return null;
  }
}

/// Represents a location search result
class LocationSearchResult {
  final String displayName;
  final LatLng location;
  final String? city;
  final String? country;
  final String type;
  final double? importance;

  LocationSearchResult({
    required this.displayName,
    required this.location,
    this.city,
    this.country,
    required this.type,
    this.importance,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    
    return LocationSearchResult(
      displayName: json['display_name'] ?? '',
      location: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
      city: address?['city'] ?? address?['town'] ?? address?['village'],
      country: address?['country'],
      type: json['type'] ?? 'unknown',
      importance: double.tryParse(json['importance']?.toString() ?? ''),
    );
  }

  bool get isCity => ['city', 'town', 'village', 'municipality'].contains(type);
  
  String get shortName {
    if (city != null && country != null) {
      return '$city, $country';
    }
    if (city != null) {
      return city!;
    }
    // Shorten the display name for better UX
    final parts = displayName.split(', ');
    if (parts.length > 3) {
      return '${parts[0]}, ${parts[1]}, ${parts.last}';
    }
    return displayName;
  }
}