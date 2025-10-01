import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../core/constants/activity_types.dart';
import 'routing_service.dart';

/// Fast roundtrip generation service that prioritizes speed over perfect routing
class FastRoundtripService {
  static final Dio _dio = Dio();
  /// Generate a realistic roundtrip route quickly (target: <10 seconds)
  static Future<FastRoundtripRoute?> generateFastRoundtrip({
    required LatLng startPoint,
    required double targetDistanceKm,
    required ActivityType activityType,
    required RoundtripStrategy strategy,
  }) async {
    debugPrint('⚡ Generating FAST roundtrip: ${targetDistanceKm}km ${activityType.name} from ${startPoint.latitude.toStringAsFixed(4)},${startPoint.longitude.toStringAsFixed(4)}');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // Step 1: Generate strategic waypoints (no API calls - pure geometry)
      final waypoints = _generateGeometricWaypoints(
        startPoint: startPoint,
        targetDistanceKm: targetDistanceKm,
        strategy: strategy,
      );
      
      debugPrint('📍 Generated ${waypoints.length} waypoints in ${stopwatch.elapsedMilliseconds}ms');
      
      // Step 2: Try to connect waypoints with single routing call
      List<LatLng> routedPath;
      
      // First attempt: Use fast routing services (OSRM, GraphHopper) which are faster than Overpass
      try {
        routedPath = await _routeWithFastServices(waypoints, activityType);
        debugPrint('🚀 Fast routing completed in ${stopwatch.elapsedMilliseconds}ms');
      } catch (e) {
        debugPrint('⚠️ Fast routing failed: $e, using geometric interpolation');
        // Fallback: Create a smooth route using geometric interpolation
        routedPath = _createGeometricRoute(waypoints, targetDistanceKm);
        debugPrint('📐 Geometric route created in ${stopwatch.elapsedMilliseconds}ms');
      }
      
      final actualDistanceKm = _calculateRouteDistance(routedPath) / 1000;
      final estimatedTime = RoutingService.getEstimatedTime(routedPath, activityType);
      
      stopwatch.stop();
      debugPrint('✅ Fast roundtrip completed in ${stopwatch.elapsedMilliseconds}ms: ${actualDistanceKm.toStringAsFixed(1)}km');
      
      return FastRoundtripRoute(
        waypoints: waypoints,
        routedPath: routedPath,
        startPoint: startPoint,
        actualDistanceKm: actualDistanceKm,
        targetDistanceKm: targetDistanceKm,
        estimatedTime: estimatedTime,
        activityType: activityType,
        strategy: strategy,
        generationTimeMs: stopwatch.elapsedMilliseconds,
      );
      
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Fast roundtrip generation failed in ${stopwatch.elapsedMilliseconds}ms: $e');
      return null;
    }
  }

  /// Generate waypoints using pure geometry (no API calls)
  static List<LatLng> _generateGeometricWaypoints({
    required LatLng startPoint,
    required double targetDistanceKm,
    required RoundtripStrategy strategy,
  }) {
    final waypoints = <LatLng>[startPoint];

    // Calculate optimal number of waypoints (fewer = faster routing)
    final numWaypoints = _getOptimalWaypointCount(targetDistanceKm, strategy);

    // IMPROVED: Account for road snapping overhead (roads aren't straight lines)
    // Routed distance is typically 1.3-1.5x the straight-line distance
    final roadSnapFactor = 1.4;
    final approximateRadius = (targetDistanceKm * 1000) / (2 * pi * roadSnapFactor);
    final angleStep = (2 * pi) / numWaypoints;

    debugPrint('🎯 Creating $numWaypoints waypoints with ~${(approximateRadius / 1000).toStringAsFixed(1)}km radius (adjusted for road snapping)');

    // Generate waypoints in strategic pattern
    for (int i = 0; i < numWaypoints - 1; i++) {
      final baseAngle = i * angleStep;

      // Add variation based on strategy
      final variation = _getAngleVariation(strategy);
      final actualAngle = baseAngle + ((Random().nextDouble() - 0.5) * variation * angleStep);

      // Create interesting radius variation
      final radiusVariation = _getRadiusVariation(strategy, i, numWaypoints);
      final effectiveRadius = approximateRadius * radiusVariation;

      // Calculate waypoint position
      final waypoint = _calculatePointAtDistance(startPoint, actualAngle, effectiveRadius);
      waypoints.add(waypoint);
    }

    // Close the loop
    waypoints.add(startPoint);

    return waypoints;
  }

  /// Get optimal waypoint count for speed vs quality balance
  static int _getOptimalWaypointCount(double targetDistanceKm, RoundtripStrategy strategy) {
    // Fewer waypoints = faster routing, but less realistic shape
    final baseCount = (targetDistanceKm / 2.5).round().clamp(4, 8); // Max 8 for speed
    
    switch (strategy) {
      case RoundtripStrategy.direct:
        return (baseCount * 0.7).round().clamp(3, 5); // Fewer waypoints
      case RoundtripStrategy.exploration:
        return (baseCount * 1.2).round().clamp(5, 8); // More waypoints
      default:
        return baseCount;
    }
  }

  /// Route through waypoints using segment-by-segment routing for reliability
  static Future<List<LatLng>> _routeWithFastServices(List<LatLng> waypoints, ActivityType activityType) async {
    debugPrint('🎯 Routing ${waypoints.length} waypoints segment-by-segment for ${activityType.name}');

    if (waypoints.length < 2) return waypoints;

    final completePath = <LatLng>[];
    int successfulSegments = 0;
    int failedSegments = 0;

    // Route each segment individually for better reliability
    for (int i = 0; i < waypoints.length - 1; i++) {
      debugPrint('🗺️ Routing segment ${i + 1}/${waypoints.length - 1}');

      try {
        final segmentPath = await RoutingService.snapToPath(
          points: [waypoints[i], waypoints[i + 1]],
          activityType: activityType,
        );

        if (segmentPath.isNotEmpty) {
          // Add points, avoiding duplicates at segment boundaries
          final startIdx = i == 0 ? 0 : 1;
          for (int j = startIdx; j < segmentPath.length; j++) {
            completePath.add(segmentPath[j]);
          }
          successfulSegments++;
        } else {
          // If routing fails, try mixed mode for this segment
          debugPrint('⚠️ Primary routing failed for segment ${i + 1}, trying mixed mode');
          final mixedSegment = await RoutingService.snapToPathMixed(
            points: [waypoints[i], waypoints[i + 1]],
            primaryActivityType: activityType,
            allowMixedModes: true,
          );

          if (mixedSegment.isNotEmpty) {
            final startIdx = i == 0 ? 0 : 1;
            for (int j = startIdx; j < mixedSegment.length; j++) {
              completePath.add(mixedSegment[j]);
            }
            successfulSegments++;
          } else {
            // Last resort: use direct line
            debugPrint('❌ All routing failed for segment ${i + 1}, using direct line');
            if (i == 0) completePath.add(waypoints[i]);
            completePath.add(waypoints[i + 1]);
            failedSegments++;
          }
        }
      } catch (e) {
        debugPrint('❌ Routing error for segment ${i + 1}: $e');
        // Fallback to direct line
        if (i == 0) completePath.add(waypoints[i]);
        completePath.add(waypoints[i + 1]);
        failedSegments++;
      }
    }

    debugPrint('✅ Routing complete: $successfulSegments successful, $failedSegments failed segments');

    if (failedSegments > successfulSegments) {
      throw Exception('Too many segments failed to route properly (${failedSegments}/${waypoints.length - 1})');
    }

    return completePath;
  }

  /// Get routing strategies in priority order for the activity type
  static List<Map<String, dynamic>> _getRoutingStrategies(ActivityType activityType) {
    // Use the same routing as normal drawing mode (RoutingService.snapToPath)
    // which prioritizes Overpass API for proper infrastructure
    return [
      {
        'name': 'Infrastructure-Specific (like normal drawing)',
        'method': (List<LatLng> waypoints, ActivityType type) => 
            RoutingService.snapToPath(points: waypoints, activityType: type),
      },
      {
        'name': 'Mixed Routing Fallback',
        'method': (List<LatLng> waypoints, ActivityType type) => 
            RoutingService.snapToPathMixed(
              points: waypoints, 
              primaryActivityType: type, 
              allowMixedModes: true
            ),
      },
      // Keep the specific methods as additional fallbacks
      ..._getSpecificMethodsFallback(activityType),
    ];
  }

  /// Get activity-specific fallback methods
  static List<Map<String, dynamic>> _getSpecificMethodsFallback(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.walking:
      case ActivityType.running:
        return [
          {
            'name': 'GraphHopper Foot',
            'method': _routeWithGraphHopperFoot,
          },
          {
            'name': 'OSRM Walking',
            'method': _routeWithOSRMWalking,
          },
        ];
        
      case ActivityType.cycling:
        return [
          {
            'name': 'GraphHopper Bike',
            'method': _routeWithGraphHopperBike,
          },
          {
            'name': 'OSRM Cycling',
            'method': _routeWithOSRMCycling,
          },
        ];
        
      case ActivityType.hiking:
        return [
          {
            'name': 'GraphHopper Hike',
            'method': _routeWithGraphHopperHike,
          },
          {
            'name': 'OSRM Walking (trail fallback)',
            'method': _routeWithOSRMWalking,
          },
        ];
    }
  }

  /// Route with pedestrian infrastructure priority (footways, sidewalks, pedestrian areas)
  static Future<List<LatLng>> _routeWithPedestrianPriority(List<LatLng> waypoints, ActivityType activityType) async {
    // Use the mixed routing which prioritizes pedestrian infrastructure (like normal drawing)
    return await RoutingService.snapToPathMixed(
      points: waypoints,
      primaryActivityType: activityType,
      allowMixedModes: true,
    );
  }

  /// Route with cycling infrastructure priority (cycleways, bike lanes, bike-friendly roads)
  static Future<List<LatLng>> _routeWithCyclingPriority(List<LatLng> waypoints, ActivityType activityType) async {
    // Use the mixed routing which prioritizes cycling infrastructure (like normal drawing)
    return await RoutingService.snapToPathMixed(
      points: waypoints,
      primaryActivityType: activityType,
      allowMixedModes: true,
    );
  }

  /// Route with hiking priority (trails, paths, forest roads)
  static Future<List<LatLng>> _routeWithHikingPriority(List<LatLng> waypoints, ActivityType activityType) async {
    // Use the mixed routing which prioritizes hiking trails (like normal drawing)
    return await RoutingService.snapToPathMixed(
      points: waypoints,
      primaryActivityType: activityType,
      allowMixedModes: true,
    );
  }

  /// Route using GraphHopper with foot profile
  static Future<List<LatLng>> _routeWithGraphHopperFoot(List<LatLng> waypoints, ActivityType activityType) async {
    // Convert waypoints to GraphHopper coordinate format
    final pointParams = waypoints.map((p) => 'point=${p.latitude},${p.longitude}').join('&');
    
    // Use foot profile with pedestrian-friendly settings
    const vehicle = 'foot';
    const additional = '&weighting=shortest&avoid=motorway&block_area=false';
    
    final url = 'https://graphhopper.com/api/1/route?$pointParams&vehicle=$vehicle$additional&debug=false&calc_points=true&type=json';
    
    debugPrint('🚶 GraphHopper Foot URL: $url');
    
    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Accept': 'application/json'},
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    if (response.statusCode == 200) {
      return _parseGraphHopperResponse(response.data);
    } else {
      throw Exception('GraphHopper Foot error: ${response.statusCode}');
    }
  }

  /// Route using GraphHopper with bike profile
  static Future<List<LatLng>> _routeWithGraphHopperBike(List<LatLng> waypoints, ActivityType activityType) async {
    final pointParams = waypoints.map((p) => 'point=${p.latitude},${p.longitude}').join('&');
    
    // Use bike profile with cycling-friendly settings
    const vehicle = 'bike';
    const additional = '&weighting=fastest&avoid=motorway&bike.speed_factor=1.2&bike.speed_bits=4';
    
    final url = 'https://graphhopper.com/api/1/route?$pointParams&vehicle=$vehicle$additional&debug=false&calc_points=true&type=json';
    
    debugPrint('🚴 GraphHopper Bike URL: $url');
    
    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Accept': 'application/json'},
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    if (response.statusCode == 200) {
      return _parseGraphHopperResponse(response.data);
    } else {
      throw Exception('GraphHopper Bike error: ${response.statusCode}');
    }
  }

  /// Route using GraphHopper with hike profile  
  static Future<List<LatLng>> _routeWithGraphHopperHike(List<LatLng> waypoints, ActivityType activityType) async {
    final pointParams = waypoints.map((p) => 'point=${p.latitude},${p.longitude}').join('&');
    
    // Use hike profile for trails and natural paths
    const vehicle = 'hike';
    const additional = '&weighting=shortest&avoid=motorway';
    
    final url = 'https://graphhopper.com/api/1/route?$pointParams&vehicle=$vehicle$additional&debug=false&calc_points=true&type=json';
    
    debugPrint('🥾 GraphHopper Hike URL: $url');
    
    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Accept': 'application/json'},
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    if (response.statusCode == 200) {
      return _parseGraphHopperResponse(response.data);
    } else {
      throw Exception('GraphHopper Hike error: ${response.statusCode}');
    }
  }

  /// Route using OSRM with walking profile
  static Future<List<LatLng>> _routeWithOSRMWalking(List<LatLng> waypoints, ActivityType activityType) async {
    final coordString = waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
    
    final options = [
      'overview=full',
      'geometries=geojson',
      'steps=true',
      'annotations=true',
    ];
    
    final url = 'https://router.project-osrm.org/route/v1/walking/$coordString?${options.join('&')}';
    
    debugPrint('🚶 OSRM Walking URL: $url');
    
    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Accept': 'application/json'},
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    if (response.statusCode == 200) {
      return _parseOsrmResponse(response.data);
    } else {
      throw Exception('OSRM Walking error: ${response.statusCode}');
    }
  }

  /// Route using OSRM with cycling profile
  static Future<List<LatLng>> _routeWithOSRMCycling(List<LatLng> waypoints, ActivityType activityType) async {
    final coordString = waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
    
    final options = [
      'overview=full',
      'geometries=geojson',
      'steps=true',
      'annotations=true',
    ];
    
    final url = 'https://router.project-osrm.org/route/v1/cycling/$coordString?${options.join('&')}';
    
    debugPrint('🚴 OSRM Cycling URL: $url');
    
    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Accept': 'application/json'},
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    if (response.statusCode == 200) {
      return _parseOsrmResponse(response.data);
    } else {
      throw Exception('OSRM Cycling error: ${response.statusCode}');
    }
  }

  /// Select key waypoints to reduce routing calls
  static List<LatLng> _selectKeyWaypoints(List<LatLng> waypoints) {
    if (waypoints.length <= 4) return waypoints;
    
    // Select start, quarter points, and end for faster routing
    final keyIndices = [
      0, // Start
      (waypoints.length * 0.25).round(), // Quarter
      (waypoints.length * 0.5).round(),  // Half
      (waypoints.length * 0.75).round(), // Three-quarter
      waypoints.length - 1, // End
    ];
    
    return keyIndices.map((i) => waypoints[i]).toList();
  }

  /// Create a smooth geometric route when routing fails
  static List<LatLng> _createGeometricRoute(List<LatLng> waypoints, double targetDistanceKm) {
    final route = <LatLng>[];
    final targetPoints = (targetDistanceKm * 20).round(); // ~50m between points
    
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      final segmentDistance = Distance().as(LengthUnit.Meter, start, end);
      final segmentPoints = (segmentDistance / 50).round().clamp(2, 20);
      
      // Add intermediate points with realistic variation
      for (int j = 0; j < segmentPoints; j++) {
        final ratio = j / (segmentPoints - 1);
        
        // Linear interpolation with slight random variation for realism
        final lat = start.latitude + (end.latitude - start.latitude) * ratio;
        final lng = start.longitude + (end.longitude - start.longitude) * ratio;
        
        // Add small random variation to simulate road following
        final variation = 0.0001; // ~10m variation
        final variedLat = lat + (Random().nextDouble() - 0.5) * variation;
        final variedLng = lng + (Random().nextDouble() - 0.5) * variation;
        
        route.add(LatLng(variedLat, variedLng));
      }
    }
    
    return route;
  }

  /// Interpolate missing route segments
  static List<LatLng> _interpolateRoute(List<LatLng> routedSegments, List<LatLng> originalWaypoints) {
    // For now, just return the routed segments
    // Could be enhanced to insert missing waypoints
    return routedSegments;
  }

  /// Get angle variation based on strategy
  static double _getAngleVariation(RoundtripStrategy strategy) {
    switch (strategy) {
      case RoundtripStrategy.direct:
        return 0.2; // Minimal variation
      case RoundtripStrategy.scenic:
        return 0.6; // More variation
      case RoundtripStrategy.exploration:
        return 0.8; // Maximum variation
      default:
        return 0.4; // Balanced
    }
  }

  /// Get radius variation for interesting shapes
  static double _getRadiusVariation(RoundtripStrategy strategy, int index, int total) {
    final normalizedIndex = index / total;
    final waveComponent = 0.3 + (sin(normalizedIndex * pi * 3) + 1) * 0.35;
    
    switch (strategy) {
      case RoundtripStrategy.direct:
        return 0.9 + waveComponent * 0.1; // Minimal variation
      case RoundtripStrategy.scenic:
      case RoundtripStrategy.exploration:
        return 0.6 + waveComponent * 0.6; // More variation
      default:
        return 0.8 + waveComponent * 0.3; // Balanced
    }
  }

  /// Calculate point at given distance and bearing
  static LatLng _calculatePointAtDistance(LatLng start, double bearingRad, double distanceM) {
    const earthRadiusM = 6371000.0;
    
    final latRad = start.latitude * pi / 180;
    final lonRad = start.longitude * pi / 180;
    
    final angularDistance = distanceM / earthRadiusM;
    
    final targetLatRad = asin(
      sin(latRad) * cos(angularDistance) +
      cos(latRad) * sin(angularDistance) * cos(bearingRad)
    );
    
    final targetLonRad = lonRad + atan2(
      sin(bearingRad) * sin(angularDistance) * cos(latRad),
      cos(angularDistance) - sin(latRad) * sin(targetLatRad)
    );
    
    return LatLng(
      targetLatRad * 180 / pi,
      targetLonRad * 180 / pi,
    );
  }

  /// Calculate total route distance
  static double _calculateRouteDistance(List<LatLng> points) {
    if (points.length < 2) return 0;
    
    double totalDistance = 0;
    final distance = Distance();
    
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += distance.as(LengthUnit.Meter, points[i], points[i + 1]);
    }
    
    return totalDistance;
  }

  /// Parse GraphHopper response format
  static List<LatLng> _parseGraphHopperResponse(Map<String, dynamic> data) {
    try {
      debugPrint('Parsing GraphHopper response...');
      
      final paths = data['paths'] as List?;
      if (paths == null || paths.isEmpty) {
        debugPrint('No paths found in GraphHopper response');
        return [];
      }

      final path = paths[0] as Map<String, dynamic>;
      final points = path['points'] as Map<String, dynamic>?;
      
      if (points == null) {
        debugPrint('No points found in GraphHopper path');
        return [];
      }

      final coordinates = points['coordinates'] as List?;
      if (coordinates == null || coordinates.isEmpty) {
        debugPrint('No coordinates found in GraphHopper points');
        return [];
      }

      // GraphHopper returns coordinates as [[lng, lat], [lng, lat], ...]
      final route = <LatLng>[];
      for (final coord in coordinates) {
        if (coord is List && coord.length >= 2) {
          final lng = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          route.add(LatLng(lat, lng));
        }
      }

      debugPrint('Successfully parsed ${route.length} GraphHopper route points');
      return route;
      
    } catch (e, stackTrace) {
      debugPrint('Error parsing GraphHopper response: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Response data: $data');
      return [];
    }
  }

  /// Parse OSRM response format
  static List<LatLng> _parseOsrmResponse(Map<String, dynamic> data) {
    try {
      debugPrint('Parsing OSRM response...');
      
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        debugPrint('No routes found in OSRM response');
        return [];
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      
      if (geometry == null) {
        debugPrint('No geometry found in OSRM route');
        return [];
      }

      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null || coordinates.isEmpty) {
        debugPrint('No coordinates found in OSRM geometry');
        return [];
      }

      // OSRM also returns LineString coordinates as [[lng, lat], [lng, lat], ...]
      final routePoints = <LatLng>[];
      for (final coord in coordinates) {
        if (coord is List && coord.length >= 2) {
          final lng = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          routePoints.add(LatLng(lat, lng));
        }
      }

      debugPrint('Successfully parsed ${routePoints.length} OSRM route points');
      return routePoints;
      
    } catch (e, stackTrace) {
      debugPrint('Error parsing OSRM response: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Response data: $data');
      return [];
    }
  }
}

/// Strategy for roundtrip generation
enum RoundtripStrategy {
  scenic,
  direct,
  balanced,
  exploration,
}

/// Fast roundtrip route result
class FastRoundtripRoute {
  final List<LatLng> waypoints;
  final List<LatLng> routedPath;
  final LatLng startPoint;
  final double actualDistanceKm;
  final double targetDistanceKm;
  final Duration estimatedTime;
  final ActivityType activityType;
  final RoundtripStrategy strategy;
  final int generationTimeMs;

  const FastRoundtripRoute({
    required this.waypoints,
    required this.routedPath,
    required this.startPoint,
    required this.actualDistanceKm,
    required this.targetDistanceKm,
    required this.estimatedTime,
    required this.activityType,
    required this.strategy,
    required this.generationTimeMs,
  });

  /// Distance accuracy as a percentage
  double get distanceAccuracy {
    if (targetDistanceKm == 0) return 100.0;
    return 100.0 - ((actualDistanceKm - targetDistanceKm).abs() / targetDistanceKm * 100.0);
  }

  /// Whether this is a high-quality route
  bool get isHighQuality {
    return distanceAccuracy >= 60.0 && 
           actualDistanceKm >= targetDistanceKm * 0.4 &&
           routedPath.length >= waypoints.length;
  }

  /// Whether generation was fast (< 10 seconds)
  bool get isFastGeneration {
    return generationTimeMs < 10000;
  }

  @override
  String toString() {
    return 'FastRoundtripRoute(${actualDistanceKm.toStringAsFixed(1)}km, ${waypoints.length} waypoints, ${generationTimeMs}ms, ${distanceAccuracy.toStringAsFixed(1)}% accuracy)';
  }
}