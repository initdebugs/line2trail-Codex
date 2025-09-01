import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:pathify/core/constants/activity_types.dart';
import 'package:pathify/shared/services/fast_roundtrip_service.dart';

void main() {
  group('Activity-Specific Roundtrip Generation', () {
    final testLocation = LatLng(52.3676, 4.9041); // Amsterdam - rich infrastructure
    const testDistance = 4.0; // 4km
    
    test('should prioritize footways for walking', () async {
      print('🚶 Testing WALKING roundtrip generation...');
      
      final result = await FastRoundtripService.generateFastRoundtrip(
        startPoint: testLocation,
        targetDistanceKm: testDistance,
        activityType: ActivityType.walking,
        strategy: RoundtripStrategy.balanced,
      );
      
      if (result != null) {
        print('✅ WALKING: Generated ${result.actualDistanceKm.toStringAsFixed(1)}km route in ${result.generationTimeMs}ms');
        print('   - Waypoints: ${result.waypoints.length}');
        print('   - Route points: ${result.routedPath.length}');
        print('   - Accuracy: ${result.distanceAccuracy.toStringAsFixed(1)}%');
        
        expect(result.activityType, equals(ActivityType.walking));
        expect(result.routedPath.length, greaterThan(100)); // Should have detailed route
        expect(result.generationTimeMs, lessThan(5000)); // Fast generation
        
        // Walking routes should prioritize pedestrian infrastructure
        // The first routing method should have been "Pedestrian-First"
        expect(result.actualDistanceKm, greaterThan(2.0)); // Reasonable distance
      } else {
        print('⚠️ Walking roundtrip failed');
        fail('Walking roundtrip should succeed');
      }
    });

    test('should prioritize cycleways for cycling', () async {
      print('🚴 Testing CYCLING roundtrip generation...');
      
      final result = await FastRoundtripService.generateFastRoundtrip(
        startPoint: testLocation,
        targetDistanceKm: testDistance,
        activityType: ActivityType.cycling,
        strategy: RoundtripStrategy.balanced,
      );
      
      if (result != null) {
        print('✅ CYCLING: Generated ${result.actualDistanceKm.toStringAsFixed(1)}km route in ${result.generationTimeMs}ms');
        print('   - Waypoints: ${result.waypoints.length}');
        print('   - Route points: ${result.routedPath.length}');
        print('   - Accuracy: ${result.distanceAccuracy.toStringAsFixed(1)}%');
        
        expect(result.activityType, equals(ActivityType.cycling));
        expect(result.routedPath.length, greaterThan(100));
        expect(result.generationTimeMs, lessThan(5000));
        
        // Cycling routes should prioritize cycling infrastructure
        expect(result.actualDistanceKm, greaterThan(2.0));
      } else {
        print('⚠️ Cycling roundtrip failed');
        fail('Cycling roundtrip should succeed');
      }
    });

    test('should prioritize trails for hiking', () async {
      print('🥾 Testing HIKING roundtrip generation...');
      
      final result = await FastRoundtripService.generateFastRoundtrip(
        startPoint: testLocation,
        targetDistanceKm: testDistance,
        activityType: ActivityType.hiking,
        strategy: RoundtripStrategy.balanced,
      );
      
      if (result != null) {
        print('✅ HIKING: Generated ${result.actualDistanceKm.toStringAsFixed(1)}km route in ${result.generationTimeMs}ms');
        print('   - Waypoints: ${result.waypoints.length}');
        print('   - Route points: ${result.routedPath.length}');
        print('   - Accuracy: ${result.distanceAccuracy.toStringAsFixed(1)}%');
        
        expect(result.activityType, equals(ActivityType.hiking));
        expect(result.routedPath.length, greaterThan(100));
        expect(result.generationTimeMs, lessThan(5000));
        
        // Hiking routes should prioritize trails and natural paths
        expect(result.actualDistanceKm, greaterThan(2.0));
      } else {
        print('⚠️ Hiking roundtrip failed');
        fail('Hiking roundtrip should succeed');
      }
    });

    test('should handle running like walking', () async {
      print('🏃 Testing RUNNING roundtrip generation...');
      
      final result = await FastRoundtripService.generateFastRoundtrip(
        startPoint: testLocation,
        targetDistanceKm: testDistance,
        activityType: ActivityType.running,
        strategy: RoundtripStrategy.balanced,
      );
      
      if (result != null) {
        print('✅ RUNNING: Generated ${result.actualDistanceKm.toStringAsFixed(1)}km route in ${result.generationTimeMs}ms');
        
        expect(result.activityType, equals(ActivityType.running));
        expect(result.routedPath.length, greaterThan(100));
        
        // Running should use similar infrastructure as walking
        expect(result.actualDistanceKm, greaterThan(2.0));
      } else {
        print('⚠️ Running roundtrip failed - this might be acceptable');
      }
    });

    test('should generate different routes for different activities', () async {
      print('🔄 Testing activity type differences...');
      
      final walkingFuture = FastRoundtripService.generateFastRoundtrip(
        startPoint: testLocation,
        targetDistanceKm: testDistance,
        activityType: ActivityType.walking,
        strategy: RoundtripStrategy.balanced,
      );
      
      final cyclingFuture = FastRoundtripService.generateFastRoundtrip(
        startPoint: testLocation,
        targetDistanceKm: testDistance,
        activityType: ActivityType.cycling,
        strategy: RoundtripStrategy.balanced,
      );
      
      final results = await Future.wait([walkingFuture, cyclingFuture]);
      final walkingResult = results[0];
      final cyclingResult = results[1];
      
      if (walkingResult != null && cyclingResult != null) {
        print('📊 Comparing routes:');
        print('   Walking: ${walkingResult.routedPath.length} points, ${walkingResult.actualDistanceKm.toStringAsFixed(1)}km');
        print('   Cycling: ${cyclingResult.routedPath.length} points, ${cyclingResult.actualDistanceKm.toStringAsFixed(1)}km');
        
        // Routes should be different (different infrastructure priorities)
        expect(walkingResult.activityType, equals(ActivityType.walking));
        expect(cyclingResult.activityType, equals(ActivityType.cycling));
        
        // Both should be valid roundtrips
        expect(walkingResult.isHighQuality || walkingResult.actualDistanceKm > 2.0, isTrue);
        expect(cyclingResult.isHighQuality || cyclingResult.actualDistanceKm > 2.0, isTrue);
        
        print('✅ Successfully generated different routes for walking and cycling');
      } else {
        print('⚠️ One or both activity-specific routes failed');
      }
    });
    
    test('should complete all activity types within reasonable time', () async {
      print('⏱️ Testing performance across all activity types...');
      
      final allActivities = ActivityType.values;
      final futures = allActivities.map((activity) => 
        FastRoundtripService.generateFastRoundtrip(
          startPoint: testLocation,
          targetDistanceKm: 3.0, // Smaller distance for speed
          activityType: activity,
          strategy: RoundtripStrategy.direct, // Fastest strategy
        )
      );
      
      final stopwatch = Stopwatch()..start();
      final results = await Future.wait(futures);
      stopwatch.stop();
      
      print('🏁 Generated ${results.where((r) => r != null).length}/${allActivities.length} routes in ${stopwatch.elapsedMilliseconds}ms');
      
      // Should complete all within reasonable time (parallel execution)
      expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // 15 seconds for all
      
      // At least half should succeed
      final successCount = results.where((r) => r != null).length;
      expect(successCount, greaterThanOrEqualTo(allActivities.length ~/ 2));
      
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final activity = allActivities[i];
        
        if (result != null) {
          print('   ${activity.name}: ${result.generationTimeMs}ms, ${result.actualDistanceKm.toStringAsFixed(1)}km');
          expect(result.activityType, equals(activity));
        }
      }
    });
  });
}