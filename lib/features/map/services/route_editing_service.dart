import 'package:latlong2/latlong.dart';

class RouteEditingService {
  /// Split a route at a given index
  static List<List<LatLng>> splitRoute(List<LatLng> route, int splitIndex) {
    if (splitIndex <= 0 || splitIndex >= route.length - 1) {
      return [route]; // Can't split at endpoints
    }

    final firstPart = route.sublist(0, splitIndex + 1);
    final secondPart = route.sublist(splitIndex);

    return [firstPart, secondPart];
  }

  /// Merge two routes together
  static List<LatLng> mergeRoutes(List<LatLng> route1, List<LatLng> route2, {bool connectWithLine = false}) {
    if (route1.isEmpty) return route2;
    if (route2.isEmpty) return route1;

    final merged = List<LatLng>.from(route1);

    if (connectWithLine) {
      // Add route2 directly (might create a straight line connection)
      merged.addAll(route2);
    } else {
      // Try to connect intelligently by removing the last point of route1 
      // if it's close to the first point of route2
      final lastPoint = route1.last;
      final firstPoint = route2.first;
      
      final distance = Distance().as(LengthUnit.Meter, lastPoint, firstPoint);
      
      if (distance < 50) { // Within 50 meters, merge smoothly
        merged.addAll(route2.sublist(1)); // Skip first point of route2
      } else {
        merged.addAll(route2); // Add all points
      }
    }

    return merged;
  }

  /// Remove a segment from a route between two indices
  static List<LatLng> removeSegment(List<LatLng> route, int startIndex, int endIndex) {
    if (startIndex < 0 || endIndex >= route.length || startIndex >= endIndex) {
      return route; // Invalid indices
    }

    final result = <LatLng>[];
    
    // Add points before the segment
    result.addAll(route.sublist(0, startIndex + 1));
    
    // Add points after the segment
    if (endIndex < route.length - 1) {
      result.addAll(route.sublist(endIndex));
    }

    return result;
  }

  /// Insert a new point at a specific index
  static List<LatLng> insertPoint(List<LatLng> route, int index, LatLng point) {
    if (index < 0 || index > route.length) {
      return route; // Invalid index
    }

    final result = List<LatLng>.from(route);
    result.insert(index, point);
    return result;
  }

  /// Find the closest point on the route to a given coordinate
  static RoutePoint findClosestPointOnRoute(List<LatLng> route, LatLng targetPoint) {
    if (route.isEmpty) return RoutePoint(-1, targetPoint, double.infinity);

    double minDistance = double.infinity;
    int closestIndex = 0;
    LatLng closestPoint = route[0];

    for (int i = 0; i < route.length; i++) {
      final distance = Distance().as(LengthUnit.Meter, route[i], targetPoint);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
        closestPoint = route[i];
      }
    }

    // Also check distances to line segments between points
    for (int i = 0; i < route.length - 1; i++) {
      final segmentPoint = _findClosestPointOnSegment(route[i], route[i + 1], targetPoint);
      final distance = Distance().as(LengthUnit.Meter, segmentPoint, targetPoint);
      
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
        closestPoint = segmentPoint;
      }
    }

    return RoutePoint(closestIndex, closestPoint, minDistance);
  }

  /// Find the closest point on a line segment between two points
  static LatLng _findClosestPointOnSegment(LatLng start, LatLng end, LatLng point) {
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;

    if (dx == 0 && dy == 0) {
      return start; // Start and end are the same point
    }

    final t = ((point.longitude - start.longitude) * dx + (point.latitude - start.latitude) * dy) / (dx * dx + dy * dy);

    // Clamp t to [0, 1] to stay within the segment
    final clampedT = t.clamp(0.0, 1.0);

    return LatLng(
      start.latitude + clampedT * dy,
      start.longitude + clampedT * dx,
    );
  }

  /// Reverse a route
  static List<LatLng> reverseRoute(List<LatLng> route) {
    return route.reversed.toList();
  }

  /// Simplify a route by removing points that are too close together
  static List<LatLng> simplifyRoute(List<LatLng> route, {double minDistanceMeters = 10}) {
    if (route.length <= 2) return route;

    final simplified = <LatLng>[route.first];

    for (int i = 1; i < route.length - 1; i++) {
      final distance = Distance().as(LengthUnit.Meter, simplified.last, route[i]);
      if (distance >= minDistanceMeters) {
        simplified.add(route[i]);
      }
    }

    // Always keep the last point
    if (route.isNotEmpty) {
      simplified.add(route.last);
    }

    return simplified;
  }
}

class RoutePoint {
  final int index;
  final LatLng point;
  final double distance;

  const RoutePoint(this.index, this.point, this.distance);
}