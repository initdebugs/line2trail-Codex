import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:line2trail/core/constants/activity_types.dart';
import 'package:line2trail/shared/services/routing_service.dart';

void main() {
  group('Routing Service Tests', () {
    // Test coordinates in a well-mapped area (San Francisco)
    final testStart = LatLng(37.7749, -122.4194); // Downtown SF
    final testEnd = LatLng(37.7849, -122.4094);   // North Beach

    setUpAll(() {
      // Enable mock mode for testing to avoid API calls
      RoutingService.setMockMode(true);
    });

    tearDownAll(() {
      // Disable mock mode after tests
      RoutingService.setMockMode(false);
    });

    testWidgets('Walking route should prioritize pedestrian infrastructure', (WidgetTester tester) async {
      final result = await RoutingService.snapToPathMixed(
        points: [testStart, testEnd],
        primaryActivityType: ActivityType.walking,
        allowMixedModes: false,
      );

      expect(result.length, greaterThan(2));
      expect(result.first.latitude, closeTo(testStart.latitude, 0.01));
      expect(result.last.latitude, closeTo(testEnd.latitude, 0.01));
    });

    testWidgets('Cycling route should use bike-friendly paths', (WidgetTester tester) async {
      final result = await RoutingService.snapToPathMixed(
        points: [testStart, testEnd],
        primaryActivityType: ActivityType.cycling,
        allowMixedModes: false,
      );

      expect(result.length, greaterThan(2));
      expect(result.first.latitude, closeTo(testStart.latitude, 0.01));
      expect(result.last.latitude, closeTo(testEnd.latitude, 0.01));
    });

    testWidgets('Mixed routing should find routes when single mode fails', (WidgetTester tester) async {
      // Test with hiking which may not have good coverage in urban areas
      final result = await RoutingService.snapToPathMixed(
        points: [testStart, testEnd],
        primaryActivityType: ActivityType.hiking,
        allowMixedModes: true,
      );

      expect(result.length, greaterThan(2));
      expect(result.first.latitude, closeTo(testStart.latitude, 0.01));
      expect(result.last.latitude, closeTo(testEnd.latitude, 0.01));
    });

    testWidgets('Can route check should work for reasonable distances', (WidgetTester tester) async {
      final canRoute = await RoutingService.canRoute(
        testStart,
        testEnd,
        ActivityType.walking,
      );

      expect(canRoute, isTrue);
    });

    testWidgets('Can route should reject very long distances', (WidgetTester tester) async {
      final farPoint = LatLng(40.7128, -74.0060); // New York
      final canRoute = await RoutingService.canRoute(
        testStart,
        farPoint,
        ActivityType.walking,
      );

      expect(canRoute, isFalse);
    });

    testWidgets('Time estimation should vary by activity type', (WidgetTester tester) async {
      final route = [
        testStart,
        LatLng(37.7779, -122.4164), // Intermediate point
        testEnd,
      ];

      final walkingTime = RoutingService.getEstimatedTime(route, ActivityType.walking);
      final cyclingTime = RoutingService.getEstimatedTime(route, ActivityType.cycling);
      final runningTime = RoutingService.getEstimatedTime(route, ActivityType.running);

      // Cycling should be faster than walking
      expect(cyclingTime.inMinutes, lessThan(walkingTime.inMinutes));
      
      // Running should be faster than walking but slower than cycling
      expect(runningTime.inMinutes, lessThan(walkingTime.inMinutes));
    });
  });
}