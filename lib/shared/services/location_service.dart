import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _lastLatKey = 'last_latitude';
  static const String _lastLngKey = 'last_longitude';
  static const LatLng _defaultLocation = LatLng(37.7749, -122.4194); // San Francisco fallback
  
  static Timer? _locationTimer;
  static LatLng? _cachedLocation;
  static bool _isLocationServiceActive = false;

  /// Start periodic location updates every 5 seconds
  static void startLocationTracking() async {
    if (_isLocationServiceActive) return;
    
    _isLocationServiceActive = true;
    
    // Get initial location
    await _updateCachedLocation();
    
    // Set up timer for periodic updates
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _updateCachedLocation();
    });
  }
  
  /// Stop periodic location updates
  static void stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isLocationServiceActive = false;
  }
  
  /// Get cached location (much faster than getCurrentLocation)
  static LatLng? getCachedLocation() {
    return _cachedLocation;
  }
  
  /// Update the cached location in background
  static Future<void> _updateCachedLocation() async {
    try {
      final location = await _getCurrentLocationInternal();
      if (location != null) {
        _cachedLocation = location;
      }
    } catch (e) {
      debugPrint('Background location update failed: $e');
    }
  }

  /// Get current user location with permission handling
  static Future<LatLng?> getCurrentLocation() async {
    // If we have a recent cached location, return it immediately
    if (_cachedLocation != null) {
      return _cachedLocation;
    }
    
    // Otherwise get fresh location
    return await _getCurrentLocationInternal();
  }
  
  /// Internal method to get current location
  static Future<LatLng?> _getCurrentLocationInternal() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Open app settings if permanently denied
        await openAppSettings();
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final location = LatLng(position.latitude, position.longitude);
      
      // Save this location for future use
      await _saveLastLocation(location);
      
      return location;
    } catch (e) {
      // Log error (in production, use proper logging like logger package)
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Get the last known location or default location
  static Future<LatLng> getLastKnownLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_lastLatKey);
      final lng = prefs.getDouble(_lastLngKey);

      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    } catch (e) {
      debugPrint('Error getting last known location: $e');
    }
    
    return _defaultLocation;
  }

  /// Save location for persistence
  static Future<void> _saveLastLocation(LatLng location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_lastLatKey, location.latitude);
      await prefs.setDouble(_lastLngKey, location.longitude);
    } catch (e) {
      debugPrint('Error saving location: $e');
    }
  }

  /// Get initial location - tries current first, falls back to last known
  static Future<LatLng> getInitialLocation() async {
    // First try to get current location (with timeout)
    final currentLocation = await getCurrentLocation();
    if (currentLocation != null) {
      return currentLocation;
    }

    // Fall back to last known location
    return await getLastKnownLocation();
  }

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Request location permissions
  static Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get location stream for real-time updates
  static Stream<LatLng> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).map((position) {
      final location = LatLng(position.latitude, position.longitude);
      // Save location in background
      _saveLastLocation(location);
      return location;
    });
  }

  /// Update last known location manually (useful when user moves map)
  static Future<void> updateLastLocation(LatLng location) async {
    await _saveLastLocation(location);
  }
}