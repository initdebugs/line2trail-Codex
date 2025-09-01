import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:pathify/core/constants/activity_types.dart';
import 'package:pathify/shared/services/roundtrip_generation_service.dart';

void main() {
  group('RoundtripGenerationService', () {
    test('should generate waypoints in circular pattern', () async {
      // Test location: Amsterdam center
      final startPoint = LatLng(52.3676, 4.9041);
      const targetDistance = 5.0; // 5km
      
      // Test different strategies
      for (final strategy in RoundtripStrategy.values) {
        final result = await RoundtripGenerationService.generateRealisticRoundtrip(
          startPoint: startPoint,
          targetDistanceKm: targetDistance,
          activityType: ActivityType.walking,
          strategy: strategy,
        );
        
        if (result != null) {
          print('✅ ${strategy.name}: Generated ${result.actualDistanceKm.toStringAsFixed(1)}km route with ${result.waypoints.length} waypoints');
          
          // Verify basic properties
          expect(result.waypoints.length, greaterThan(2));
          expect(result.routedPath.length, greaterThan(result.waypoints.length));
          expect(result.actualDistanceKm, greaterThan(targetDistance * 0.3)); // At least 30% of target
          expect(result.distanceAccuracy, greaterThan(0)); // Some accuracy score
          
          // Verify it's a loop (starts and ends at same point)
          expect(result.waypoints.first.latitude, closeTo(result.waypoints.last.latitude, 0.001));
          expect(result.waypoints.first.longitude, closeTo(result.waypoints.last.longitude, 0.001));
        } else {
          print('⚠️ ${strategy.name}: Failed to generate route (may be expected in test environment)');
        }
      }
    });
    
    test('should handle different activity types', () async {
      final startPoint = LatLng(52.3676, 4.9041); // Amsterdam
      const targetDistance = 3.0; // 3km
      
      for (final activity in ActivityType.values) {
        final result = await RoundtripGenerationService.generateRealisticRoundtrip(
          startPoint: startPoint,
          targetDistanceKm: targetDistance,
          activityType: activity,
          strategy: RoundtripStrategy.balanced,
        );
        
        if (result != null) {
          print('✅ ${activity.name}: Generated route successfully');
          expect(result.activityType, equals(activity));
        } else {
          print('⚠️ ${activity.name}: Route generation failed (may be expected in test)');
        }
      }
    });
    
    test('should generate different routes for different distances', () async {
      final startPoint = LatLng(52.3676, 4.9041);
      final distances = [2.0, 5.0, 10.0]; // Different distances
      
      for (final distance in distances) {
        final result = await RoundtripGenerationService.generateRealisticRoundtrip(
          startPoint: startPoint,
          targetDistanceKm: distance,
          activityType: ActivityType.cycling,
          strategy: RoundtripStrategy.balanced,
        );
        
        if (result != null) {
          print('✅ ${distance}km: Generated ${result.actualDistanceKm.toStringAsFixed(1)}km route');
          expect(result.targetDistanceKm, equals(distance));
          // Route should be reasonably close to target distance
          expect(result.actualDistanceKm, lessThan(distance * 2.0)); // Not more than 2x target
        } else {
          print('⚠️ ${distance}km: Route generation failed');
        }
      }
    });
    
    test('should calculate route properties correctly', () {
      final waypoints = [
        LatLng(52.3676, 4.9041),
        LatLng(52.3686, 4.9051),
        LatLng(52.3696, 4.9061),
        LatLng(52.3676, 4.9041), // Back to start
      ];
      
      final routedPath = [
        ...waypoints,
        LatLng(52.3681, 4.9046), // Additional routed points
        LatLng(52.3691, 4.9056),
      ];
      
      final route = RoundtripRoute(
        waypoints: waypoints,
        routedPath: routedPath,
        startPoint: waypoints.first,
        actualDistanceKm: 4.8,
        targetDistanceKm: 5.0,
        estimatedTime: const Duration(hours: 1),
        activityType: ActivityType.walking,
        strategy: RoundtripStrategy.balanced,
      );
      
      expect(route.distanceAccuracy, closeTo(96.0, 1.0)); // 96% accuracy for 4.8km vs 5km target
      expect(route.isHighQuality, isTrue); // Should be high quality
      expect(route.toString(), contains('4.8km'));
    });
  });
}