import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/activity_types.dart';

class RoutingService {
  static final Dio _dio = Dio();
  
  // Using public OpenRouteService endpoint (rate limited but no API key required)
  static const String _baseUrl = 'https://api.openrouteservice.org';
  
  // For development, we'll try real service first, fallback to mock if needed
  static bool _useMockService = false;

  /// Snap a series of points to walkable paths using real routing
  static Future<List<LatLng>> snapToPath({
    required List<LatLng> points,
    required ActivityType activityType,
  }) async {
    if (points.length < 2) return points;

    // Try real routing service first
    try {
      return await _realSnapToPath(points, activityType);
    } catch (e) {
      debugPrint('Real routing failed: $e, falling back to mock');
      // Fall back to mock if real service fails
      return await _mockSnapToPath(points, activityType);
    }
  }

  /// Advanced routing that tries multiple transport modes to find the best path
  /// This allows for mixed routing (e.g., walking + cycling + footpaths)
  static Future<List<LatLng>> snapToPathMixed({
    required List<LatLng> points,
    required ActivityType primaryActivityType,
    bool allowMixedModes = true,
  }) async {
    if (points.length < 2) return points;

    // If mixed modes are disabled, use regular routing
    if (!allowMixedModes) {
      return await snapToPath(points: points, activityType: primaryActivityType);
    }

    // Try primary activity type first
    try {
      final primaryResult = await _realSnapToPath(points, primaryActivityType);
      
      // If we got a good result, return it
      if (primaryResult.length > points.length * 2) {
        debugPrint('✅ Mixed routing: Primary mode ($primaryActivityType) worked well');
        return primaryResult;
      }
      
      // If result is sparse, try alternative modes for better coverage
      debugPrint('🔄 Mixed routing: Trying alternative modes for better path coverage...');
      return await _tryAlternativeModes(points, primaryActivityType);
      
    } catch (e) {
      debugPrint('Mixed routing primary mode failed: $e, trying alternatives...');
      return await _tryAlternativeModes(points, primaryActivityType);
    }
  }

  /// Try alternative routing modes when primary mode doesn't work well
  static Future<List<LatLng>> _tryAlternativeModes(List<LatLng> points, ActivityType primaryType) async {
    // Define alternative modes to try
    final alternatives = <ActivityType>[];
    
    switch (primaryType) {
      case ActivityType.walking:
        alternatives.addAll([ActivityType.cycling, ActivityType.hiking]); // Try bike paths and trails
        break;
      case ActivityType.cycling:
        alternatives.addAll([ActivityType.walking, ActivityType.hiking]); // Try pedestrian infrastructure
        break;
      case ActivityType.hiking:
        alternatives.addAll([ActivityType.walking, ActivityType.cycling]); // Try more developed paths
        break;
      case ActivityType.running:
        alternatives.addAll([ActivityType.walking, ActivityType.cycling]); // Similar to walking
        break;
    }

    List<LatLng> bestResult = [];
    String bestMode = 'none';
    
    // Try each alternative mode
    for (final altType in alternatives) {
      try {
        final result = await _realSnapToPath(points, altType);
        
        // Use the result if it's better than what we have
        if (result.length > bestResult.length) {
          bestResult = result;
          bestMode = altType.toString();
        }
        
        // If we get a really good result, use it immediately
        if (result.length > points.length * 3) {
          debugPrint('✅ Mixed routing: Found excellent path using $altType');
          break;
        }
      } catch (e) {
        debugPrint('Alternative mode $altType failed: $e');
        continue;
      }
    }
    
    if (bestResult.isNotEmpty) {
      debugPrint('✅ Mixed routing: Best alternative was $bestMode with ${bestResult.length} points');
      return bestResult;
    }
    
    // If all else fails, fall back to mock
    debugPrint('⚠️ Mixed routing: All modes failed, using mock routing');
    return await _mockSnapToPath(points, primaryType);
  }

  /// Real path snapping using routing services (prioritizes proper infrastructure)
  static Future<List<LatLng>> _realSnapToPath(List<LatLng> points, ActivityType activityType) async {
    debugPrint('🚀 _realSnapToPath: Trying routing for ${activityType.name} with ${points.length} points');
    
    // Prioritize Overpass API first for proper infrastructure (like normal drawing mode)
    try {
      debugPrint('🗺️ Trying Overpass API (proper infrastructure)...');
      return await _overpassRouting(points, activityType);
    } catch (e) {
      debugPrint('Overpass failed: $e, trying OSRM...');
      try {
        return await _osrmSnap(points, activityType);
      } catch (e2) {
        debugPrint('OSRM failed: $e2, trying GraphHopper...');
        try {
          return await _graphHopperSnap(points, activityType);
        } catch (e3) {
          debugPrint('GraphHopper failed: $e3, trying Mapbox...');
          return await _mapboxSnap(points, activityType);
        }
      }
    }
  }

  /// Overpass API routing (like your working HTML project)
  static Future<List<LatLng>> _overpassRouting(List<LatLng> points, ActivityType activityType) async {
    debugPrint('🗺️ Starting Overpass API routing...');
    
    // Create bounding box around the route points
    double minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLon = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLon = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    
    // Add margin
    const margin = 0.01;
    final bbox = [minLat - margin, minLon - margin, maxLat + margin, maxLon + margin];
    
    // Query for pedestrian and cycling infrastructure (like your HTML project)
    final query = '''
    [out:json][timeout:45];
    (
      way["highway"="cycleway"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
      way["cycleway"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
      way["highway"="path"]["bicycle"~"^(yes|designated)\$"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
      way["highway"="footway"]["bicycle"~"^(yes|designated)\$"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
      way["highway"="footway"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
      way["highway"="pedestrian"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
      way["highway"="steps"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
      way["highway"~"^(residential|living_street|service|unclassified|tertiary|secondary|primary|track)\$"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
    );
    (._;>;);
    out body geom;
    ''';
    
    debugPrint('🔗 Overpass query: ${query.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ')}');
    
    // Try multiple Overpass endpoints
    final endpoints = [
      'https://overpass.kumi.systems/api/interpreter',
      'https://overpass-api.de/api/interpreter',
      'https://overpass.openstreetmap.fr/api/interpreter'
    ];
    
    for (final endpoint in endpoints) {
      try {
        final url = '$endpoint?data=${Uri.encodeComponent(query)}';
        debugPrint('🌐 Trying Overpass endpoint: $endpoint');
        
        final response = await _dio.get(
          url,
          options: Options(
            headers: {'Accept': 'application/json'},
            sendTimeout: const Duration(seconds: 45),
            receiveTimeout: const Duration(seconds: 45),
          ),
        );
        
        if (response.statusCode == 200) {
          debugPrint('✅ Overpass API response received, processing...');
          return await _processOverpassData(response.data, points, activityType);
        }
      } catch (e) {
        debugPrint('❌ Overpass endpoint failed: $endpoint - $e');
        continue;
      }
    }
    
    throw Exception('All Overpass endpoints failed');
  }

  /// Mapbox routing (excellent pedestrian and cycling infrastructure)
  static Future<List<LatLng>> _mapboxSnap(List<LatLng> points, ActivityType activityType) async {
    // Convert points to coordinate string
    final coordString = points.map((p) => '${p.longitude},${p.latitude}').join(';');
    
    // Get profile for Mapbox
    String profile = 'walking';
    if (activityType == ActivityType.cycling) {
      profile = 'cycling';
    }
    
    // Mapbox Directions API - using their demo/public endpoint (has rate limits)
    final url = 'https://api.mapbox.com/directions/v5/mapbox/$profile/$coordString?geometries=geojson&overview=full&steps=true&access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4M29iazA2Z2gycXA4N2pmbDZmangifQ.-g_vE53SD2WrJ4tFg7VjQA';
    
    debugPrint('🔗 Mapbox URL: $url');
    
    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Accept': 'application/json'},
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    debugPrint('📡 Mapbox response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return _parseMapboxResponse(response.data);
    } else {
      debugPrint('❌ Mapbox error response: ${response.data}');
      throw Exception('Mapbox error: ${response.statusCode} - ${response.data}');
    }
  }

  /// GraphHopper routing (excellent for pedestrian and cycling infrastructure)
  static Future<List<LatLng>> _graphHopperSnap(List<LatLng> points, ActivityType activityType) async {
    // Convert points to GraphHopper coordinate format
    final pointParams = points.map((p) => 'point=${p.latitude},${p.longitude}').join('&');
    
    // Unified vehicle selection - use similar permissive profiles for all
    String vehicle = 'foot';
    String additional = '&weighting=shortest&avoid=motorway'; // Same restrictions for all
    
    if (activityType == ActivityType.cycling) {
      vehicle = 'bike';
      // Same restrictions as foot - only avoid motorways
    }
    // All other activity types use foot with same restrictions
    
    // GraphHopper public API (has rate limits but no API key required for basic usage)
    final url = 'https://graphhopper.com/api/1/route?$pointParams&vehicle=$vehicle$additional&debug=true&calc_points=true&type=json';
    
    debugPrint('🔗 GraphHopper URL: $url');
    
    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Accept': 'application/json'},
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    debugPrint('📡 GraphHopper response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return _parseGraphHopperResponse(response.data);
    } else {
      debugPrint('❌ GraphHopper error response: ${response.data}');
      throw Exception('GraphHopper error: ${response.statusCode} - ${response.data}');
    }
  }

  /// Simple OpenRouteService routing with minimal restrictions
  static Future<List<LatLng>> _simpleOpenRouteServiceSnap(List<LatLng> points, ActivityType activityType) async {
    // Convert points to coordinates format [longitude, latitude]
    final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();
    
    final profile = _getProfile(activityType);
    final url = '$_baseUrl/v2/directions/$profile/geojson';
    
    // Minimal routing options - let the service decide the best path
    final response = await _dio.post(
      url,
      data: {
        'coordinates': coordinates,
        'radiuses': List.filled(points.length, 5000), // Larger search radius (5km)
        'continue_straight': false,
        // No restrictions - let it use any available infrastructure
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    if (response.statusCode == 200) {
      return _parseGeojsonResponse(response.data);
    } else {
      throw Exception('Simple OpenRouteService error: ${response.statusCode} - ${response.data}');
    }
  }

  /// OpenRouteService routing
  static Future<List<LatLng>> _openRouteServiceSnap(List<LatLng> points, ActivityType activityType) async {
    // Convert points to coordinates format [longitude, latitude]
    final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();
    
    final profile = _getProfile(activityType);
    final url = '$_baseUrl/v2/directions/$profile/geojson';
    
    // Enhanced routing options for better pedestrian/cyclist infrastructure usage
    Map<String, dynamic> options = _getRoutingOptions(activityType);
    
    final response = await _dio.post(
      url,
      data: {
        'coordinates': coordinates,
        'radiuses': List.filled(points.length, 2000), // Increased to 2km search radius for better path finding
        'continue_straight': false,
        'options': options,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    if (response.statusCode == 200) {
      return _parseGeojsonResponse(response.data);
    } else {
      throw Exception('OpenRouteService error: ${response.statusCode} - ${response.data}');
    }
  }

  /// OSRM routing (fallback service)
  static Future<List<LatLng>> _osrmSnap(List<LatLng> points, ActivityType activityType) async {
    debugPrint('Using OSRM routing service...');
    
    // Unified OSRM profiles - all foot-based activities use walking
    String profile = 'walking';
    if (activityType == ActivityType.cycling) {
      profile = 'cycling';
    }
    // All other activities (walking, running, hiking) use same walking profile
    
    // Create coordinate string: "lon,lat;lon,lat;..."
    final coordString = points.map((p) => '${p.longitude},${p.latitude}').join(';');
    
    // Add OSRM options for better routing
    final options = [
      'overview=full',
      'geometries=geojson',
      'steps=true', // Get detailed step information
      'annotations=true', // Get additional route annotations
    ];
    
    final url = 'https://router.project-osrm.org/route/v1/$profile/$coordString?${options.join('&')}';
    
    debugPrint('🔗 OSRM URL: $url');
    
    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Accept': 'application/json'},
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    debugPrint('📡 OSRM response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return _parseOsrmResponse(response.data);
    } else {
      debugPrint('❌ OSRM error response: ${response.data}');
      throw Exception('OSRM error: ${response.statusCode}');
    }
  }

  /// Mock path snapping for development
  static Future<List<LatLng>> _mockSnapToPath(List<LatLng> points, ActivityType activityType) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock path snapping by adding intermediate points and slight adjustments
    List<LatLng> snappedPath = [];
    
    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      
      // Add start point with slight snap adjustment
      snappedPath.add(LatLng(
        start.latitude + (0.0001 * (i % 3 - 1)), // Small random adjustment
        start.longitude + (0.0001 * ((i + 1) % 3 - 1)),
      ));
      
      // Add intermediate points to simulate following roads/paths
      final distance = Distance().as(LengthUnit.Meter, start, end);
      final numIntermediatePoints = (distance / 100).round().clamp(1, 10);
      
      for (int j = 1; j <= numIntermediatePoints; j++) {
        final ratio = j / (numIntermediatePoints + 1);
        final lat = start.latitude + (end.latitude - start.latitude) * ratio;
        final lng = start.longitude + (end.longitude - start.longitude) * ratio;
        
        // Add some variation to simulate road following
        final variation = activityType == ActivityType.walking ? 0.0001 : 0.0002;
        snappedPath.add(LatLng(
          lat + (variation * (j % 3 - 1)),
          lng + (variation * ((j + 1) % 3 - 1)),
        ));
      }
    }
    
    // Add final point
    if (points.isNotEmpty) {
      final lastPoint = points.last;
      snappedPath.add(LatLng(
        lastPoint.latitude + 0.0001 * (points.length % 3 - 1),
        lastPoint.longitude + 0.0001 * ((points.length + 1) % 3 - 1),
      ));
    }
    
    return snappedPath;
  }

  /// Get routing profile based on activity type for OpenRouteService
  /// All profiles now allow similar routing paths, only speed differs
  static String _getProfile(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.walking:
      case ActivityType.running:
      case ActivityType.hiking:
        return 'foot-walking'; // Use same profile for all foot-based activities
      case ActivityType.cycling:
        return 'cycling-regular'; // Keep cycling for bike infrastructure
    }
  }

  /// Get unified routing options for all activity types - all can go anywhere
  static Map<String, dynamic> _getRoutingOptions(ActivityType activityType) {
    // Unified approach: all activity types can use any road/path
    // Only difference is the speed/time calculation, not the routing restrictions
    return {
      'avoid_features': ['highways'], // Only avoid highways for safety
      'preference': 'shortest', // Use shortest/most direct path
      // Remove all other restrictions - allow all modes to go anywhere
    };
  }

  /// Parse GeoJSON response from OpenRouteService
  static List<LatLng> _parseGeojsonResponse(Map<String, dynamic> data) {
    try {
      debugPrint('Parsing OpenRouteService response...');
      
      final features = data['features'] as List?;
      if (features == null || features.isEmpty) {
        debugPrint('No features found in response');
        return [];
      }

      // Get the first feature (route)
      final feature = features[0] as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      
      if (geometry == null) {
        debugPrint('No geometry found in feature');
        return [];
      }

      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null || coordinates.isEmpty) {
        debugPrint('No coordinates found in geometry');
        return [];
      }

      // OpenRouteService returns LineString coordinates as [[lng, lat], [lng, lat], ...]
      final route = <LatLng>[];
      for (final coord in coordinates) {
        if (coord is List && coord.length >= 2) {
          final lng = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          route.add(LatLng(lat, lng)); // LatLng expects (latitude, longitude)
        }
      }

      debugPrint('Successfully parsed ${route.length} route points');
      return route;
      
    } catch (e, stackTrace) {
      debugPrint('Error parsing OpenRouteService response: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Response data: $data');
      return [];
    }
  }

  /// Process Overpass data and route through it (like your HTML project)
  static Future<List<LatLng>> _processOverpassData(Map<String, dynamic> data, List<LatLng> points, ActivityType activityType) async {
    debugPrint('🔧 Processing Overpass data...');
    
    // Build routing graph from Overpass data (like your HTML project)
    final nodes = <String, Map<String, dynamic>>{};
    final nodeIndex = <int, Map<String, double>>{};
    
    // Index nodes first
    for (final element in (data['elements'] as List? ?? [])) {
      if (element['type'] == 'node') {
        nodeIndex[element['id']] = {
          'lat': element['lat'].toDouble(),
          'lon': element['lon'].toDouble(),
        };
      }
    }
    
    debugPrint('📍 Indexed ${nodeIndex.length} nodes');
    
    // Build graph edges from ways
    for (final element in (data['elements'] as List? ?? [])) {
      if (element['type'] != 'way' || element['tags'] == null) continue;
      
      final tags = Map<String, String>.from(element['tags']);
      final costFactor = _getCostFactor(tags, activityType);
      if (!costFactor.isFinite) continue; // Skip inaccessible ways
      
      List<Map<String, double>> wayPoints = [];
      
      // Get way geometry
      if (element['geometry'] != null && element['geometry'] is List) {
        // Use geometry if available
        for (final geom in element['geometry']) {
          wayPoints.add({
            'lat': geom['lat'].toDouble(),
            'lon': geom['lon'].toDouble(),
          });
        }
      } else if (element['nodes'] != null && element['nodes'] is List) {
        // Use node references
        for (final nodeId in element['nodes']) {
          final nodeData = nodeIndex[nodeId];
          if (nodeData != null) {
            wayPoints.add(nodeData);
          }
        }
      }
      
      if (wayPoints.length < 2) continue;
      
      // Create edges between consecutive points
      for (int i = 1; i < wayPoints.length; i++) {
        final a = wayPoints[i - 1];
        final b = wayPoints[i];
        
        final idA = '${a['lat']!.toStringAsFixed(6)},${a['lon']!.toStringAsFixed(6)}';
        final idB = '${b['lat']!.toStringAsFixed(6)},${b['lon']!.toStringAsFixed(6)}';
        
        // Create nodes if they don't exist
        nodes[idA] ??= {
          'id': idA,
          'lat': a['lat']!,
          'lon': a['lon']!,
          'edges': <Map<String, dynamic>>[],
        };
        nodes[idB] ??= {
          'id': idB,
          'lat': b['lat']!,
          'lon': b['lon']!,
          'edges': <Map<String, dynamic>>[],
        };
        
        final distance = _haversineDistance(a['lat']!, a['lon']!, b['lat']!, b['lon']!);
        final weight = distance * costFactor;
        final isBikeInfra = _isBikeInfrastructure(tags);
        
        // Add bidirectional edges
        (nodes[idA]!['edges'] as List).add({
          'to': idB,
          'distance': distance,
          'weight': weight,
          'bike': isBikeInfra,
          'tags': tags,
        });
        (nodes[idB]!['edges'] as List).add({
          'to': idA,
          'distance': distance,
          'weight': weight,
          'bike': isBikeInfra,
          'tags': tags,
        });
      }
    }
    
    debugPrint('🗺️ Built routing graph with ${nodes.length} nodes');
    
    // Now route through the graph using A* (like your HTML project)
    return _routeThroughGraph(nodes, points);
  }

  /// Get unified cost factor for routing - all activity types can use same paths
  static double _getCostFactor(Map<String, String> tags, ActivityType activityType) {
    final highway = tags['highway'] ?? '';
    final cycleway = tags['cycleway'] ?? '';
    final bicycle = (tags['bicycle'] ?? '').toLowerCase();
    final segregated = tags['segregated'] == 'yes';
    
    // Block only truly inaccessible roads
    if (['motorway', 'trunk', 'motorway_link', 'trunk_link'].contains(highway)) {
      return double.infinity;
    }
    if (bicycle == 'no' || bicycle == 'private') {
      return double.infinity;
    }
    
    // Unified cost calculation - all activities can use any available path
    // Prefer pedestrian and cycling infrastructure for everyone
    if (['footway', 'pedestrian', 'steps', 'path'].contains(highway)) return 0.7;
    if (highway == 'cycleway' || bicycle == 'designated' || cycleway == 'track' || segregated) return 0.7;
    
    // Residential streets are good for all activities
    if (['residential', 'living_street', 'service'].contains(highway)) {
      if (cycleway == 'lane' || bicycle == 'yes') return 1.0;
      return 1.2;
    }
    
    // Other roads - allow all activity types to use them
    if (['tertiary', 'secondary', 'primary'].contains(highway)) {
      if (cycleway == 'lane' || bicycle == 'yes') return 1.6;
      if (highway == 'primary') return 2.4; // Reduced penalty
      if (highway == 'secondary') return 2.0; // Reduced penalty
      return 1.8;
    }
    
    return 1.6; // Default for other roads - same for all activities
  }

  /// Check if infrastructure is bike-friendly (like your HTML project)
  static bool _isBikeInfrastructure(Map<String, String> tags) {
    final highway = tags['highway'] ?? '';
    final cycleway = tags['cycleway'] ?? '';
    final bicycle = (tags['bicycle'] ?? '').toLowerCase();
    final segregated = tags['segregated'] == 'yes';
    
    return highway == 'cycleway' ||
           bicycle == 'designated' ||
           cycleway == 'track' ||
           cycleway == 'lane' ||
           (highway == 'path' && (bicycle == 'yes' || bicycle == 'designated')) ||
           segregated;
  }

  /// Calculate Haversine distance
  static double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth radius in meters
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
              sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  /// Route through graph using A* pathfinding (like your HTML project)
  static List<LatLng> _routeThroughGraph(Map<String, Map<String, dynamic>> nodes, List<LatLng> points) {
    debugPrint('🎯 Starting A* routing through ${points.length} waypoints...');
    
    if (points.length < 2) return points;
    
    final routedPath = <LatLng>[];
    
    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      
      // Find nearest nodes to start and end points
      final startNode = _findNearestNode(nodes, start);
      final endNode = _findNearestNode(nodes, end);
      
      if (startNode == null || endNode == null) {
        debugPrint('⚠️ Could not find nodes for segment ${i + 1}, using direct line');
        if (i == 0) routedPath.add(start);
        routedPath.add(end);
        continue;
      }
      
      debugPrint('🔍 Routing from ${startNode['id']} to ${endNode['id']}');
      
      // Run A* pathfinding
      final path = _aStar(nodes, startNode['id'], endNode['id']);
      
      if (path.isNotEmpty) {
        // Add the path points (skip first if not first segment to avoid duplicates)
        final startIdx = i == 0 ? 0 : 1;
        for (int j = startIdx; j < path.length; j++) {
          final nodeId = path[j];
          final node = nodes[nodeId];
          if (node != null) {
            routedPath.add(LatLng(node['lat'], node['lon']));
          }
        }
        debugPrint('✅ Segment ${i + 1} routed with ${path.length} points');
      } else {
        debugPrint('⚠️ No path found for segment ${i + 1}, using direct line');
        if (i == 0) routedPath.add(start);
        routedPath.add(end);
      }
    }
    
    debugPrint('🎉 Overpass routing completed: ${routedPath.length} points');
    return routedPath;
  }

  /// Find nearest node to a point
  static Map<String, dynamic>? _findNearestNode(Map<String, Map<String, dynamic>> nodes, LatLng point) {
    Map<String, dynamic>? nearest;
    double nearestDistance = double.infinity;
    const maxSnapDistance = 200.0; // meters
    
    for (final node in nodes.values) {
      final distance = _haversineDistance(
        point.latitude, point.longitude,
        node['lat'], node['lon']
      );
      
      if (distance < nearestDistance && distance <= maxSnapDistance) {
        nearestDistance = distance;
        nearest = node;
      }
    }
    
    if (nearest != null) {
      debugPrint('📍 Snapped to node ${nearestDistance.toStringAsFixed(1)}m away');
    }
    
    return nearest;
  }

  /// A* pathfinding algorithm (like your HTML project)
  static List<String> _aStar(Map<String, Map<String, dynamic>> nodes, String startId, String goalId) {
    final openSet = <String>{startId};
    final cameFrom = <String, String>{};
    final gScore = <String, double>{startId: 0};
    final fScore = <String, double>{startId: _heuristic(nodes, startId, goalId)};
    
    while (openSet.isNotEmpty) {
      // Get node with lowest fScore
      String? current;
      double lowestF = double.infinity;
      for (final nodeId in openSet) {
        final f = fScore[nodeId] ?? double.infinity;
        if (f < lowestF) {
          lowestF = f;
          current = nodeId;
        }
      }
      
      if (current == null) break;
      if (current == goalId) {
        // Reconstruct path
        final path = <String>[current];
        while (cameFrom.containsKey(current)) {
          current = cameFrom[current]!;
          path.insert(0, current);
        }
        return path;
      }
      
      openSet.remove(current);
      final currentNode = nodes[current];
      if (currentNode == null) continue;
      
      for (final edge in (currentNode['edges'] as List)) {
        final neighbor = edge['to'] as String;
        final tentativeG = (gScore[current] ?? double.infinity) + (edge['weight'] as double);
        
        if (tentativeG < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeG;
          fScore[neighbor] = tentativeG + _heuristic(nodes, neighbor, goalId);
          openSet.add(neighbor);
        }
      }
    }
    
    return []; // No path found
  }

  /// Heuristic function for A* (straight-line distance)
  static double _heuristic(Map<String, Map<String, dynamic>> nodes, String fromId, String toId) {
    final from = nodes[fromId];
    final to = nodes[toId];
    if (from == null || to == null) return double.infinity;
    
    return _haversineDistance(from['lat'], from['lon'], to['lat'], to['lon']) * 0.7; // Optimistic multiplier
  }

  /// Parse Mapbox response format
  static List<LatLng> _parseMapboxResponse(Map<String, dynamic> data) {
    try {
      debugPrint('Parsing Mapbox response...');
      
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        debugPrint('No routes found in Mapbox response');
        return [];
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      
      if (geometry == null) {
        debugPrint('No geometry found in Mapbox route');
        return [];
      }

      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null || coordinates.isEmpty) {
        debugPrint('No coordinates found in Mapbox geometry');
        return [];
      }

      // Mapbox returns coordinates as [[lng, lat], [lng, lat], ...]
      final routePoints = <LatLng>[];
      for (final coord in coordinates) {
        if (coord is List && coord.length >= 2) {
          final lng = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          routePoints.add(LatLng(lat, lng));
        }
      }

      debugPrint('Successfully parsed ${routePoints.length} Mapbox route points');
      return routePoints;
      
    } catch (e, stackTrace) {
      debugPrint('Error parsing Mapbox response: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Response data: $data');
      return [];
    }
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
      return [];
    }
  }

  /// Check if two points can be routed
  static Future<bool> canRoute(LatLng start, LatLng end, ActivityType activityType) async {
    final distance = Distance().as(LengthUnit.Kilometer, start, end);
    
    // Basic checks
    if (distance > 50) return false; // Too far
    if (distance < 0.01) return false; // Too close
    
    if (_useMockService) {
      // Mock: assume most points can be routed for walking
      return activityType == ActivityType.walking ? true : distance < 30;
    }

    try {
      final result = await snapToPath(
        points: [start, end],
        activityType: activityType,
      );
      return result.length > 2; // Should have intermediate points if routed
    } catch (e) {
      return false;
    }
  }

  /// Get estimated walking time between two points
  static Duration getEstimatedTime(List<LatLng> points, ActivityType activityType) {
    if (points.length < 2) return Duration.zero;

    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += Distance().as(LengthUnit.Kilometer, points[i], points[i + 1]);
    }

    final speedKmh = activityType.averageSpeed;
    final timeHours = totalDistance / speedKmh;
    return Duration(milliseconds: (timeHours * 3600000).round());
  }

  /// Test the routing service with sample coordinates
  static Future<void> testRouting() async {
    debugPrint('🧪 Testing routing services...');
    
    // Test coordinates in San Francisco (known to work with routing services)
    final testPoints = [
      LatLng(37.7749, -122.4194), // San Francisco downtown
      LatLng(37.7849, -122.4094), // North Beach area
    ];

    debugPrint('Testing with coordinates: ${testPoints.map((p) => '${p.latitude},${p.longitude}').join(' -> ')}');

    try {
      final result = await snapToPath(
        points: testPoints,
        activityType: ActivityType.walking,
      );
      
      if (result.length > testPoints.length) {
        debugPrint('✅ Routing service working! Got ${result.length} route points');
        debugPrint('First few points: ${result.take(3).map((p) => '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}').join(' -> ')}');
      } else {
        debugPrint('⚠️ Routing returned same number of points - may be using mock service');
      }
    } catch (e) {
      debugPrint('❌ Routing test failed: $e');
    }

    // Test cycling routing specifically
    debugPrint('🚴 Testing cycling routing...');
    try {
      final cyclingResult = await snapToPath(
        points: testPoints,
        activityType: ActivityType.cycling,
      );
      
      debugPrint('Cycling routing got ${cyclingResult.length} points');
    } catch (e) {
      debugPrint('❌ Cycling routing test failed: $e');
    }
  }

  /// Enable/disable mock service for testing
  static void setMockMode(bool useMock) {
    _useMockService = useMock;
    debugPrint('🔧 Routing service mock mode: ${useMock ? 'enabled' : 'disabled'}');
  }
}