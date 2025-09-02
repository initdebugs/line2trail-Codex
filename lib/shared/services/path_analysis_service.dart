import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../core/constants/activity_types.dart';

class PathTypeBreakdown {
  final double footpathPercent;
  final double cyclePathPercent;
  final double roadPercent;
  final double totalDistanceKm;
  final double avgSpeed; // km/h based on activity type
  final String difficulty;
  final List<RouteSegment> segments;
  
  PathTypeBreakdown({
    required this.footpathPercent,
    required this.cyclePathPercent,
    required this.roadPercent,
    required this.totalDistanceKm,
    required this.avgSpeed,
    required this.difficulty,
    required this.segments,
  });
}

class RouteSegment {
  final LatLng start;
  final LatLng end;
  final double distance; // meters
  final PathType type;
  final double estimatedSpeed; // km/h
  
  RouteSegment({
    required this.start,
    required this.end,
    required this.distance,
    required this.type,
    required this.estimatedSpeed,
  });
}

enum PathType {
  footpath,
  cyclePath,
  road,
}

class PathAnalysisService {
  static Future<PathTypeBreakdown> analyze(List<LatLng> points, ActivityType activity) async {
    if (points.length < 2) {
      return PathTypeBreakdown(
        footpathPercent: 0,
        cyclePathPercent: 0,
        roadPercent: 0,
        totalDistanceKm: 0,
        avgSpeed: 0,
        difficulty: 'Onbekend',
        segments: [],
      );
    }

    final segments = _analyzeSegments(points, activity);
    final totalDistance = segments.fold<double>(0, (sum, seg) => sum + seg.distance);
    final totalDistanceKm = totalDistance / 1000.0;

    // Calculate path type percentages from segments
    double footpathDistance = 0, cyclePathDistance = 0, roadDistance = 0;
    for (final segment in segments) {
      switch (segment.type) {
        case PathType.footpath:
          footpathDistance += segment.distance;
          break;
        case PathType.cyclePath:
          cyclePathDistance += segment.distance;
          break;
        case PathType.road:
          roadDistance += segment.distance;
          break;
      }
    }

    final footPercent = totalDistance > 0 ? (footpathDistance / totalDistance) * 100 : 0;
    final cyclePercent = totalDistance > 0 ? (cyclePathDistance / totalDistance) * 100 : 0;
    final roadPercent = totalDistance > 0 ? (roadDistance / totalDistance) * 100 : 0;

    // Calculate average speed based on segments
    final avgSpeed = _calculateAvgSpeed(segments, activity);
    
    // Determine difficulty
    final difficulty = _calculateDifficulty(segments, totalDistanceKm, activity);

    return PathTypeBreakdown(
      footpathPercent: footPercent.toDouble(),
      cyclePathPercent: cyclePercent.toDouble(),
      roadPercent: roadPercent.toDouble(),
      totalDistanceKm: totalDistanceKm,
      avgSpeed: avgSpeed,
      difficulty: difficulty,
      segments: segments,
    );
  }

  static List<RouteSegment> _analyzeSegments(List<LatLng> points, ActivityType activity) {
    final segments = <RouteSegment>[];
    final distance = Distance();
    final random = Random(_hashPoints(points));

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final segmentDistance = distance(start, end);
      
      // Determine path type based on various factors
      final pathType = _determinePathType(start, end, segmentDistance, activity, random);
      
      // Estimate speed for this segment
      final estimatedSpeed = _getSpeedForSegment(pathType, activity, segmentDistance);
      
      segments.add(RouteSegment(
        start: start,
        end: end,
        distance: segmentDistance,
        type: pathType,
        estimatedSpeed: estimatedSpeed,
      ));
    }

    return segments;
  }

  static PathType _determinePathType(LatLng start, LatLng end, double segmentDistance, ActivityType activity, Random random) {
    // Simulate path type determination based on various heuristics
    // In a real implementation, this would use OSM data or routing service metadata
    
    final distanceFactor = segmentDistance.clamp(0, 500) / 500; // 0-1 scale
    final randomFactor = random.nextDouble();
    
    switch (activity) {
      case ActivityType.cycling:
        if (distanceFactor > 0.7 && randomFactor < 0.7) return PathType.cyclePath;
        if (randomFactor < 0.25) return PathType.road;
        return PathType.cyclePath;
        
      case ActivityType.hiking:
        if (distanceFactor < 0.3 && randomFactor < 0.8) return PathType.footpath;
        if (randomFactor < 0.2) return PathType.road;
        return PathType.footpath;
        
      case ActivityType.running:
        if (distanceFactor > 0.5 && randomFactor < 0.6) return PathType.footpath;
        if (randomFactor < 0.3) return PathType.road;
        return PathType.footpath;
        
      case ActivityType.walking:
        if (randomFactor < 0.7) return PathType.footpath;
        if (randomFactor < 0.9) return PathType.road;
        return PathType.cyclePath;
    }
  }

  static double _getSpeedForSegment(PathType pathType, ActivityType activity, double segmentDistance) {
    // Base speeds by activity type
    Map<ActivityType, double> baseSpeeds = {
      ActivityType.walking: 4.5,
      ActivityType.running: 8.5,
      ActivityType.cycling: 18.0,
      ActivityType.hiking: 3.5,
    };

    double baseSpeed = baseSpeeds[activity] ?? 5.0;
    
    // Adjust speed based on path type
    switch (pathType) {
      case PathType.road:
        baseSpeed *= 1.1; // Slightly faster on roads
        break;
      case PathType.cyclePath:
        if (activity == ActivityType.cycling) {
          baseSpeed *= 1.0;
        } else {
          baseSpeed *= 0.9; // Slightly slower for non-cycling activities
        }
        break;
      case PathType.footpath:
        if (activity == ActivityType.hiking) {
          baseSpeed *= 0.8; // Slower on trails
        } else {
          baseSpeed *= 0.95;
        }
        break;
    }
    
    // Adjust for segment length (longer segments might be faster)
    if (segmentDistance > 200) {
      baseSpeed *= 1.05;
    }
    if (segmentDistance < 50) {
      baseSpeed *= 0.9;
    }
    
    return baseSpeed;
  }

  static double _calculateAvgSpeed(List<RouteSegment> segments, ActivityType activity) {
    if (segments.isEmpty) return 0;
    
    double totalDistance = 0;
    double totalTime = 0;
    
    for (final segment in segments) {
      totalDistance += segment.distance;
      totalTime += (segment.distance / 1000.0) / segment.estimatedSpeed; // hours
    }
    
    return totalTime > 0 ? totalDistance / 1000.0 / totalTime : 0;
  }

  static String _calculateDifficulty(List<RouteSegment> segments, double totalDistanceKm, ActivityType activity) {
    // Calculate difficulty based on distance, path variety, and activity type
    double difficultyScore = 0;
    
    // Distance factor
    switch (activity) {
      case ActivityType.walking:
        if (totalDistanceKm > 15) {
          difficultyScore += 2;
        } else if (totalDistanceKm > 8) {
          difficultyScore += 1;
        }
        break;
      case ActivityType.running:
        if (totalDistanceKm > 20) {
          difficultyScore += 2;
        } else if (totalDistanceKm > 10) {
          difficultyScore += 1;
        }
        break;
      case ActivityType.cycling:
        if (totalDistanceKm > 50) {
          difficultyScore += 2;
        } else if (totalDistanceKm > 25) {
          difficultyScore += 1;
        }
        break;
      case ActivityType.hiking:
        if (totalDistanceKm > 12) {
          difficultyScore += 2;
        } else if (totalDistanceKm > 6) {
          difficultyScore += 1;
        }
        break;
    }
    
    // Path variety factor
    final pathTypes = segments.map((s) => s.type).toSet();
    if (pathTypes.length > 2) {
      difficultyScore += 1;
    }
    
    // Speed variation factor
    final speeds = segments.map((s) => s.estimatedSpeed).toList();
    if (speeds.isNotEmpty) {
      final minSpeed = speeds.reduce(min);
      final maxSpeed = speeds.reduce(max);
      if (maxSpeed - minSpeed > 3) {
        difficultyScore += 1;
      }
    }
    
    if (difficultyScore <= 1) return 'Makkelijk';
    if (difficultyScore <= 3) return 'Gemiddeld';
    return 'Moeilijk';
  }

  static int _hashPoints(List<LatLng> points) {
    // Create a consistent hash from route points for reproducible randomness
    int hash = 0;
    for (final point in points.take(10)) {
      hash ^= (point.latitude * 10000).round();
      hash ^= (point.longitude * 10000).round() << 1;
    }
    return hash.abs();
  }
}

