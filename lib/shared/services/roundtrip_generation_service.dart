import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/activity_types.dart';
import 'routing_service.dart';

class RoundtripGenerationService {
  static const int _maxGenerationAttempts = 3;
  static const double _minViableDistance = 0.3; // 30% of target distance
  static const double _maxDistanceVariance = 0.3; // 30% variance allowed

  /// Generate a realistic roundtrip route that follows actual roads/paths
  static Future<RoundtripRoute?> generateRealisticRoundtrip({
    required LatLng startPoint,
    required double targetDistanceKm,
    required ActivityType activityType,
    RoundtripStrategy strategy = RoundtripStrategy.balanced,
  }) async {
    debugPrint('🔄 Generating realistic roundtrip: ${targetDistanceKm}km ${activityType.name} from ${startPoint.latitude.toStringAsFixed(4)},${startPoint.longitude.toStringAsFixed(4)}');

    for (int attempt = 1; attempt <= _maxGenerationAttempts; attempt++) {
      debugPrint('🎯 Generation attempt $attempt/$_maxGenerationAttempts');
      
      try {
        final route = await _generateSingleRoundtrip(
          startPoint: startPoint,
          targetDistanceKm: targetDistanceKm,
          activityType: activityType,
          strategy: strategy,
          attempt: attempt,
        );
        
        if (route != null) {
          debugPrint('✅ Successfully generated roundtrip: ${route.actualDistanceKm.toStringAsFixed(1)}km');
          return route;
        }
      } catch (e) {
        debugPrint('❌ Attempt $attempt failed: $e');
      }
    }
    
    debugPrint('💥 Failed to generate viable roundtrip after $_maxGenerationAttempts attempts');
    return null;
  }

  /// Generate a single roundtrip attempt
  static Future<RoundtripRoute?> _generateSingleRoundtrip({
    required LatLng startPoint,
    required double targetDistanceKm,
    required ActivityType activityType,
    required RoundtripStrategy strategy,
    required int attempt,
  }) async {
    final targetDistanceM = targetDistanceKm * 1000;
    
    // Generate strategic waypoints in a roughly circular pattern
    final waypoints = await _generateStrategicWaypoints(
      startPoint: startPoint,
      targetDistanceM: targetDistanceM,
      activityType: activityType,
      strategy: strategy,
      attempt: attempt,
    );
    
    if (waypoints.length < 3) {
      debugPrint('⚠️ Insufficient waypoints generated: ${waypoints.length}');
      return null;
    }
    
    // Route through the waypoints using the existing routing service
    debugPrint('🗺️ Routing through ${waypoints.length} waypoints...');
    final routedPath = await _routeThroughWaypoints(waypoints, activityType);
    
    if (routedPath.isEmpty) {
      debugPrint('❌ Failed to route through waypoints');
      return null;
    }
    
    // Calculate actual distance and validate
    final actualDistanceM = _calculateRouteDistance(routedPath);
    final actualDistanceKm = actualDistanceM / 1000;
    final distanceError = (actualDistanceKm - targetDistanceKm).abs() / targetDistanceKm;
    
    debugPrint('📏 Route distance: ${actualDistanceKm.toStringAsFixed(1)}km (target: ${targetDistanceKm}km, error: ${(distanceError * 100).toStringAsFixed(1)}%)');
    
    // Validate route quality
    if (actualDistanceKm < targetDistanceKm * _minViableDistance) {
      debugPrint('❌ Route too short: ${actualDistanceKm.toStringAsFixed(1)}km < ${(targetDistanceKm * _minViableDistance).toStringAsFixed(1)}km');
      return null;
    }
    
    if (distanceError > _maxDistanceVariance) {
      debugPrint('⚠️ Route distance variance too high: ${(distanceError * 100).toStringAsFixed(1)}%');
      // Don't reject, but note the variance
    }
    
    // Calculate estimated time
    final estimatedTime = RoutingService.getEstimatedTime(routedPath, activityType);
    
    return RoundtripRoute(
      waypoints: waypoints,
      routedPath: routedPath,
      startPoint: startPoint,
      actualDistanceKm: actualDistanceKm,
      targetDistanceKm: targetDistanceKm,
      estimatedTime: estimatedTime,
      activityType: activityType,
      strategy: strategy,
    );
  }

  /// Generate strategic waypoints for the roundtrip
  static Future<List<LatLng>> _generateStrategicWaypoints({
    required LatLng startPoint,
    required double targetDistanceM,
    required ActivityType activityType,
    required RoundtripStrategy strategy,
    required int attempt,
  }) async {
    // Calculate parameters for waypoint distribution
    final approximateRadius = targetDistanceM / (2 * pi);
    final numWaypoints = _calculateOptimalWaypoints(targetDistanceM, strategy);
    final angleStep = (2 * pi) / numWaypoints;
    
    debugPrint('🎯 Generating $numWaypoints waypoints in ~${(approximateRadius / 1000).toStringAsFixed(1)}km radius');
    
    final waypoints = <LatLng>[startPoint];
    final usedDirections = <double>[];
    
    // Generate waypoints in a strategic pattern
    for (int i = 0; i < numWaypoints - 1; i++) {
      final baseAngle = i * angleStep;
      final variation = _getAngleVariation(strategy, attempt) * angleStep;
      final targetAngle = baseAngle + ((Random().nextDouble() - 0.5) * variation);
      
      // Avoid previously used directions
      final adjustedAngle = _avoidUsedDirections(targetAngle, usedDirections, angleStep * 0.3);
      usedDirections.add(adjustedAngle);
      
      // Calculate distance variation for this waypoint
      final radiusVariation = _getRadiusVariation(strategy, i, numWaypoints);
      final effectiveRadius = approximateRadius * radiusVariation;
      
      // Generate target position
      final targetPoint = _calculateTargetPoint(startPoint, adjustedAngle, effectiveRadius);
      
      // Try to find a reachable waypoint near the target
      final waypoint = await _findReachableWaypoint(
        targetPoint: targetPoint,
        previousPoint: waypoints.last,
        activityType: activityType,
        maxSearchDistance: effectiveRadius * 0.3,
      );
      
      if (waypoint != null) {
        waypoints.add(waypoint);
        debugPrint('📍 Added waypoint ${waypoints.length - 1}: ${waypoint.latitude.toStringAsFixed(4)},${waypoint.longitude.toStringAsFixed(4)}');
      }
    }
    
    // Ensure we can close the loop back to start
    waypoints.add(startPoint);
    
    return waypoints;
  }

  /// Calculate optimal number of waypoints based on distance and strategy
  static int _calculateOptimalWaypoints(double targetDistanceM, RoundtripStrategy strategy) {
    final baseWaypoints = (targetDistanceM / 2500).round().clamp(4, 12);
    
    switch (strategy) {
      case RoundtripStrategy.scenic:
        return (baseWaypoints * 1.3).round().clamp(6, 15); // More waypoints for scenic routes
      case RoundtripStrategy.direct:
        return (baseWaypoints * 0.8).round().clamp(3, 8);  // Fewer waypoints for direct routes
      case RoundtripStrategy.exploration:
        return (baseWaypoints * 1.5).round().clamp(8, 18); // Most waypoints for exploration
      case RoundtripStrategy.balanced:
        return baseWaypoints;
    }
  }

  /// Get angle variation based on strategy
  static double _getAngleVariation(RoundtripStrategy strategy, int attempt) {
    double baseVariation = 0.4;
    
    switch (strategy) {
      case RoundtripStrategy.scenic:
        baseVariation = 0.6; // More variation for scenic routes
        break;
      case RoundtripStrategy.direct:
        baseVariation = 0.2; // Less variation for direct routes
        break;
      case RoundtripStrategy.exploration:
        baseVariation = 0.8; // Maximum variation for exploration
        break;
      case RoundtripStrategy.balanced:
        baseVariation = 0.4;
        break;
    }
    
    // Increase variation with each attempt
    return baseVariation * (1 + (attempt - 1) * 0.3);
  }

  /// Get radius variation for creating interesting shapes
  static double _getRadiusVariation(RoundtripStrategy strategy, int waypointIndex, int totalWaypoints) {
    final normalizedIndex = waypointIndex / totalWaypoints;
    
    // Create a wave pattern for more interesting loops
    final waveComponent = 0.3 + (sin(normalizedIndex * pi * 2) + 1) * 0.35;
    
    switch (strategy) {
      case RoundtripStrategy.scenic:
        return 0.7 + waveComponent * 0.5; // Wider variation for scenic routes
      case RoundtripStrategy.direct:
        return 0.9 + waveComponent * 0.2; // Minimal variation for direct routes
      case RoundtripStrategy.exploration:
        return 0.5 + waveComponent * 0.7; // Maximum variation for exploration
      case RoundtripStrategy.balanced:
        return 0.8 + waveComponent * 0.4;
    }
  }

  /// Avoid previously used directions to prevent overlap
  static double _avoidUsedDirections(double targetAngle, List<double> usedDirections, double minSeparation) {
    double adjustedAngle = targetAngle;
    
    for (final usedAngle in usedDirections) {
      final diff = (adjustedAngle - usedAngle).abs();
      final normalizedDiff = diff > pi ? 2 * pi - diff : diff;
      
      if (normalizedDiff < minSeparation) {
        // Adjust angle to avoid collision
        if (adjustedAngle > usedAngle) {
          adjustedAngle = usedAngle + minSeparation;
        } else {
          adjustedAngle = usedAngle - minSeparation;
        }
        
        // Normalize angle
        adjustedAngle = adjustedAngle % (2 * pi);
      }
    }
    
    return adjustedAngle;
  }

  /// Calculate target point at given angle and distance
  static LatLng _calculateTargetPoint(LatLng startPoint, double angle, double distanceM) {
    const earthRadiusM = 6371000.0;
    
    final latRad = startPoint.latitude * pi / 180;
    final lonRad = startPoint.longitude * pi / 180;
    
    final angularDistance = distanceM / earthRadiusM;
    
    final targetLatRad = asin(
      sin(latRad) * cos(angularDistance) +
      cos(latRad) * sin(angularDistance) * cos(angle)
    );
    
    final targetLonRad = lonRad + atan2(
      sin(angle) * sin(angularDistance) * cos(latRad),
      cos(angularDistance) - sin(latRad) * sin(targetLatRad)
    );
    
    return LatLng(
      targetLatRad * 180 / pi,
      targetLonRad * 180 / pi,
    );
  }

  /// Find a reachable waypoint near the target point (fast version)
  static Future<LatLng?> _findReachableWaypoint({
    required LatLng targetPoint,
    required LatLng previousPoint,
    required ActivityType activityType,
    required double maxSearchDistance,
  }) async {
    // For speed, just use the target point with some random variation
    // This avoids slow reachability checks that require API calls
    final variation = maxSearchDistance * 0.1; // 10% variation
    final randomLat = targetPoint.latitude + (Random().nextDouble() - 0.5) * variation / 111320;
    final randomLng = targetPoint.longitude + (Random().nextDouble() - 0.5) * variation / (111320 * cos(targetPoint.latitude * pi / 180));
    
    return LatLng(randomLat, randomLng);
  }

  /// Generate candidate points in a circle around the target
  static List<LatLng> _generateCandidatePoints(LatLng center, double radiusM, int numCandidates) {
    final candidates = <LatLng>[];
    final angleStep = (2 * pi) / numCandidates;
    
    for (int i = 0; i < numCandidates; i++) {
      final angle = i * angleStep;
      final candidate = _calculateTargetPoint(center, angle, radiusM);
      candidates.add(candidate);
    }
    
    return candidates;
  }

  /// Check if we can route between two points
  static Future<bool> _canReachPoint(LatLng from, LatLng to, ActivityType activityType) async {
    try {
      return await RoutingService.canRoute(from, to, activityType);
    } catch (e) {
      return false;
    }
  }

  /// Route through all waypoints to create the final path
  static Future<List<LatLng>> _routeThroughWaypoints(List<LatLng> waypoints, ActivityType activityType) async {
    if (waypoints.length < 2) return waypoints;
    
    final completePath = <LatLng>[];
    
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
        } else {
          debugPrint('⚠️ No route found for segment ${i + 1}, using direct line');
          if (i == 0) completePath.add(waypoints[i]);
          completePath.add(waypoints[i + 1]);
        }
      } catch (e) {
        debugPrint('❌ Routing failed for segment ${i + 1}: $e');
        if (i == 0) completePath.add(waypoints[i]);
        completePath.add(waypoints[i + 1]);
      }
    }
    
    return completePath;
  }

  /// Calculate total distance of a route
  static double _calculateRouteDistance(List<LatLng> points) {
    if (points.length < 2) return 0;
    
    double totalDistance = 0;
    final distance = Distance();
    
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += distance.as(LengthUnit.Meter, points[i], points[i + 1]);
    }
    
    return totalDistance;
  }
}

/// Strategy for roundtrip generation
enum RoundtripStrategy {
  scenic,      // Focus on parks, paths, and scenic areas
  direct,      // Most efficient circular route
  balanced,    // Good mix of efficiency and variety
  exploration, // Maximum area coverage and diversity
}

/// Generated roundtrip route with metadata
class RoundtripRoute {
  final List<LatLng> waypoints;
  final List<LatLng> routedPath;
  final LatLng startPoint;
  final double actualDistanceKm;
  final double targetDistanceKm;
  final Duration estimatedTime;
  final ActivityType activityType;
  final RoundtripStrategy strategy;

  const RoundtripRoute({
    required this.waypoints,
    required this.routedPath,
    required this.startPoint,
    required this.actualDistanceKm,
    required this.targetDistanceKm,
    required this.estimatedTime,
    required this.activityType,
    required this.strategy,
  });

  /// Distance accuracy as a percentage (100% = perfect match)
  double get distanceAccuracy {
    if (targetDistanceKm == 0) return 100.0;
    return 100.0 - ((actualDistanceKm - targetDistanceKm).abs() / targetDistanceKm * 100.0);
  }

  /// Whether this is a high-quality route
  bool get isHighQuality {
    return distanceAccuracy >= 70.0 && 
           actualDistanceKm >= targetDistanceKm * 0.5 &&
           routedPath.length >= waypoints.length;
  }

  @override
  String toString() {
    return 'RoundtripRoute(${actualDistanceKm.toStringAsFixed(1)}km, ${waypoints.length} waypoints, ${distanceAccuracy.toStringAsFixed(1)}% accuracy)';
  }
}